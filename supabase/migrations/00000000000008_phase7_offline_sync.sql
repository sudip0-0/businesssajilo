-- Phase 7: offline sync support — audit_log, pull watermarks, product sync RPC.

create type audit_source as enum ('sync_lww', 'manual');

create table audit_log (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  table_name text not null,
  record_id uuid not null,
  field_name text not null,
  old_value text,
  new_value text,
  changed_by uuid references members(id),
  changed_at timestamptz not null default now(),
  source audit_source not null default 'sync_lww'
);

create index audit_log_business_idx on audit_log(business_id);
create index audit_log_record_idx on audit_log(table_name, record_id);

-- Pull watermarks for customers and categories (products already has updated_at).
alter table customers
  add column if not exists updated_at timestamptz not null default now();

alter table categories
  add column if not exists updated_at timestamptz not null default now();

create or replace function bump_updated_at()
returns trigger
language plpgsql
as $$
begin
  NEW.updated_at := now();
  return NEW;
end;
$$;

create trigger customers_updated_at
  before update on customers
  for each row execute function bump_updated_at();

create trigger categories_updated_at
  before update on categories
  for each row execute function bump_updated_at();

-- Audit helper (security definer — clients never insert directly).
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

grant execute on function insert_audit_log(text, uuid, text, text, text, audit_source) to authenticated;

-- LWW product merge from offline pull conflicts (server wins when newer).
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

grant execute on function apply_product_sync(
  uuid, text, text, text, uuid, text, bigint, bigint, text, int, int, boolean, timestamptz
) to authenticated;

-- RLS: audit_log (staff read-only within tenant).
alter table audit_log enable row level security;

create policy "staff reads audit log" on audit_log
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales', 'warehouse')
  );

alter table audit_log force row level security;

-- Expose customers.updated_at on balance view for delta pull.
drop view if exists customer_ledger_entries;
drop view if exists customer_balances;

create view customer_balances as
select
  c.id as customer_id,
  c.business_id,
  c.member_id,
  c.shop_name,
  c.contact_name,
  c.phone,
  c.address,
  c.opening_balance,
  c.created_at,
  c.updated_at,
  coalesce(bill.total_billed, 0::bigint) as total_billed,
  coalesce(pay.total_paid, 0::bigint) as total_paid,
  c.opening_balance
    + coalesce(bill.total_billed, 0::bigint)
    - coalesce(pay.total_paid, 0::bigint) as balance_due
from customers c
left join (
  select customer_id, sum(grand_total) as total_billed
  from bills
  where customer_id is not null
  group by customer_id
) bill on bill.customer_id = c.id
left join (
  select customer_id, sum(amount) as total_paid
  from payments
  group by customer_id
) pay on pay.customer_id = c.id;

create view customer_ledger_entries as
select
  customer_id,
  business_id,
  occurred_at,
  entry_type,
  description,
  debit_paisa,
  credit_paisa,
  ref_id
from (
  select
    c.id as customer_id,
    c.business_id,
    c.created_at as occurred_at,
    'opening_balance'::text as entry_type,
    'Opening balance'::text as description,
    c.opening_balance as debit_paisa,
    0::bigint as credit_paisa,
    null::uuid as ref_id
  from customers c
  where c.opening_balance != 0
  union all
  select
    b.customer_id,
    b.business_id,
    b.created_at,
    'bill'::text,
    b.bill_no,
    b.grand_total,
    0::bigint,
    b.id
  from bills b
  where b.customer_id is not null
  union all
  select
    p.customer_id,
    p.business_id,
    p.created_at,
    'payment'::text,
    coalesce(nullif(trim(p.ref_note), ''), initcap(p.method::text)),
    0::bigint,
    p.amount,
    p.id
  from payments p
) entries;

grant select on customer_balances to authenticated;
grant select on customer_ledger_entries to authenticated;
