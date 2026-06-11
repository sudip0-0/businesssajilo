-- Phase 10: security & integrity hardening.
-- bill_sequences RLS, cross-tenant FK guards, RPC role checks, transactional
-- billing/quoting RPCs, bill status lifecycle, walk-in stock deduction,
-- column pinning, NPT report timezones, composite indexes.

-- ---------------------------------------------------------------------------
-- 1. bill_sequences: lock down (mutated only via SECURITY DEFINER trigger).
-- ---------------------------------------------------------------------------

alter table bill_sequences enable row level security;
alter table bill_sequences force row level security;
revoke all on bill_sequences from authenticated, anon;

-- ---------------------------------------------------------------------------
-- 2. bills.updated_at (delta sync of status changes) + composite indexes.
-- ---------------------------------------------------------------------------

alter table bills add column updated_at timestamptz not null default now();

create trigger bills_updated_at
  before update on bills
  for each row execute function bump_updated_at();

create index bills_business_created_idx on bills(business_id, created_at desc);
create index bills_business_updated_idx on bills(business_id, updated_at);
create unique index bills_order_unique_idx on bills(order_id) where order_id is not null;
create index payments_business_created_idx on payments(business_id, created_at);
create index stock_movements_business_created_idx on stock_movements(business_id, created_at);
create index notifications_recipient_created_idx on notifications(recipient_member_id, created_at desc);
create index messages_order_created_idx on messages(order_id, created_at);
create index products_business_updated_idx on products(business_id, updated_at);
create index customers_business_updated_idx on customers(business_id, updated_at);
create index bill_items_product_idx on bill_items(product_id);
create index audit_log_business_changed_idx on audit_log(business_id, changed_at desc);

-- ---------------------------------------------------------------------------
-- 3. Bill numbering: do not depend on trigger execution order for business_id.
-- ---------------------------------------------------------------------------

create or replace function assign_bill_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  seq int;
  biz uuid;
begin
  biz := coalesce(NEW.business_id, current_business_id());
  if biz is null then
    raise exception 'cannot assign bill number without business context';
  end if;
  NEW.business_id := biz;

  insert into bill_sequences (business_id, next_no)
  values (biz, 2)
  on conflict (business_id) do update
    set next_no = bill_sequences.next_no + 1
  returning bill_sequences.next_no - 1 into seq;

  NEW.bill_no := 'BS-' || lpad(seq::text, 4, '0');
  return NEW;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Cross-tenant FK guards (block guessed UUIDs across businesses).
-- ---------------------------------------------------------------------------

create or replace function guard_stock_movement_refs()
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
  return NEW;
end;
$$;

create trigger stock_movements_guard_refs
  before insert on stock_movements
  for each row execute function guard_stock_movement_refs();

create or replace function guard_payment_refs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  cust_biz uuid;
  bill_row bills%rowtype;
begin
  select business_id into cust_biz from customers where id = NEW.customer_id;
  if cust_biz is null or cust_biz != NEW.business_id then
    raise exception 'customer does not belong to this business';
  end if;
  if NEW.bill_id is not null then
    select * into bill_row from bills where id = NEW.bill_id;
    if bill_row.id is null or bill_row.business_id != NEW.business_id then
      raise exception 'bill does not belong to this business';
    end if;
    if bill_row.customer_id is distinct from NEW.customer_id then
      raise exception 'bill does not belong to this customer';
    end if;
  end if;
  return NEW;
end;
$$;

create trigger payments_guard_refs
  before insert on payments
  for each row execute function guard_payment_refs();

create or replace function guard_bill_item_refs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  bill_biz uuid;
begin
  select business_id into bill_biz from bills where id = NEW.bill_id;
  if not exists (
    select 1 from products where id = NEW.product_id and business_id = bill_biz
  ) then
    raise exception 'product does not belong to this business';
  end if;
  return NEW;
end;
$$;

create trigger bill_items_guard_refs
  before insert on bill_items
  for each row execute function guard_bill_item_refs();

create or replace function guard_order_item_refs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  order_biz uuid;
begin
  select business_id into order_biz from orders where id = NEW.order_id;
  if not exists (
    select 1 from products where id = NEW.product_id and business_id = order_biz
  ) then
    raise exception 'product does not belong to this business';
  end if;
  return NEW;
