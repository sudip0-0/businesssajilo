-- Phase 3: payments, customer balances, ledger views, extended RLS.

create table payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  customer_id uuid not null references customers(id),
  bill_id uuid,
  amount bigint not null,
  method payment_method not null,
  ref_note text,
  received_by uuid not null references members(id),
  created_at timestamptz not null default now(),
  constraint payment_amount_positive check (amount > 0)
);

create index payments_customer_idx on payments(customer_id);
create index payments_business_idx on payments(business_id);

create trigger payments_set_business
  before insert on payments
  for each row execute function set_row_business_id();

-- Per-customer balance: opening_balance minus payments (bill debits added in Phase 4).
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
  coalesce(pay.total_paid, 0::bigint) as total_paid,
  c.opening_balance - coalesce(pay.total_paid, 0::bigint) as balance_due
from customers c
left join (
  select customer_id, sum(amount) as total_paid
  from payments
  group by customer_id
) pay on pay.customer_id = c.id;

-- Ledger statement rows: opening balance + payments.
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

-- Extended RLS: sales can read customers.
create policy "sales reads customers" on customers
  for select using (
    business_id = current_business_id()
    and current_role_name() = 'sales'
  );

-- RLS: payments (append-only — no update/delete policies)
alter table payments enable row level security;

create policy "owner sales read payments" on payments
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  );

create policy "customer reads own payments" on payments
  for select using (
    customer_id in (
      select id from customers
      where member_id = (
        select id from members
        where auth_user_id = auth.uid() and is_active
      )
    )
  );

create policy "owner inserts payments" on payments
  for insert with check (
    business_id = current_business_id()
    and current_role_name() = 'owner'
    and received_by = current_member_id()
  );

create policy "sales inserts payments" on payments
  for insert with check (
    business_id = current_business_id()
    and current_role_name() = 'sales'
    and received_by = current_member_id()
  );

alter table payments force row level security;

grant select on customer_balances to authenticated;
grant select on customer_ledger_entries to authenticated;
