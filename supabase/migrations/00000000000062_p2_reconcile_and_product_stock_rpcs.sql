-- Migration 62: P2 Reliability RPCs
--   1. reconcile_stock_count(p jsonb) — atomic, idempotent multi-item stock
--      count reconciliation (owner & warehouse only, append-only 'adjust' rows,
--      zero financial data exposed).
--   2. create_product_with_stock(p jsonb) — atomic, idempotent product creation
--      with optional opening stock (owner & sales for products; opening_stock > 0
--      restricted to owner per product.md §4).

-- ---------------------------------------------------------------------------
-- 1. Append-only stock_reconciliations log table (idempotency & audit trail).
-- ---------------------------------------------------------------------------
create table if not exists public.stock_reconciliations (
  id uuid primary key,
  business_id uuid not null references public.businesses(id),
  reason text not null check (length(btrim(reason)) > 0 and char_length(reason) <= 300),
  created_by uuid not null references public.members(id),
  total_items int not null check (total_items > 0),
  adjusted_count int not null check (adjusted_count >= 0),
  payload_hash text not null,
  result jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists stock_reconciliations_business_created_idx
  on public.stock_reconciliations (business_id, created_at desc);

alter table public.stock_reconciliations enable row level security;
alter table public.stock_reconciliations force row level security;

revoke all on public.stock_reconciliations from public, anon, authenticated;
grant select on public.stock_reconciliations to authenticated;
grant all on public.stock_reconciliations to service_role;

drop policy if exists "staff read stock reconciliations" on public.stock_reconciliations;
create policy "staff read stock reconciliations" on public.stock_reconciliations
  for select
  using (
    business_id = (select public.current_business_id())
    and (select public.current_role_name()) in ('owner', 'sales', 'warehouse')
  );

-- Link append-only adjust movements to their reconciliation session (nullable, additive).
alter table public.stock_movements
  add column if not exists reconciliation_id uuid references public.stock_reconciliations(id);

create index if not exists stock_movements_reconciliation_idx
  on public.stock_movements (reconciliation_id)
  where reconciliation_id is not null;

-- ---------------------------------------------------------------------------
-- 2. Additive client_op_id column on products for idempotent create retries.
-- ---------------------------------------------------------------------------
alter table public.products
  add column if not exists client_op_id uuid;

create unique index if not exists products_business_client_op_idx
  on public.products (business_id, client_op_id)
  where client_op_id is not null;

-- ---------------------------------------------------------------------------
-- 3. Update purge_business to clean up stock_reconciliations & projections.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- 4. RPC: reconcile_stock_count(p jsonb) -> jsonb
--    Allowed ONLY for active owner & warehouse.
--    Input:
--      {
--        "op_id": "<uuid>",               -- required caller-generated UUID
--        "reason": "<non-empty text>",    -- required (max 300 chars)
--        "items": [
--          { "product_id": "<uuid>", "counted_qty": <int >= 0> },
--          ...
--        ]
--      }
--    Returns (zero financial fields):
--      {
--        "op_id": "<uuid>",
--        "created": true|false,
--        "reason": "...",
--        "total_items": <int>,
--        "adjusted_count": <int>,
--        "unchanged_count": <int>,
--        "items": [
--          {
--            "product_id": "<uuid>",
--            "name": "...",
--            "previous_stock": <int>,
--            "counted_qty": <int>,
--            "delta": <int>,
--            "new_stock": <int>,
--            "movement_id": "<uuid|null>"
--          }
--        ]
--      }
-- ---------------------------------------------------------------------------
create or replace function public.reconcile_stock_count(p jsonb)
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
  v_reason text;
  v_item_count int;
  v_distinct_count int;
  v_canonical jsonb;
  v_hash text;
  v_existing public.stock_reconciliations%rowtype;
  v_elem jsonb;
  v_qty_raw text;
  v_qty_num numeric;
  v_qty int;
  v_prod_id uuid;
  v_rec record;
  v_prod public.products%rowtype;
  v_delta int;
  v_movement_id uuid;
  v_adjusted int := 0;
  v_unchanged int := 0;
  v_items_out jsonb := '[]'::jsonb;
  v_result jsonb;
begin
  v_role := current_role_name();
  v_biz := current_business_id();
  v_member := current_member_id();

  if v_role is null or v_role not in ('owner', 'warehouse') or v_biz is null or v_member is null then
    raise exception 'forbidden';
  end if;

  if p is null or jsonb_typeof(p) <> 'object' then
    raise exception 'invalid payload';
  end if;

  v_op_id := coalesce(uuid_from_json(p->>'op_id'), uuid_from_json(p->>'id'));
  if v_op_id is null then
    raise exception 'op_id is required';
  end if;

  v_reason := nullif(btrim(coalesce(p->>'reason', '')), '');
  if v_reason is null then
    raise exception 'reason is required';
  end if;
  if char_length(v_reason) > 300 then
    raise exception 'reason too long';
  end if;

  if jsonb_typeof(p->'items') is distinct from 'array'
     or jsonb_array_length(p->'items') = 0 then
    raise exception 'stock count must have at least one item';
  end if;

  v_item_count := jsonb_array_length(p->'items');
  if v_item_count > 500 then
    raise exception 'too many stock count items';
  end if;

  -- Validate every element strictly (valid UUID, non-negative whole integer).
  for v_elem in select * from jsonb_array_elements(p->'items')
  loop
    if jsonb_typeof(v_elem) <> 'object' then
      raise exception 'invalid stock count item';
    end if;
    v_prod_id := uuid_from_json(v_elem->>'product_id');
    if v_prod_id is null then
      raise exception 'product_id is required';
    end if;
    if not (v_elem ? 'counted_qty') or jsonb_typeof(v_elem->'counted_qty') not in ('number', 'string') then
      raise exception 'counted_qty must be a non-negative integer';
    end if;
    v_qty_raw := btrim(v_elem->>'counted_qty');
    if v_qty_raw !~ '^[0-9]+$' then
      raise exception 'counted_qty must be a non-negative integer';
    end if;
    v_qty_num := v_qty_raw::numeric;
    if v_qty_num < 0 or v_qty_num > 100000000 then
      raise exception 'counted_qty out of range';
    end if;
  end loop;

  -- Reject duplicate product_ids in the same reconciliation.
  select count(distinct uuid_from_json(x->>'product_id'))
    into v_distinct_count
  from jsonb_array_elements(p->'items') x;
  if v_distinct_count <> v_item_count then
    raise exception 'duplicate product_id in stock count';
  end if;

  -- Build deterministic canonical representation for retry payload verification.
  select jsonb_agg(
    jsonb_build_object(
      'product_id', uuid_from_json(x->>'product_id'),
      'counted_qty', (btrim(x->>'counted_qty'))::int
    )
    order by uuid_from_json(x->>'product_id')::text
  )
  into v_canonical
  from jsonb_array_elements(p->'items') x;

  v_hash := md5(jsonb_build_object('reason', v_reason, 'items', v_canonical)::text);

  -- Serialize concurrent calls sharing the same op_id.
  perform pg_advisory_xact_lock(hashtextextended('reconcile_stock_count:' || v_op_id::text, 0));

  select * into v_existing
  from public.stock_reconciliations
  where id = v_op_id;

  if found then
    if v_existing.business_id is distinct from v_biz then
      raise exception 'forbidden';
    end if;
    if v_existing.payload_hash is distinct from v_hash then
      raise exception 'reconciliation retry payload does not match';
    end if;
    return v_existing.result || jsonb_build_object('created', false);
  end if;

  -- Insert the reconciliation header first (with placeholder result, updated at
  -- end of transaction) so append-only stock_movements can reference its FK.
  insert into public.stock_reconciliations (
    id, business_id, reason, created_by, total_items, adjusted_count, payload_hash, result
  ) values (
    v_op_id, v_biz, v_reason, v_member, v_item_count, 0, v_hash, '{}'::jsonb
  );

  -- Process items in deterministic product_id order, locking each active product
  -- row FOR UPDATE to prevent deadlocks and concurrent movement races.
  for v_rec in
    select
      (x->>'product_id')::uuid as product_id,
      (x->>'counted_qty')::int as counted_qty
    from jsonb_array_elements(v_canonical) x
    order by (x->>'product_id')::uuid
  loop
    select * into v_prod
    from public.products
    where id = v_rec.product_id
      and business_id = v_biz
      and is_active = true
    for update;

    if not found then
      raise exception 'active product not found';
    end if;

    v_delta := v_rec.counted_qty - v_prod.stock_cached;
    v_movement_id := null;

    if v_delta <> 0 then
      insert into public.stock_movements (
        business_id,
        product_id,
        type,
        qty_delta,
        reason,
        created_by,
        reconciliation_id
      ) values (
        v_biz,
        v_prod.id,
        'adjust',
        v_delta,
        v_reason,
        v_member,
        v_op_id
      )
      returning id into v_movement_id;

      v_adjusted := v_adjusted + 1;
    else
      v_unchanged := v_unchanged + 1;
    end if;

    -- Zero financial columns exposed (no cost_price, reference_price, valuation).
    v_items_out := v_items_out || jsonb_build_array(
      jsonb_build_object(
        'product_id', v_prod.id,
        'name', v_prod.name,
        'previous_stock', v_prod.stock_cached,
        'counted_qty', v_rec.counted_qty,
        'delta', v_delta,
        'new_stock', v_rec.counted_qty,
        'movement_id', v_movement_id
      )
    );
  end loop;

  v_result := jsonb_build_object(
    'op_id', v_op_id,
    'created', true,
    'reason', v_reason,
    'total_items', v_item_count,
    'adjusted_count', v_adjusted,
    'unchanged_count', v_unchanged,
    'items', v_items_out
  );

  update public.stock_reconciliations
  set adjusted_count = v_adjusted,
      result = v_result
  where id = v_op_id;

  return v_result;
end;
$$;

revoke all on function public.reconcile_stock_count(jsonb) from public, anon;
grant execute on function public.reconcile_stock_count(jsonb) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 5. RPC: create_product_with_stock(p jsonb) -> jsonb
--    Allowed ONLY for active owner & sales (product.md §4):
--      - owner: create product + optional opening_stock >= 0 (atomic stock_in)
--      - sales: create product ONLY with opening_stock = 0 (cannot insert stock_movements)
--      - warehouse, customer: forbidden
--    Input:
--      {
--        "op_id": "<uuid>",                      -- required caller-generated UUID
--        "id": "<uuid>",                         -- optional product UUID (defaults to op_id)
--        "name": "<non-empty text>",             -- required (max 200 chars)
--        "name_np": "<text|null>",               -- optional (max 200 chars)
--        "sku": "<text|null>",                   -- optional (max 100 chars)
--        "unit": "<text>",                       -- optional, default 'piece' (max 50 chars)
--        "cost_price": <bigint >= 0>,            -- optional, default 0 (paisa)
--        "reference_price": <bigint >= 0>,       -- optional, default 0 (paisa)
--        "low_stock_threshold": <int >= 0>,      -- optional, default 0
--        "opening_stock": <int >= 0>,            -- optional, default 0 (owner-only if > 0)
--        "opening_stock_reason": "<text|null>"   -- optional, default 'Opening stock'
--      }
--    Returns:
--      {
--        "product": { ...full products row with updated stock_cached... },
--        "movement_id": "<uuid|null>",
--        "created": true|false
--      }
-- ---------------------------------------------------------------------------
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
  -- but only owner (and warehouse for stock-only ops) can write stock_movements.
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

  -- Serialize concurrent retries sharing op_id or product_id.
  perform pg_advisory_xact_lock(hashtextextended('create_product_with_stock:' || v_op_id::text, 0));
  if v_product_id <> v_op_id then
    perform pg_advisory_xact_lock(hashtextextended('create_product_with_stock:' || v_product_id::text, 0));
  end if;

  -- Check idempotency by (business_id, client_op_id) or primary key id.
  select * into v_existing
  from public.products
  where id = v_product_id
     or (business_id = v_biz and client_op_id = v_op_id)
  limit 1;

  if found then
    if v_existing.business_id is distinct from v_biz then
      raise exception 'forbidden';
    end if;
    if v_existing.client_op_id is distinct from v_op_id
       or v_existing.name is distinct from v_name
       or v_existing.unit is distinct from v_unit
       or v_existing.cost_price is distinct from v_cost_price
       or v_existing.reference_price is distinct from v_ref_price
       or v_existing.low_stock_threshold is distinct from v_threshold
       or v_existing.sku is distinct from v_sku then
      raise exception 'product retry payload does not match';
    end if;

    select sm.id into v_movement_id
    from public.stock_movements sm
    where sm.business_id = v_biz
      and sm.product_id = v_existing.id
      and sm.type = 'stock_in'
    order by sm.created_at asc
    limit 1;

    return jsonb_build_object(
      'product', to_jsonb(v_existing),
      'movement_id', v_movement_id,
      'created', false
    );
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