end;
$$;

create trigger order_items_guard_refs
  before insert on order_items
  for each row execute function guard_order_item_refs();

create or replace function guard_quote_item_refs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  order_biz uuid;
begin
  select o.business_id into order_biz
  from quotes q join orders o on o.id = q.order_id
  where q.id = NEW.quote_id;
  if not exists (
    select 1 from products where id = NEW.product_id and business_id = order_biz
  ) then
    raise exception 'product does not belong to this business';
  end if;
  return NEW;
end;
$$;

create trigger quote_items_guard_refs
  before insert on quote_items
  for each row execute function guard_quote_item_refs();

-- ---------------------------------------------------------------------------
-- 5. Line math integrity (no negative lines; totals derived from qty/rate).
-- ---------------------------------------------------------------------------

alter table bill_items
  add constraint bill_item_line_math check (
    rate >= 0
    and discount >= 0
    and discount <= qty * rate
    and line_total = qty * rate - discount
  );

alter table quote_items
  add constraint quote_item_line_math check (
    rate >= 0
    and discount >= 0
    and discount <= qty * rate
    and line_total = qty * rate - discount
  );

-- ---------------------------------------------------------------------------
-- 6. RPC role checks (previously callable by any authenticated member).
-- ---------------------------------------------------------------------------

create or replace function insert_audit_log(
  p_table_name text,
  p_record_id uuid,
  p_field_name text,
  p_old_value text,
  p_new_value text,
  p_source audit_source default 'sync_lww'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
begin
  if current_role_name() not in ('owner', 'sales', 'warehouse') then
    raise exception 'forbidden';
  end if;

  insert into audit_log (
    business_id, table_name, record_id, field_name,
    old_value, new_value, changed_by, source
  )
  values (
    current_business_id(),
    p_table_name,
    p_record_id,
    p_field_name,
    p_old_value,
    p_new_value,
    current_member_id(),
    p_source
  )
  returning id into new_id;
  return new_id;
end;
$$;

create or replace function apply_product_sync(
  p_id uuid,
  p_name text,
  p_name_np text,
  p_sku text,
  p_category_id uuid,
  p_unit text,
  p_cost_price bigint,
  p_reference_price bigint,
  p_image_url text,
  p_low_stock_threshold int,
  p_stock_cached int,
  p_is_active boolean,
  p_client_updated_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  server_row products%rowtype;
  result_action text;
  result_product jsonb;
begin
  if current_role_name() != 'owner' then
    raise exception 'forbidden';
  end if;

  select * into server_row from products where id = p_id;

  if not found then
    return jsonb_build_object('action', 'not_found');
  end if;

  if server_row.business_id != current_business_id() then
    raise exception 'forbidden';
  end if;

  if server_row.updated_at >= p_client_updated_at then
    result_action := 'server_wins';
  else
    update products set
      name = p_name,
      name_np = p_name_np,
      sku = p_sku,
      category_id = p_category_id,
      unit = p_unit,
      cost_price = p_cost_price,
      reference_price = p_reference_price,
      image_url = p_image_url,
      low_stock_threshold = p_low_stock_threshold,
      is_active = p_is_active
    where id = p_id;

    perform insert_audit_log(
      'products', p_id, 'sync_merge',
      server_row.name, p_name, 'sync_lww'
    );
    result_action := 'client_wins';
  end if;

  select to_jsonb(p.*) into result_product from products p where id = p_id;
  return jsonb_build_object('action', result_action, 'product', result_product);
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. Column pinning: members (no role/tenant escalation), orders.
-- ---------------------------------------------------------------------------

create or replace function pin_member_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Service-role / internal paths have no member context and are unrestricted.
  if current_role_name() is null then
    return NEW;
  end if;
  if NEW.role is distinct from OLD.role
     or NEW.business_id is distinct from OLD.business_id
     or NEW.auth_user_id is distinct from OLD.auth_user_id then
    raise exception 'member role and tenancy cannot be changed';
  end if;
  return NEW;
end;
$$;

create trigger members_pin_columns
  before update on members
  for each row execute function pin_member_columns();

create or replace function pin_order_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_role_name() is null then
    return NEW;
  end if;
  if NEW.customer_id is distinct from OLD.customer_id
     or NEW.business_id is distinct from OLD.business_id
     or NEW.created_at is distinct from OLD.created_at then
    raise exception 'order identity columns cannot be changed';
  end if;
  if current_role_name() = 'warehouse'
     and NEW.customer_note is distinct from OLD.customer_note then
    raise exception 'warehouse can only change order status';
  end if;
  return NEW;
end;
$$;

create trigger orders_pin_columns
  before update on orders
  for each row execute function pin_order_columns();

-- ---------------------------------------------------------------------------
-- 8. Stock recalc: serialize per product (prevents lost updates).
-- ---------------------------------------------------------------------------

create or replace function recalc_product_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_stock int;
begin
  perform 1 from products where id = NEW.product_id for update;

  select coalesce(sum(qty_delta), 0)::int into new_stock
  from stock_movements
  where product_id = NEW.product_id;

  update products
  set stock_cached = new_stock,
      updated_at = now()
  where id = NEW.product_id;

  return NEW;
end;
$$;

-- ---------------------------------------------------------------------------
-- 9. Walk-in (counter) bills deduct stock.
-- ---------------------------------------------------------------------------

alter table stock_movements
  add column ref_bill_id uuid references bills(id);

create index stock_movements_ref_bill_idx on stock_movements(ref_bill_id);

create or replace function deduct_stock_for_bill_item()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  bill_row bills%rowtype;
begin
  select * into bill_row from bills where id = NEW.bill_id;

  -- Order-based bills deduct on dispatch; only counter bills deduct here.
  if bill_row.order_id is not null then
    return NEW;
  end if;

  if exists (
    select 1 from stock_movements
    where ref_bill_id = NEW.bill_id and product_id = NEW.product_id and type = 'dispatch'
  ) then
    return NEW;
  end if;

  insert into stock_movements (
    business_id, product_id, type, qty_delta, reason, ref_bill_id, created_by
  ) values (
    bill_row.business_id,
    NEW.product_id,
    'dispatch',
    -NEW.qty,
    'Counter sale ' || bill_row.bill_no,
    NEW.bill_id,
    bill_row.created_by
  );

  return NEW;
end;
$$;

create trigger bill_items_deduct_stock
  after insert on bill_items
  for each row execute function deduct_stock_for_bill_item();

-- ---------------------------------------------------------------------------
-- 10. Payments keep bill status correct (due -> partial -> paid).
-- ---------------------------------------------------------------------------

create or replace function refresh_bill_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  bill_row bills%rowtype;
  paid_sum bigint;
  new_status bill_status;
begin
  if NEW.bill_id is null then
    return NEW;
  end if;

  select * into bill_row from bills where id = NEW.bill_id for update;
  if bill_row.id is null then
    return NEW;
  end if;

  select coalesce(sum(amount), 0) into paid_sum
  from payments where bill_id = NEW.bill_id;

  if paid_sum >= bill_row.grand_total then
    new_status := 'paid';
  elsif paid_sum > 0 then
    new_status := 'partial';
  else
    new_status := 'due';
  end if;

  if new_status is distinct from bill_row.status then
    update bills set status = new_status where id = NEW.bill_id;
  end if;

  return NEW;
end;
$$;

create trigger payments_refresh_bill_status
  after insert on payments
  for each row execute function refresh_bill_status();

-- ---------------------------------------------------------------------------
-- 11. Opening balance is immutable once the ledger has activity.
-- ---------------------------------------------------------------------------

create or replace function guard_opening_balance()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.opening_balance is distinct from OLD.opening_balance then
    if exists (select 1 from bills where customer_id = NEW.id)
       or exists (select 1 from payments where customer_id = NEW.id) then
      raise exception 'opening balance cannot be changed once the customer has bills or payments';
    end if;
  end if;
  return NEW;
end;
$$;

create trigger customers_guard_opening_balance
  before update on customers
  for each row execute function guard_opening_balance();

-- ---------------------------------------------------------------------------
-- 12. Auth claims: remove stale tenancy claims on deactivation / delete.
-- ---------------------------------------------------------------------------

create or replace function sync_auth_claims()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'DELETE' then
    update auth.users
    set raw_app_meta_data =
      (coalesce(raw_app_meta_data, '{}'::jsonb) - 'business_id' - 'role')
      || jsonb_build_object('deactivated', true)
    where id = OLD.auth_user_id;
    return OLD;
  end if;

  if NEW.is_active then
    update auth.users
    set raw_app_meta_data =
      (coalesce(raw_app_meta_data, '{}'::jsonb) - 'deactivated')
      || jsonb_build_object(
        'business_id', NEW.business_id::text,
        'role', NEW.role::text
      )
    where id = NEW.auth_user_id;
  else
    update auth.users
    set raw_app_meta_data =
      (coalesce(raw_app_meta_data, '{}'::jsonb) - 'business_id' - 'role')
      || jsonb_build_object('deactivated', true)
    where id = NEW.auth_user_id;
  end if;

  return NEW;
end;
$$;

drop trigger if exists members_sync_auth_claims on members;
create trigger members_sync_auth_claims
  after insert or update of business_id, role, is_active or delete on members
  for each row
  execute function sync_auth_claims();

-- ---------------------------------------------------------------------------
-- 13. Drop unused SECURITY DEFINER catalog view (RPC is the only safe path).
-- ---------------------------------------------------------------------------

drop view if exists catalog_products;

-- Ledger views: pin to invoker security explicitly.
alter view customer_balances set (security_invoker = true);
alter view customer_ledger_entries set (security_invoker = true);

-- ---------------------------------------------------------------------------
-- 14. Reports in Nepal time (UTC+5:45), not UTC.
-- ---------------------------------------------------------------------------

create or replace view report_sales_daily
with (security_invoker = true) as
select
  b.business_id,
  (b.created_at at time zone 'Asia/Kathmandu')::date as sale_date,
  count(*)::int as bill_count,
  coalesce(sum(b.grand_total), 0::bigint) as total_sales
from bills b
where current_role_name() in ('owner', 'sales')
group by b.business_id, (b.created_at at time zone 'Asia/Kathmandu')::date;

create or replace view report_top_products
with (security_invoker = true) as
select
  b.business_id,
  bi.product_id,
  bi.name_snapshot,
  (b.created_at at time zone 'Asia/Kathmandu')::date as sale_date,
  sum(bi.qty)::bigint as qty_sold,
  coalesce(sum(bi.line_total), 0::bigint) as revenue
from bill_items bi
join bills b on b.id = bi.bill_id
where current_role_name() in ('owner', 'sales')
group by b.business_id, bi.product_id, bi.name_snapshot,
  (b.created_at at time zone 'Asia/Kathmandu')::date;

create or replace view report_top_customers
with (security_invoker = true) as
select
  b.business_id,
  b.customer_id,
  c.shop_name,
  (b.created_at at time zone 'Asia/Kathmandu')::date as sale_date,
  count(*)::int as bill_count,
  coalesce(sum(b.grand_total), 0::bigint) as revenue
from bills b
join customers c on c.id = b.customer_id
where b.customer_id is not null
  and current_role_name() in ('owner', 'sales')
group by b.business_id, b.customer_id, c.shop_name,
  (b.created_at at time zone 'Asia/Kathmandu')::date;

create or replace view customer_dues_aging
with (security_invoker = true) as
select
  cb.business_id,
  cb.customer_id,
  cb.shop_name,
  cb.balance_due,
  coalesce(oldest.oldest_due_at, c.created_at) as oldest_due_at,
  greatest(
    0,
    ((now() at time zone 'Asia/Kathmandu')::date
      - (coalesce(oldest.oldest_due_at, c.created_at) at time zone 'Asia/Kathmandu')::date)
  )::int as age_days,
  case
    when greatest(
      0,
      ((now() at time zone 'Asia/Kathmandu')::date
        - (coalesce(oldest.oldest_due_at, c.created_at) at time zone 'Asia/Kathmandu')::date)
    ) <= 30 then '0_30'
    when greatest(
      0,
      ((now() at time zone 'Asia/Kathmandu')::date
        - (coalesce(oldest.oldest_due_at, c.created_at) at time zone 'Asia/Kathmandu')::date)
    ) <= 60 then '31_60'
    else '60_plus'
  end as bucket
from customer_balances cb
join customers c on c.id = cb.customer_id
left join (
  select customer_id, min(created_at) as oldest_due_at
  from bills
  where customer_id is not null
    and status in ('due', 'partial')
  group by customer_id
) oldest on oldest.customer_id = cb.customer_id
where cb.balance_due > 0
  and current_role_name() in ('owner', 'sales');

-- Server-side top-N aggregation (replaces client-side full-range fetch).
create or replace function report_top_products_range(
  p_from date,
  p_to date,
  p_limit int default 5
)
returns table (
  product_id uuid,
  name_snapshot text,
  qty_sold bigint,
  revenue bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    bi.product_id,
    min(bi.name_snapshot) as name_snapshot,
    sum(bi.qty)::bigint as qty_sold,
    coalesce(sum(bi.line_total), 0::bigint) as revenue
  from bill_items bi
  join bills b on b.id = bi.bill_id
  where b.business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
    and (b.created_at at time zone 'Asia/Kathmandu')::date between p_from and p_to
  group by bi.product_id
  order by revenue desc
  limit greatest(1, least(p_limit, 50));
$$;

create or replace function report_top_customers_range(
  p_from date,
  p_to date,
  p_limit int default 5
)
returns table (
  customer_id uuid,
  shop_name text,
  bill_count int,
  revenue bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    b.customer_id,
    min(c.shop_name) as shop_name,
    count(*)::int as bill_count,
    coalesce(sum(b.grand_total), 0::bigint) as revenue
  from bills b
  join customers c on c.id = b.customer_id
  where b.business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
    and b.customer_id is not null
    and (b.created_at at time zone 'Asia/Kathmandu')::date between p_from and p_to
  group by b.customer_id
  order by revenue desc
  limit greatest(1, least(p_limit, 50));
$$;

grant execute on function report_top_products_range(date, date, int) to authenticated;
grant execute on function report_top_customers_range(date, date, int) to authenticated;

-- ---------------------------------------------------------------------------
-- 15. Quote superseding + transactional send_quote RPC.
-- ---------------------------------------------------------------------------

alter type quote_status add value if not exists 'superseded';

create or replace function send_quote(
  p_order_id uuid,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  order_row orders%rowtype;
  item jsonb;
  v_version int;
  v_total bigint := 0;
  v_qty int;
  v_rate bigint;
  v_discount bigint;
  v_line bigint;
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

  if order_row.status not in ('placed', 'quoted', 'rejected') then
    raise exception 'order cannot be quoted in status %', order_row.status;
  end if;

  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'quote must have at least one item';
  end if;

  for item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_discount := coalesce((item->>'discount')::bigint, 0);
    if v_qty is null or v_qty <= 0 then
      raise exception 'item qty must be positive';
    end if;
    if v_rate is null or v_rate < 0 then
      raise exception 'item rate cannot be negative';
    end if;
    if v_discount < 0 or v_discount > v_qty * v_rate then
      raise exception 'item discount out of range';
    end if;
    v_total := v_total + (v_qty * v_rate - v_discount);
  end loop;

  -- Supersede earlier outstanding quotes for this order.
  update quotes set status = 'superseded'
  where order_id = p_order_id and status = 'sent';

  select coalesce(max(version), 0) + 1 into v_version
  from quotes where order_id = p_order_id;

  insert into quotes (order_id, version, status, total, created_by)
  values (p_order_id, v_version, 'sent', v_total, current_member_id())
  returning id into v_quote_id;

  for item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_discount := coalesce((item->>'discount')::bigint, 0);
    v_line := v_qty * v_rate - v_discount;
    insert into quote_items (quote_id, product_id, qty, rate, discount, line_total)
    values (v_quote_id, (item->>'product_id')::uuid, v_qty, v_rate, v_discount, v_line);
  end loop;

  return jsonb_build_object(
    'id', v_quote_id,
    'version', v_version,
    'total', v_total
  );
end;
$$;

grant execute on function send_quote(uuid, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- 16. Transactional, idempotent bill creation (counter + from-order).
-- ---------------------------------------------------------------------------

create or replace function create_bill(p jsonb)
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
  v_items_total bigint := 0;
  v_grand_total bigint;
  v_status bill_status;
  v_device_prefix text;
  item jsonb;
  v_qty int;
  v_rate bigint;
  v_item_discount bigint;
  v_payment jsonb;
  v_pay_amount bigint;
  v_member uuid;
  order_row orders%rowtype;
  existing jsonb;
  result jsonb;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_member := current_member_id();
  v_id := coalesce((p->>'id')::uuid, gen_random_uuid());

  -- Idempotency: replays (e.g. offline sync retries) return the existing bill.
  select to_jsonb(b.*) into existing
  from bills b
  where b.id = v_id and b.business_id = current_business_id();
  if existing is not null then
    return jsonb_build_object('bill', existing, 'created', false);
  end if;

  v_customer_id := (p->>'customer_id')::uuid;
  v_order_id := (p->>'order_id')::uuid;
  v_discount := coalesce((p->>'discount')::bigint, 0);
  v_status := coalesce((p->>'status'), 'due')::bill_status;
  v_device_prefix := p->>'device_prefix';
  v_payment := p->'payment';

  if v_customer_id is not null and not exists (
    select 1 from customers
    where id = v_customer_id and business_id = current_business_id()
  ) then
    raise exception 'customer not found';
  end if;

  if p->'items' is null or jsonb_array_length(p->'items') = 0 then
    raise exception 'bill must have at least one item';
  end if;

  for item in select * from jsonb_array_elements(p->'items')
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_item_discount := coalesce((item->>'discount')::bigint, 0);
    if v_qty is null or v_qty <= 0 then
      raise exception 'item qty must be positive';
    end if;
    if v_rate is null or v_rate < 0 then
      raise exception 'item rate cannot be negative';
    end if;
    if v_item_discount < 0 or v_item_discount > v_qty * v_rate then
      raise exception 'item discount out of range';
    end if;
    v_items_total := v_items_total + (v_qty * v_rate - v_item_discount);
  end loop;

  if v_discount < 0 or v_discount > v_items_total then
    raise exception 'bill discount out of range';
  end if;
  v_grand_total := v_items_total - v_discount;

  if v_order_id is not null then
    select * into order_row from orders
    where id = v_order_id and business_id = current_business_id()
    for update;
    if order_row.id is null then
      raise exception 'order not found';
    end if;
    if exists (select 1 from bills where order_id = v_order_id) then
      raise exception 'order is already billed';
    end if;
    if order_row.status != 'dispatched' then
      raise exception 'order must be dispatched before billing';
    end if;
    if v_customer_id is null then
      v_customer_id := order_row.customer_id;
    end if;
  end if;

  insert into bills (
    id, business_id, customer_id, order_id, device_prefix,
    items_total, discount, grand_total, status, created_by
  ) values (
    v_id, current_business_id(), v_customer_id, v_order_id, v_device_prefix,
    v_items_total, v_discount, v_grand_total, v_status, v_member
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
      (item->>'product_id')::uuid,
      coalesce(item->>'name_snapshot', ''),
      v_qty,
      v_rate,
      v_item_discount,
      v_qty * v_rate - v_item_discount
    );
  end loop;

  if v_payment is not null then
    v_pay_amount := coalesce((v_payment->>'amount')::bigint, 0);
    if v_pay_amount > 0 then
      if v_customer_id is null then
        raise exception 'payment requires a customer';
      end if;
      insert into payments (
        business_id, customer_id, bill_id, amount, method, ref_note, received_by
      ) values (
        current_business_id(),
        v_customer_id,
        v_id,
        v_pay_amount,
        (v_payment->>'method')::payment_method,
        v_payment->>'ref_note',
        v_member
      );
    end if;
  end if;

  -- Customer-less (walk-in) bills are settled at the counter.
  if v_customer_id is null then
    update bills set status = 'paid' where id = v_id and status != 'paid';
  end if;

  if v_order_id is not null then
    update orders set status = 'billed' where id = v_order_id;
  end if;

  select to_jsonb(b.*) into result from bills b where b.id = v_id;
  return jsonb_build_object('bill', result, 'created', true);
end;
$$;

grant execute on function create_bill(jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- 17. Push idempotency: notify function marks notifications as pushed.
-- ---------------------------------------------------------------------------

alter table notifications add column pushed_at timestamptz;

-- ---------------------------------------------------------------------------
-- 18. Chat image uploads must live under {business_id}/{order_id}/.
-- ---------------------------------------------------------------------------

drop policy if exists "chat participants upload images" on storage.objects;

create policy "chat participants upload images" on storage.objects
  for insert with check (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() in ('owner', 'sales', 'customer')
    and (storage.foldername(name))[2] in (
      select id::text from orders where business_id = current_business_id()
    )
  );
