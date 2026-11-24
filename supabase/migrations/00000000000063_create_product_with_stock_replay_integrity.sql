-- Migration 63: Strict replay integrity for create_product_with_stock
--   - Records exact immutable creation payload hash (including name_np,
--     opening_stock, opening_stock_reason) and exact opening_movement_id in an
--     internal RLS-protected idempotency table (product_create_ops).
--   - Prevents mismatched retries (e.g. different name_np or opening_stock)
--     from silently succeeding, and ensures opening_stock = 0 replays always
--     return movement_id = null even after subsequent stock_in movements.

create table if not exists public.product_create_ops (
  op_id uuid primary key,
  business_id uuid not null references public.businesses(id),
  product_id uuid not null references public.products(id),
  opening_movement_id uuid references public.stock_movements(id),
  payload_hash text not null,
  created_at timestamptz not null default now()
);

create index if not exists product_create_ops_business_idx
  on public.product_create_ops (business_id, created_at desc);

alter table public.product_create_ops enable row level security;
alter table public.product_create_ops force row level security;

revoke all on public.product_create_ops from public, anon, authenticated;
grant all on public.product_create_ops to service_role;

-- Update purge_business to clean up product_create_ops before stock_movements/products.
create or replace function public.purge_business(p_business_id uuid)
returns uuid[]
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_user_ids uuid[];
begin
  select coalesce(array_agg(auth_user_id), '{}') into v_auth_user_ids
  from members where business_id = p_business_id;

  delete from notifications where business_id = p_business_id;
  delete from device_tokens
  where member_id in (select id from members where business_id = p_business_id);

  delete from credit_note_items
  where credit_note_id in
    (select id from credit_notes where business_id = p_business_id);
  delete from credit_notes where business_id = p_business_id;
  delete from credit_note_sequences where business_id = p_business_id;

  delete from payments where business_id = p_business_id;
  delete from bill_items
  where bill_id in (select id from bills where business_id = p_business_id);
  delete from bills where business_id = p_business_id;
  delete from bill_sequences where business_id = p_business_id;

  delete from quote_items
  where quote_id in
    (select q.id from quotes q
     join orders o on o.id = q.order_id
     where o.business_id = p_business_id);
  delete from quotes
  where order_id in (select id from orders where business_id = p_business_id);
  delete from order_items
  where order_id in (select id from orders where business_id = p_business_id);
  delete from orders where business_id = p_business_id;

  delete from product_create_ops where business_id = p_business_id;
  delete from stock_movements where business_id = p_business_id;
  delete from stock_reconciliations where business_id = p_business_id;
  delete from products where business_id = p_business_id;

  delete from customer_balance_projections where business_id = p_business_id;
  delete from audit_log where business_id = p_business_id;
  delete from customers where business_id = p_business_id;
  delete from members where business_id = p_business_id;
  delete from businesses where id = p_business_id;

  return v_auth_user_ids;
end;
$$;

revoke all on function public.purge_business(uuid) from public, anon, authenticated;
grant execute on function public.purge_business(uuid) to service_role;

