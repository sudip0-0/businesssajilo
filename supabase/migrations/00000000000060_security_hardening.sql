-- Migration 60: Security hardening across views, RPC grants, column-pinning
-- triggers, credit-note return locking/dedup, LIKE escaping, and bounds checks.

-- ---------------------------------------------------------------------------
-- 1. Helper: escape LIKE/ILIKE wildcards (%, _, \) so user search queries
--    cannot inject pattern wildcards.
-- ---------------------------------------------------------------------------
create or replace function public.escape_like_pattern(p_text text)
returns text
language sql
immutable
set search_path = public
as $$
  select replace(
    replace(
      replace(btrim(coalesce(p_text, '')), '\', '\\'),
      '%', '\%'
    ),
    '_', '\_'
  );
$$;

revoke all on function public.escape_like_pattern(text) from public, anon;
grant execute on function public.escape_like_pattern(text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. Lock down catalog_products view (previously security_invoker=false with
--    no business_id filter, exposing cross-tenant active products).
-- ---------------------------------------------------------------------------
create or replace view public.catalog_products
with (security_invoker = false, security_barrier = true) as
select
  p.id,
  p.business_id,
  p.name,
  p.name_np,
  p.sku,
  p.unit,
  p.image_url,
  p.stock_cached,
  p.is_active
from public.products p
where p.is_active = true
  and p.business_id = (select public.current_business_id())
  and (select public.current_role_name()) in ('owner', 'sales', 'warehouse', 'customer');

revoke all on public.catalog_products from public, anon, authenticated;
grant select on public.catalog_products to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. Revoke PUBLIC / anon / authenticated EXECUTE on internal SECURITY DEFINER
--    helpers (insert_notification, refresh_bill_status_for, insert_audit_log).
-- ---------------------------------------------------------------------------
revoke all on function public.insert_notification(uuid, uuid, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.insert_notification(uuid, uuid, text, jsonb)
  to service_role;

revoke all on function public.refresh_bill_status_for(uuid)
  from public, anon, authenticated;
grant execute on function public.refresh_bill_status_for(uuid)
  to service_role;

revoke all on function public.insert_audit_log(text, uuid, text, text, text, audit_source)
  from public, anon, authenticated;
grant execute on function public.insert_audit_log(text, uuid, text, text, text, audit_source)
  to service_role;

-- Revoke PUBLIC & anon EXECUTE on all authenticated-only RPCs.
revoke execute on function public.bill_returned_qty(uuid) from public, anon;
grant execute on function public.bill_returned_qty(uuid) to authenticated, service_role;

revoke execute on function public.billing_draft_from_order(uuid) from public, anon;
grant execute on function public.billing_draft_from_order(uuid) to authenticated, service_role;

revoke execute on function public.clear_must_change_password() from public, anon;
grant execute on function public.clear_must_change_password() to authenticated, service_role;

revoke execute on function public.create_bill(jsonb) from public, anon;
grant execute on function public.create_bill(jsonb) to authenticated, service_role;

revoke execute on function public.create_credit_note(jsonb) from public, anon;
grant execute on function public.create_credit_note(jsonb) to authenticated, service_role;

revoke execute on function public.last_quoted_rate(uuid, uuid) from public, anon;
grant execute on function public.last_quoted_rate(uuid, uuid) to authenticated, service_role;

revoke execute on function public.list_catalog_products() from public, anon;
grant execute on function public.list_catalog_products() to authenticated, service_role;

revoke execute on function public.list_low_stock(integer) from public, anon;
grant execute on function public.list_low_stock(integer) to authenticated, service_role;

revoke execute on function public.list_products_page(boolean, text, text, integer, integer) from public, anon;
grant execute on function public.list_products_page(boolean, text, text, integer, integer) to authenticated, service_role;

revoke execute on function public.low_stock_count() from public, anon;
grant execute on function public.low_stock_count() to authenticated, service_role;

revoke execute on function public.occurred_at_from_payload(jsonb) from public, anon;
grant execute on function public.occurred_at_from_payload(jsonb) to authenticated, service_role;

revoke execute on function public.owner_dashboard_stats() from public, anon;
grant execute on function public.owner_dashboard_stats() to authenticated, service_role;

revoke execute on function public.place_order(jsonb) from public, anon;
grant execute on function public.place_order(jsonb) to authenticated, service_role;

revoke execute on function public.process_operational_nudges() from public, anon;
grant execute on function public.process_operational_nudges() to authenticated, service_role;

revoke execute on function public.record_customer_sale(jsonb) from public, anon;
grant execute on function public.record_customer_sale(jsonb) to authenticated, service_role;

revoke execute on function public.record_payment(jsonb) from public, anon;
grant execute on function public.record_payment(jsonb) to authenticated, service_role;

revoke execute on function public.report_customer_top_products(uuid, date, date, integer) from public, anon;
grant execute on function public.report_customer_top_products(uuid, date, date, integer) to authenticated, service_role;

revoke execute on function public.report_dues_aging() from public, anon;
grant execute on function public.report_dues_aging() to authenticated, service_role;

revoke execute on function public.report_product_top_customers(uuid, date, date, integer) from public, anon;
grant execute on function public.report_product_top_customers(uuid, date, date, integer) to authenticated, service_role;

revoke execute on function public.report_profit_summary(date, date) from public, anon;
grant execute on function public.report_profit_summary(date, date) to authenticated, service_role;

revoke execute on function public.report_top_customers_range(date, date, integer) from public, anon;
grant execute on function public.report_top_customers_range(date, date, integer) to authenticated, service_role;

revoke execute on function public.report_top_products_range(date, date, integer) from public, anon;
grant execute on function public.report_top_products_range(date, date, integer) to authenticated, service_role;

revoke execute on function public.report_top_profitable_customers(date, date, integer) from public, anon;
grant execute on function public.report_top_profitable_customers(date, date, integer) to authenticated, service_role;

revoke execute on function public.report_top_profitable_products(date, date, integer) from public, anon;
grant execute on function public.report_top_profitable_products(date, date, integer) to authenticated, service_role;

revoke execute on function public.respond_quote(uuid, text, text) from public, anon;
grant execute on function public.respond_quote(uuid, text, text) to authenticated, service_role;

revoke execute on function public.search_bills(text, bill_status, timestamptz, timestamptz, integer, integer) from public, anon;
grant execute on function public.search_bills(text, bill_status, timestamptz, timestamptz, integer, integer) to authenticated, service_role;

revoke execute on function public.send_quote(uuid, jsonb) from public, anon;
grant execute on function public.send_quote(uuid, jsonb) to authenticated, service_role;

revoke execute on function public.total_dues() from public, anon;
grant execute on function public.total_dues() to authenticated, service_role;

revoke execute on function public.update_own_notification_prefs(jsonb) from public, anon;
grant execute on function public.update_own_notification_prefs(jsonb) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. Tighten table & view grants (revoke anon privileges, revoke direct write
--    grants on internal/read-only tables and views from authenticated).
-- ---------------------------------------------------------------------------
revoke all on all tables in schema public from anon;

revoke all on public.credit_note_sequences from public, anon, authenticated;
grant all on public.credit_note_sequences to service_role;

revoke insert, update, delete, truncate on public.customer_balance_projections from authenticated;
revoke insert, update, delete, truncate on public.customer_balance_projection_drift from authenticated;
revoke insert, update, delete, truncate on public.customer_balances from authenticated;
revoke insert, update, delete, truncate on public.customer_dues_aging from authenticated;
revoke insert, update, delete, truncate on public.customer_ledger_entries from authenticated;
revoke insert, update, delete, truncate on public.report_sales_daily from authenticated;
revoke insert, update, delete, truncate on public.report_stock_valuation from authenticated;
revoke insert, update, delete, truncate on public.report_top_customers from authenticated;
revoke insert, update, delete, truncate on public.report_top_products from authenticated;

-- ---------------------------------------------------------------------------
-- 5. Pin search_path on remaining trigger functions.
-- ---------------------------------------------------------------------------
alter function public.bump_updated_at() set search_path = public;
alter function public.orders_bump_updated_at() set search_path = public;
alter function public.validate_order_status_transition() set search_path = public;

-- ---------------------------------------------------------------------------
-- 6. Column-pinning & direct-write integrity triggers for authenticated clients.
-- ---------------------------------------------------------------------------

-- 6a. Notifications: recipients may only toggle read_at (no tampering with
--     type, payload, pushed_at, recipient_member_id, business_id, created_at).
create or replace function public.pin_notification_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user is distinct from 'authenticated' then
    return new;
  end if;
  if new.id is distinct from old.id
     or new.business_id is distinct from old.business_id
     or new.recipient_member_id is distinct from old.recipient_member_id
     or new.type is distinct from old.type
     or new.payload is distinct from old.payload
     or new.created_at is distinct from old.created_at
     or new.pushed_at is distinct from old.pushed_at then
    raise exception 'only read_at can be updated on notifications';
  end if;
  return new;
end;
$$;

revoke all on function public.pin_notification_columns() from public, anon, authenticated;

drop trigger if exists notifications_pin_columns on public.notifications;
create trigger notifications_pin_columns
  before update on public.notifications
  for each row execute function public.pin_notification_columns();

-- 6b. Businesses: owners cannot self-upgrade subscription_plan or mutate id/created_at.
create or replace function public.pin_business_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user is distinct from 'authenticated' then
    return new;
  end if;
  if new.id is distinct from old.id
     or new.subscription_plan is distinct from old.subscription_plan
     or new.created_at is distinct from old.created_at then
    raise exception 'business identity and subscription plan cannot be changed directly';
  end if;
  return new;
end;
$$;

revoke all on function public.pin_business_columns() from public, anon, authenticated;

drop trigger if exists businesses_pin_columns on public.businesses;
create trigger businesses_pin_columns
  before update on public.businesses
  for each row execute function public.pin_business_columns();

-- 6c. Products: stock_cached and was_above_threshold are trigger-managed only;
--     authenticated clients (owner/sales) cannot set or alter stock_cached directly.
create or replace function public.guard_product_stock_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_user is distinct from 'authenticated' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    if coalesce(new.stock_cached, 0) <> 0 then
      raise exception 'stock_cached is managed by stock_movements';
    end if;
    return new;
  end if;
  if new.business_id is distinct from old.business_id then
    raise exception 'product business cannot be changed';
  end if;
  if new.stock_cached is distinct from old.stock_cached
     or new.was_above_threshold is distinct from old.was_above_threshold then
    raise exception 'stock_cached is managed by stock_movements';
  end if;
  return new;
end;
$$;

revoke all on function public.guard_product_stock_columns() from public, anon, authenticated;

drop trigger if exists products_guard_stock_columns on public.products;
create trigger products_guard_stock_columns
  before insert or update on public.products
  for each row execute function public.guard_product_stock_columns();

-- 6d. Stock movements: guard ref_bill_id and ref_credit_note_id same-tenant
--     ownership (closes cross-tenant FK existence oracle).
create or replace function public.guard_stock_movement_refs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  prod_biz uuid;
begin
  select business_id into prod_biz from products where id = NEW.product_id;
  if prod_biz is null or prod_biz != NEW.business_id then
    raise exception 'product does not belong to this business';
  end if;

  if NEW.ref_order_id is not null and not exists (
    select 1 from orders where id = NEW.ref_order_id and business_id = NEW.business_id
  ) then
    raise exception 'order does not belong to this business';
  end if;

  if NEW.ref_bill_id is not null and not exists (
    select 1 from bills where id = NEW.ref_bill_id and business_id = NEW.business_id
  ) then
    raise exception 'bill does not belong to this business';
  end if;

  if NEW.ref_credit_note_id is not null and not exists (
    select 1 from credit_notes where id = NEW.ref_credit_note_id and business_id = NEW.business_id
  ) then
    raise exception 'credit note does not belong to this business';
  end if;

  return NEW;
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. Narrow order_items staff SELECT policy to owner & sales (warehouse uses
--    billing_draft_from_order RPC and has no orders SELECT).
-- ---------------------------------------------------------------------------
drop policy if exists "staff read order items" on public.order_items;
create policy "staff read order items" on public.order_items
  for select
  using (
    order_id in (
      select orders.id
      from public.orders
      where orders.business_id = (select public.current_business_id())
        and (select public.current_role_name()) in ('owner', 'sales')
    )
  );

-- ---------------------------------------------------------------------------
-- 8. Harden storage.objects policies on product-images against path traversal.
-- ---------------------------------------------------------------------------
drop policy if exists "owner upload product images" on storage.objects;
create policy "owner upload product images" on storage.objects
  for insert
  with check (
    bucket_id = 'product-images'
    and strpos(name, '..') = 0
    and (storage.foldername(name))[1] = ((select public.current_business_id()))::text
    and (select public.current_role_name()) = 'owner'
  );

drop policy if exists "owner update product images" on storage.objects;
create policy "owner update product images" on storage.objects
  for update
  using (
    bucket_id = 'product-images'
    and strpos(name, '..') = 0
    and (storage.foldername(name))[1] = ((select public.current_business_id()))::text
    and (select public.current_role_name()) = 'owner'
  );

drop policy if exists "owner delete product images" on storage.objects;
create policy "owner delete product images" on storage.objects
  for delete
  using (
    bucket_id = 'product-images'
    and strpos(name, '..') = 0
    and (storage.foldername(name))[1] = ((select public.current_business_id()))::text
    and (select public.current_role_name()) = 'owner'
  );

drop policy if exists "staff read product images" on storage.objects;
create policy "staff read product images" on storage.objects
  for select
  using (
    bucket_id = 'product-images'
    and strpos(name, '..') = 0
    and (storage.foldername(name))[1] = ((select public.current_business_id()))::text
    and (select public.current_role_name()) in ('owner', 'sales', 'warehouse')
  );

-- ---------------------------------------------------------------------------
-- 9. Harden create_credit_note:
--    - Advisory lock on v_id for concurrent idempotent retry safety
--    - Lock bills row FOR UPDATE to serialize concurrent returns on same bill
--    - Aggregate requested qty_returned per bill_item_id so duplicate entries
--      in p->'items' cannot bypass the remaining-returnable-qty check
--    - Validate items array type & max length; guard null product_id on restock
-- ---------------------------------------------------------------------------
create or replace function public.create_credit_note(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_bill_id uuid;
  v_customer_id uuid;
  v_reason text;
  v_restock boolean;
  v_member uuid;
  v_biz uuid;
  v_items_total numeric := 0;
  v_discount bigint := 0;
  v_grand_total bigint := 0;
  item record;
  v_bill_item_id uuid;
  v_product_id uuid;
  v_name text;
  v_qty int;
  v_rate bigint;
  v_item_discount bigint;
  v_orig_discount bigint;
  v_line numeric;
  v_bill_qty int;
  v_returned int;
  bill_row bills%rowtype;
  existing jsonb;
  v_note_id uuid;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_biz := current_business_id();
  v_member := current_member_id();
  v_id := coalesce(uuid_from_json(p->>'id'), gen_random_uuid());

  perform pg_advisory_xact_lock(hashtextextended('create_credit_note:' || v_id::text, 0));

  select to_jsonb(cn.*) into existing
  from credit_notes cn
  where cn.id = v_id and cn.business_id = v_biz;
  if existing is not null then
    return jsonb_build_object('credit_note', existing, 'created', false);
  end if;

  v_bill_id := uuid_from_json(p->>'bill_id');
  if v_bill_id is null then
    raise exception 'bill not found';
  end if;
  v_reason := nullif(btrim(coalesce(p->>'reason', '')), '');
  v_restock := coalesce((p->>'restock')::boolean, true);

  -- Lock bill row to serialize concurrent credit notes against the same bill.
  select * into bill_row
  from bills
  where id = v_bill_id and business_id = v_biz
  for update;
  if not found then
    raise exception 'bill not found';
  end if;
  if bill_row.customer_id is null then
    raise exception 'walk-in bills cannot be returned';
  end if;
  v_customer_id := bill_row.customer_id;

  if jsonb_typeof(p->'items') is distinct from 'array'
     or jsonb_array_length(p->'items') = 0 then
    raise exception 'credit note must have at least one item';
  end if;
  if jsonb_array_length(p->'items') > 500 then
    raise exception 'too many credit note items';
  end if;

  -- Validate every raw item first (positive qty & valid uuid).
  for item in
    select
      uuid_from_json(elem->>'bill_item_id') as bill_item_id,
      (elem->>'qty_returned')::int as qty_returned
    from jsonb_array_elements(p->'items') as elem
  loop
    if item.bill_item_id is null then
      raise exception 'bill item not found';
    end if;
    if item.qty_returned is null or item.qty_returned <= 0 then
      raise exception 'qty must be positive';
    end if;
  end loop;

  -- Aggregate requested return quantities per bill_item_id so duplicate entries
  -- in the same payload cannot exceed the original billed quantity.
  for item in
    select
      uuid_from_json(elem->>'bill_item_id') as bill_item_id,
      sum((elem->>'qty_returned')::bigint) as total_req_qty
    from jsonb_array_elements(p->'items') as elem
    group by uuid_from_json(elem->>'bill_item_id')
  loop
    v_bill_item_id := item.bill_item_id;
    if item.total_req_qty > 2147483647 then
      raise exception 'return qty exceeds remaining';
    end if;
    v_qty := item.total_req_qty::int;

    select bi.qty, bi.product_id, bi.name_snapshot, bi.rate, bi.discount
      into v_bill_qty, v_product_id, v_name, v_rate, v_orig_discount
    from bill_items bi
    where bi.id = v_bill_item_id
      and bi.bill_id = v_bill_id
      and bi.business_id = v_biz;
    if not found then
      raise exception 'bill item not found';
    end if;

    select coalesce(sum(cni.qty_returned), 0) into v_returned
    from credit_note_items cni
    join credit_notes cn on cn.id = cni.credit_note_id
    where cni.bill_item_id = v_bill_item_id
      and cn.business_id = v_biz;

    if v_returned::bigint + v_qty::bigint > v_bill_qty::bigint then
      raise exception 'return qty exceeds remaining';
    end if;

    v_item_discount := ((v_orig_discount::numeric * v_qty::numeric) / v_bill_qty::numeric)::bigint;
    if v_item_discount < 0 then
      v_item_discount := 0;
    end if;
    if v_item_discount::numeric > v_qty::numeric * v_rate::numeric then
      v_item_discount := (v_qty::numeric * v_rate::numeric)::bigint;
    end if;
    v_line := v_qty::numeric * v_rate::numeric - v_item_discount::numeric;
    v_items_total := v_items_total + v_line;
  end loop;

  if v_items_total > 9007199254740991 then
    raise exception 'credit note total out of range';
  end if;

  v_grand_total := v_items_total::bigint - v_discount;
  if v_grand_total < 0 then
    raise exception 'grand total must be non-negative';
  end if;

  insert into credit_notes (
    id, business_id, bill_id, customer_id, items_total, discount, grand_total,
    reason, restock, created_by
  ) values (
    v_id, v_biz, v_bill_id, v_customer_id, v_items_total::bigint, v_discount, v_grand_total,
    v_reason, v_restock, v_member
  ) returning id into v_note_id;

  for item in
    select
      uuid_from_json(elem->>'bill_item_id') as bill_item_id,
      sum((elem->>'qty_returned')::bigint)::int as qty_returned
    from jsonb_array_elements(p->'items') as elem
    group by uuid_from_json(elem->>'bill_item_id')
  loop
    v_bill_item_id := item.bill_item_id;
    v_qty := item.qty_returned;

    select bi.product_id, bi.name_snapshot, bi.rate, bi.discount, bi.qty
      into v_product_id, v_name, v_rate, v_orig_discount, v_bill_qty
    from bill_items bi
    where bi.id = v_bill_item_id
      and bi.bill_id = v_bill_id
      and bi.business_id = v_biz;

    v_item_discount := ((v_orig_discount::numeric * v_qty::numeric) / v_bill_qty::numeric)::bigint;
    if v_item_discount < 0 then
      v_item_discount := 0;
    end if;
    if v_item_discount::numeric > v_qty::numeric * v_rate::numeric then
      v_item_discount := (v_qty::numeric * v_rate::numeric)::bigint;
    end if;
    v_line := v_qty::numeric * v_rate::numeric - v_item_discount::numeric;

    insert into credit_note_items (
      credit_note_id, bill_item_id, product_id, name_snapshot,
      qty_returned, rate, discount, line_total
    ) values (
      v_note_id, v_bill_item_id, v_product_id, v_name,
      v_qty, v_rate, v_item_discount, v_line::bigint
    );

    if v_restock and v_product_id is not null then
      insert into stock_movements (
        business_id, product_id, type, qty_delta, reason,
        ref_bill_id, ref_credit_note_id, created_by
      ) values (
        v_biz, v_product_id, 'return', v_qty,
        coalesce(v_reason, 'Sales return'),
        v_bill_id, v_note_id, v_member
      );
    end if;
  end loop;

  perform refresh_bill_status_for(v_bill_id);

  return jsonb_build_object(
    'credit_note', (select to_jsonb(cn.*) from credit_notes cn where cn.id = v_note_id),
    'created', true
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 10. Harden create_bill, record_customer_sale, send_quote with overflow
--     guards, advisory retry locks, array-type checks, and payment validation.
-- ---------------------------------------------------------------------------
create or replace function public.create_bill(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_customer_id uuid;
  v_order_id uuid;
  v_discount bigint;
  v_items_total numeric := 0;
  v_grand_total bigint;
  v_status bill_status;
  v_device_prefix text;
  v_guest_name text;
  v_reference_note text;
  v_created_at timestamptz;
  item jsonb;
  v_qty int;
  v_rate bigint;
  v_item_discount bigint;
  v_line numeric;
  v_payment jsonb;
  v_pay_amount bigint;
  v_pay_id uuid;
  v_member uuid;
  v_biz uuid;
  v_role text;
  order_row orders%rowtype;
  existing jsonb;
  result jsonb;
begin
  v_role := current_role_name();
  if v_role not in ('owner', 'sales', 'warehouse') then
    raise exception 'forbidden';
  end if;

  v_biz := current_business_id();
  v_member := current_member_id();
  v_id := coalesce(uuid_from_json(p->>'id'), gen_random_uuid());

  perform pg_advisory_xact_lock(hashtextextended('create_bill:' || v_id::text, 0));

  select to_jsonb(b.*) into existing
  from bills b
  where b.id = v_id and b.business_id = v_biz;
  if existing is not null then
    return jsonb_build_object('bill', existing, 'created', false);
  end if;

  v_customer_id := resolve_billing_customer(p);
  v_order_id := uuid_from_json(p->>'order_id');
  v_discount := coalesce((p->>'discount')::bigint, 0);
  v_device_prefix := p->>'device_prefix';
  v_payment := p->'payment';
  v_guest_name := nullif(btrim(coalesce(p->>'guest_name', '')), '');
  v_reference_note := nullif(btrim(coalesce(p->>'reference_note', '')), '');
  v_created_at := occurred_at_from_payload(p);

  if v_role = 'warehouse' and v_payment is not null and v_payment != 'null'::jsonb then
    raise exception 'warehouse cannot record payment with bill';
  end if;

  if v_payment is not null and v_payment != 'null'::jsonb then
    v_reference_note := null;
  end if;

  if v_customer_id is null then
    v_status := 'paid';
  else
    v_status := 'due';
    v_guest_name := null;
  end if;

  if jsonb_typeof(p->'items') is distinct from 'array'
     or jsonb_array_length(p->'items') = 0 then
    raise exception 'bill must have at least one item';
  end if;
  if jsonb_array_length(p->'items') > 500 then
    raise exception 'too many bill items';
  end if;

  for item in select * from jsonb_array_elements(p->'items')
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_item_discount := coalesce((item->>'discount')::bigint, 0);
    if v_qty is null or v_qty <= 0 or v_qty > 100000000 then
      raise exception 'item qty must be positive';
    end if;
    if v_rate is null or v_rate < 0 or v_rate > 100000000000 then
      raise exception 'item rate out of range';
    end if;
    v_line := v_qty::numeric * v_rate::numeric;
    if v_line > 9007199254740991 then
      raise exception 'item total out of range';
    end if;
    if v_item_discount < 0 or v_item_discount::numeric > v_line then
      raise exception 'item discount out of range';
    end if;
    v_items_total := v_items_total + (v_line - v_item_discount::numeric);
    if v_items_total > 9007199254740991 then
      raise exception 'bill total out of range';
    end if;
  end loop;

  if v_discount < 0 or v_discount::numeric > v_items_total then
    raise exception 'bill discount out of range';
  end if;
  v_grand_total := v_items_total::bigint - v_discount;

  if v_order_id is not null then
    select * into order_row from orders
    where id = v_order_id and business_id = v_biz
    for update;
    if order_row.id is null then
      raise exception 'order not found';
    end if;
    if exists (select 1 from bills where order_id = v_order_id) then
      raise exception 'order is already billed';
    end if;
    if order_row.status not in ('placed', 'received') then
      raise exception 'order must be placed or received before billing';
    end if;
    if v_customer_id is null then
      v_customer_id := order_row.customer_id;
      v_status := 'due';
      v_guest_name := null;
    end if;
  end if;

  if v_payment is not null and v_payment != 'null'::jsonb then
    v_pay_amount := coalesce((v_payment->>'amount')::bigint, 0);
    if v_pay_amount < 0 or v_pay_amount > 100000000000 then
      raise exception 'payment amount out of range';
    end if;
  end if;

  insert into bills (
    id, business_id, customer_id, order_id, device_prefix,
    items_total, discount, grand_total, status, created_by, guest_name,
    reference_note, created_at
  ) values (
    v_id, v_biz, v_customer_id, v_order_id, v_device_prefix,
    v_items_total::bigint, v_discount, v_grand_total, v_status, v_member, v_guest_name,
    v_reference_note, v_created_at
  );

  for item in select * from jsonb_array_elements(p->'items')
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_item_discount := coalesce((item->>'discount')::bigint, 0);
    insert into bill_items (
      bill_id, product_id, name_snapshot, qty, rate, discount, line_total
    ) values (
      v_id,
      uuid_from_json(item->>'product_id'),
      coalesce(item->>'name_snapshot', ''),
      v_qty,
      v_rate,
      v_item_discount,
      (v_qty::numeric * v_rate::numeric - v_item_discount::numeric)::bigint
    );
  end loop;

  if v_payment is not null and v_payment != 'null'::jsonb then
    v_pay_amount := coalesce((v_payment->>'amount')::bigint, 0);
    if v_pay_amount > 0 then
      if v_customer_id is null then
        raise exception 'payment requires a customer';
      end if;
      v_pay_id := coalesce(uuid_from_json(v_payment->>'id'), gen_random_uuid());
      insert into payments (
        id, business_id, customer_id, bill_id, amount, method, ref_note, received_by
      ) values (
        v_pay_id,
        v_biz,
        v_customer_id,
        v_id,
        v_pay_amount,
        (v_payment->>'method')::payment_method,
        v_payment->>'ref_note',
        v_member
      );
    end if;
  end if;

  if v_customer_id is null then
    update bills set status = 'paid' where id = v_id and status != 'paid';
  else
    perform refresh_bill_status_for(v_id);
  end if;

  if v_order_id is not null then
    update orders set status = 'billed' where id = v_order_id;
  end if;

  select to_jsonb(b.*) into result from bills b where b.id = v_id;
  return jsonb_build_object('bill', result, 'created', true);
end;
$$;

create or replace function public.record_customer_sale(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_customer_id uuid;
  v_amount bigint;
  v_note text;
  v_status bill_status;
  v_payment jsonb;
  v_pay_amount bigint;
  v_member uuid;
  v_biz uuid;
  v_created_at timestamptz;
  existing jsonb;
  result jsonb;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_biz := current_business_id();
  v_member := current_member_id();
  v_id := coalesce(uuid_from_json(p->>'id'), gen_random_uuid());

  perform pg_advisory_xact_lock(hashtextextended('record_customer_sale:' || v_id::text, 0));

  select to_jsonb(b.*) into existing
  from bills b
  where b.id = v_id and b.business_id = v_biz;
  if existing is not null then
    return jsonb_build_object('bill', existing, 'created', false);
  end if;

  v_customer_id := resolve_billing_customer(p);
  v_amount := (p->>'amount')::bigint;
  v_note := nullif(trim(coalesce(p->>'ref_note', '')), '');
  v_payment := p->'payment';
  v_created_at := occurred_at_from_payload(p);

  if v_customer_id is null then
    raise exception 'customer_id is required';
  end if;
  if v_amount is null or v_amount <= 0 then
    raise exception 'amount must be positive';
  end if;
  if v_amount > 100000000000 then
    raise exception 'amount out of range';
  end if;

  if v_payment is not null and v_payment != 'null'::jsonb then
    v_pay_amount := coalesce((v_payment->>'amount')::bigint, 0);
    if v_pay_amount < 0 or v_pay_amount > 100000000000 then
      raise exception 'payment amount out of range';
    end if;
  else
    v_pay_amount := 0;
  end if;

  v_status := 'due';

  insert into bills (
    id, business_id, customer_id, order_id, device_prefix,
    items_total, discount, grand_total, status, created_by, created_at
  ) values (
    v_id, v_biz, v_customer_id, null, p->>'device_prefix',
    v_amount, 0, v_amount, v_status, v_member, v_created_at
  );

  insert into bill_items (
    bill_id, product_id, name_snapshot, qty, rate, discount, line_total
  ) values (
    v_id,
    null,
    coalesce(v_note, 'Manual sale'),
    1,
    v_amount,
    0,
    v_amount
  );

  if v_pay_amount > 0 then
    insert into payments (
      id, business_id, customer_id, bill_id, amount, method, ref_note, received_by
    ) values (
      coalesce(uuid_from_json(v_payment->>'id'), gen_random_uuid()),
      v_biz,
      v_customer_id,
      v_id,
      v_pay_amount,
      (v_payment->>'method')::payment_method,
      coalesce(v_payment->>'ref_note', v_note),
      v_member
    );
  end if;

  perform refresh_bill_status_for(v_id);

  select to_jsonb(b.*) into result from bills b where b.id = v_id;
  return jsonb_build_object('bill', result, 'created', true);
end;
$$;

create or replace function public.send_quote(p_order_id uuid, p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  order_row orders%rowtype;
  item jsonb;
  v_version int;
  v_total numeric := 0;
  v_qty int;
  v_rate bigint;
  v_discount bigint;
  v_line numeric;
  v_quote_id uuid;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  select * into order_row from orders
  where id = p_order_id and business_id = current_business_id()
  for update;

  if order_row.id is null then
    raise exception 'order not found';
  end if;

  if order_row.status not in ('placed', 'received') then
    raise exception 'order cannot be quoted in status %', order_row.status;
  end if;

  if jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'quote must have at least one item';
  end if;
  if jsonb_array_length(p_items) > 500 then
    raise exception 'too many quote items';
  end if;

  for item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_discount := coalesce((item->>'discount')::bigint, 0);
    if v_qty is null or v_qty <= 0 or v_qty > 100000000 then
      raise exception 'item qty must be positive';
    end if;
    if v_rate is null or v_rate < 0 or v_rate > 100000000000 then
      raise exception 'item rate out of range';
    end if;
    v_line := v_qty::numeric * v_rate::numeric;
    if v_line > 9007199254740991 then
      raise exception 'item total out of range';
    end if;
    if v_discount < 0 or v_discount::numeric > v_line then
      raise exception 'item discount out of range';
    end if;
    v_total := v_total + (v_line - v_discount::numeric);
    if v_total > 9007199254740991 then
      raise exception 'quote total out of range';
    end if;
  end loop;

  update quotes set status = 'superseded'
  where order_id = p_order_id and status = 'sent';

  select coalesce(max(version), 0) + 1 into v_version
  from quotes where order_id = p_order_id;

  insert into quotes (order_id, version, status, total, created_by, expires_at)
  values (
    p_order_id,
    v_version,
    'sent',
    v_total::bigint,
    current_member_id(),
    now() + interval '7 days'
  )
  returning id into v_quote_id;

  for item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_discount := coalesce((item->>'discount')::bigint, 0);
    v_line := v_qty::numeric * v_rate::numeric - v_discount::numeric;
    insert into quote_items (quote_id, product_id, qty, rate, discount, line_total)
    values (
      v_quote_id,
      (item->>'product_id')::uuid,
      v_qty,
      v_rate,
      v_discount,
      v_line::bigint
    );
  end loop;

  return jsonb_build_object(
    'id', v_quote_id,
    'order_id', p_order_id,
    'version', v_version,
    'status', 'sent',
    'total', v_total::bigint,
    'expires_at', (now() + interval '7 days')
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 11. Harden search_bills, list_products_page, list_low_stock against LIKE
--     wildcard injection and unbounded p_limit DoS.
-- ---------------------------------------------------------------------------
create or replace function public.search_bills(
  p_query text default null,
  p_status bill_status default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_offset int default 0,
  p_limit int default 50
)
returns jsonb
language sql
stable
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_agg(row_data)
      from (
        select
          to_jsonb(b)
            || jsonb_build_object(
              'customers',
              case
                when c.customer_id is null then null
                else jsonb_build_object('shop_name', c.shop_name)
              end,
              'members',
              case
                when m.id is null then null
                else jsonb_build_object('display_name', m.display_name, 'role', m.role)
              end
            ) as row_data
        from bills b
        left join customer_directory c on c.customer_id = b.customer_id
        left join members m on m.id = b.created_by
        where b.business_id = (select current_business_id())
          and (p_status is null or b.status = p_status)
          and (p_from is null or b.created_at >= p_from)
          and (p_to is null or b.created_at < p_to)
          and (
            p_query is null
            or length(btrim(p_query)) = 0
            or b.bill_no ilike '%' || escape_like_pattern(p_query) || '%' escape '\'
            or coalesce(b.guest_name, '') ilike '%' || escape_like_pattern(p_query) || '%' escape '\'
            or coalesce(c.shop_name, '') ilike '%' || escape_like_pattern(p_query) || '%' escape '\'
          )
          and (
            (select current_role_name()) in ('owner', 'sales', 'warehouse')
            or (
              (select current_role_name()) = 'customer'
              and b.customer_id = (select own_customer_id())
            )
          )
        order by b.created_at desc
        offset greatest(coalesce(p_offset, 0), 0)
        limit least(greatest(coalesce(p_limit, 50), 1), 200)
      ) ranked
    ),
    '[]'::jsonb
  );
$$;

create or replace function public.list_products_page(
  p_active_only boolean default true,
  p_query text default null,
  p_stock_filter text default 'all',
  p_offset int default 0,
  p_limit int default 50
)
returns jsonb
language sql
stable
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_agg(to_jsonb(p) order by p.name)
      from (
        select *
        from products prod
        where prod.business_id = (select current_business_id())
          and prod.is_active = p_active_only
          and (
            p_query is null
            or length(btrim(p_query)) = 0
            or prod.name ilike '%' || escape_like_pattern(p_query) || '%' escape '\'
            or coalesce(prod.sku, '') ilike '%' || escape_like_pattern(p_query) || '%' escape '\'
            or coalesce(prod.name_np, '') ilike '%' || escape_like_pattern(p_query) || '%' escape '\'
          )
          and (
            coalesce(p_stock_filter, 'all') = 'all'
            or (
              p_stock_filter = 'low'
              and prod.low_stock_threshold > 0
              and prod.stock_cached <= prod.low_stock_threshold
            )
            or (
              p_stock_filter = 'out'
              and prod.stock_cached <= 0
            )
            or (
              p_stock_filter = 'inStock'
              and prod.stock_cached > 0
              and (
                prod.low_stock_threshold <= 0
                or prod.stock_cached > prod.low_stock_threshold
              )
            )
          )
          and (select current_role_name()) in ('owner', 'sales', 'warehouse')
        order by prod.name
        offset greatest(coalesce(p_offset, 0), 0)
        limit least(greatest(coalesce(p_limit, 50), 1), 200)
      ) p
    ),
    '[]'::jsonb
  );
$$;

create or replace function public.list_low_stock(p_limit integer default 50)
returns jsonb
language sql
stable
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_agg(to_jsonb(row) order by row.name)
      from (
        select
          p.id,
          p.business_id,
          p.name,
          p.name_np,
          p.sku,
          p.unit,
          p.cost_price,
          p.reference_price,
          p.image_url,
          p.low_stock_threshold,
          p.stock_cached,
          p.is_active,
          p.updated_at,
          p.created_at
        from products p
        where p.business_id = (select current_business_id())
          and p.is_active = true
          and p.low_stock_threshold > 0
          and p.stock_cached <= p.low_stock_threshold
          and (select current_role_name()) in ('owner', 'sales', 'warehouse')
        order by p.name
        limit least(greatest(coalesce(p_limit, 50), 0), 200)
      ) row
    ),
    '[]'::jsonb
  );
$$;