-- Replace create_product_with_stock to enforce full payload-hash replay checks
-- and exact opening_movement_id tracking.
create or replace function public.create_product_with_stock(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role member_role;
  v_biz uuid;
  v_member uuid;
  v_op_id uuid;
  v_product_id uuid;
  v_name text;
  v_name_np text;
  v_sku text;
  v_unit text;
  v_cost_price bigint;
  v_ref_price bigint;
  v_threshold int;
  v_opening_stock int;
  v_reason text;
  v_raw text;
  v_num numeric;
  v_payload_hash text;
  v_op public.product_create_ops%rowtype;
  v_existing public.products%rowtype;
  v_movement_id uuid;
  v_product_json jsonb;
begin
  v_role := current_role_name();
  v_biz := current_business_id();
  v_member := current_member_id();

  if v_role is null or v_role not in ('owner', 'sales') or v_biz is null or v_member is null then
    raise exception 'forbidden';
  end if;

  if p is null or jsonb_typeof(p) <> 'object' then
    raise exception 'invalid payload';
  end if;

  v_op_id := coalesce(uuid_from_json(p->>'op_id'), uuid_from_json(p->>'id'));
  if v_op_id is null then
    raise exception 'op_id is required';
  end if;
  v_product_id := coalesce(uuid_from_json(p->>'id'), v_op_id);

  v_name := nullif(btrim(coalesce(p->>'name', '')), '');
  if v_name is null then
    raise exception 'product name is required';
  end if;
  if char_length(v_name) > 200 then
    raise exception 'product name too long';
  end if;

  v_name_np := nullif(btrim(coalesce(p->>'name_np', '')), '');
  if v_name_np is not null and char_length(v_name_np) > 200 then
    raise exception 'product Nepali name too long';
  end if;

  v_sku := nullif(btrim(coalesce(p->>'sku', '')), '');
  if v_sku is not null and char_length(v_sku) > 100 then
    raise exception 'sku too long';
  end if;

  v_unit := coalesce(nullif(btrim(coalesce(p->>'unit', '')), ''), 'piece');
  if char_length(v_unit) > 50 then
    raise exception 'unit too long';
  end if;

  -- Strict integer parsing for money & stock fields (reject fractional values).
  if p ? 'cost_price' and p->'cost_price' <> 'null'::jsonb then
    v_raw := btrim(p->>'cost_price');
    if v_raw !~ '^[0-9]+$' then
      raise exception 'cost_price must be a non-negative integer';
    end if;
    v_num := v_raw::numeric;
    if v_num > 100000000000 then
      raise exception 'cost_price out of range';
    end if;
    v_cost_price := v_num::bigint;
  else
    v_cost_price := 0;
  end if;

  if p ? 'reference_price' and p->'reference_price' <> 'null'::jsonb then
    v_raw := btrim(p->>'reference_price');
    if v_raw !~ '^[0-9]+$' then
      raise exception 'reference_price must be a non-negative integer';
    end if;
    v_num := v_raw::numeric;
    if v_num > 100000000000 then
      raise exception 'reference_price out of range';
    end if;
    v_ref_price := v_num::bigint;
  else
    v_ref_price := 0;
  end if;

  if p ? 'low_stock_threshold' and p->'low_stock_threshold' <> 'null'::jsonb then
    v_raw := btrim(p->>'low_stock_threshold');
    if v_raw !~ '^[0-9]+$' then
      raise exception 'low_stock_threshold must be a non-negative integer';
    end if;
    v_num := v_raw::numeric;
    if v_num > 100000000 then
      raise exception 'low_stock_threshold out of range';
    end if;
    v_threshold := v_num::int;
  else
    v_threshold := 0;
  end if;

  if p ? 'opening_stock' and p->'opening_stock' <> 'null'::jsonb then
    v_raw := btrim(p->>'opening_stock');
    if v_raw !~ '^[0-9]+$' then
      raise exception 'opening_stock must be a non-negative integer';
    end if;
    v_num := v_raw::numeric;
    if v_num > 100000000 then
      raise exception 'opening_stock out of range';
    end if;
    v_opening_stock := v_num::int;
  else
    v_opening_stock := 0;
  end if;

  -- Role matrix enforcement (product.md §4): sales may create products,
  -- but only owner can write opening stock movements.
  if v_opening_stock > 0 and v_role <> 'owner' then
    raise exception 'only owner can record opening stock';
  end if;

  v_reason := coalesce(
    nullif(btrim(coalesce(p->>'opening_stock_reason', '')), ''),
    'Opening stock'
  );
  if char_length(v_reason) > 300 then
    raise exception 'opening_stock_reason too long';
  end if;

  v_payload_hash := md5(
    jsonb_build_object(
      'product_id', v_product_id,
      'name', v_name,
      'name_np', v_name_np,
      'sku', v_sku,
      'unit', v_unit,
      'cost_price', v_cost_price,
      'reference_price', v_ref_price,
      'low_stock_threshold', v_threshold,
      'opening_stock', v_opening_stock,
      'opening_stock_reason', case when v_opening_stock > 0 then v_reason else null end
    )::text
  );

  -- Serialize concurrent retries sharing op_id or product_id.
  perform pg_advisory_xact_lock(hashtextextended('create_product_with_stock:' || v_op_id::text, 0));
  if v_product_id <> v_op_id then
    perform pg_advisory_xact_lock(hashtextextended('create_product_with_stock:' || v_product_id::text, 0));
  end if;

  -- Check authoritative idempotency ledger first.
  select * into v_op
  from public.product_create_ops
  where op_id = v_op_id;

  if found then
    if v_op.business_id is distinct from v_biz then
      raise exception 'forbidden';
    end if;
    if v_op.payload_hash is distinct from v_payload_hash then
      raise exception 'product retry payload does not match';
    end if;

    select to_jsonb(prod.*) into v_product_json
    from public.products prod
    where prod.id = v_op.product_id
      and prod.business_id = v_biz;

    return jsonb_build_object(
      'product', v_product_json,
      'movement_id', v_op.opening_movement_id,
      'created', false
    );
  end if;

  -- Guard against product_id or legacy client_op_id collisions outside product_create_ops.
  select * into v_existing
  from public.products
  where id = v_product_id
     or (business_id = v_biz and client_op_id = v_op_id)
  limit 1;

  if found then
    if v_existing.business_id is distinct from v_biz then
      raise exception 'forbidden';
    end if;
    raise exception 'product retry payload does not match';
  end if;

  insert into public.products (
    id,
    business_id,
    name,
    name_np,
    sku,
    unit,
    cost_price,
    reference_price,
    low_stock_threshold,
    stock_cached,
    client_op_id
  ) values (
    v_product_id,
    v_biz,
    v_name,
    v_name_np,
    v_sku,
    v_unit,
    v_cost_price,
    v_ref_price,
    v_threshold,
    0,
    v_op_id
  );

  v_movement_id := null;
  if v_opening_stock > 0 then
    insert into public.stock_movements (
      business_id,
      product_id,
      type,
      qty_delta,
      reason,
      created_by
    ) values (
      v_biz,
      v_product_id,
      'stock_in',
      v_opening_stock,
      v_reason,
      v_member
    )
    returning id into v_movement_id;
  end if;

  insert into public.product_create_ops (
    op_id,
    business_id,
    product_id,
    opening_movement_id,
    payload_hash
  ) values (
    v_op_id,
    v_biz,
    v_product_id,
    v_movement_id,
    v_payload_hash
  );

  select to_jsonb(prod.*) into v_product_json
  from public.products prod
  where prod.id = v_product_id;

  return jsonb_build_object(
    'product', v_product_json,
    'movement_id', v_movement_id,
    'created', true
  );
end;
$$;

revoke all on function public.create_product_with_stock(jsonb) from public, anon;
grant execute on function public.create_product_with_stock(jsonb) to authenticated, service_role;
