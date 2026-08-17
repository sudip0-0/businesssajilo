-- Additive customer_balance_projections table. Live reads stay on
-- customer_balances until EXPLAIN benchmarks + parity checks pass.
-- Switch consumers only after reconciling customer_balance_projection_drift.

create table customer_balance_projections (
  customer_id uuid primary key references customers(id) on delete cascade,
  business_id uuid not null references businesses(id),
  total_billed bigint not null default 0,
  total_credited bigint not null default 0,
  total_paid bigint not null default 0,
  opening_balance bigint not null default 0,
  balance_due bigint not null default 0,
  last_bill_at timestamptz,
  last_credit_at timestamptz,
  last_payment_at timestamptz,
  updated_at timestamptz not null default now()
);

create index customer_balance_projections_business_idx
  on customer_balance_projections (business_id, updated_at desc);

alter table customer_balance_projections enable row level security;
alter table customer_balance_projections force row level security;

create policy "staff read own business balance projections"
  on customer_balance_projections
  for select
  using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  );

revoke all on customer_balance_projections from anon;
grant select on customer_balance_projections to authenticated;

create or replace function refresh_customer_balance_projection(p_customer_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  billed bigint;
  credited bigint;
  paid bigint;
  opening bigint;
  biz uuid;
  last_bill timestamptz;
  last_credit timestamptz;
  last_pay timestamptz;
begin
  if p_customer_id is null then
    return;
  end if;

  select
    c.business_id,
    c.opening_balance,
    coalesce(bill.total_billed, 0),
    coalesce(cn.total_credited, 0),
    coalesce(pay.total_paid, 0),
    bill.last_at,
    cn.last_at,
    pay.last_at
  into biz, opening, billed, credited, paid, last_bill, last_credit, last_pay
  from customers c
  left join (
    select customer_id, sum(grand_total) as total_billed, max(created_at) as last_at
    from bills
    where customer_id = p_customer_id
    group by customer_id
  ) bill on bill.customer_id = c.id
  left join (
    select customer_id, sum(grand_total) as total_credited, max(created_at) as last_at
    from credit_notes
    where customer_id = p_customer_id
    group by customer_id
  ) cn on cn.customer_id = c.id
  left join (
    select customer_id, sum(amount) as total_paid, max(created_at) as last_at
    from payments
    where customer_id = p_customer_id
    group by customer_id
  ) pay on pay.customer_id = c.id
  where c.id = p_customer_id;

  if not found then
    delete from customer_balance_projections where customer_id = p_customer_id;
    return;
  end if;

  insert into customer_balance_projections (
    customer_id,
    business_id,
    total_billed,
    total_credited,
    total_paid,
    opening_balance,
    balance_due,
    last_bill_at,
    last_credit_at,
    last_payment_at,
    updated_at
  )
  values (
    p_customer_id,
    biz,
    billed,
    credited,
    paid,
    opening,
    opening + billed - credited - paid,
    last_bill,
    last_credit,
    last_pay,
    now()
  )
  on conflict (customer_id) do update set
    business_id = excluded.business_id,
    total_billed = excluded.total_billed,
    total_credited = excluded.total_credited,
    total_paid = excluded.total_paid,
    opening_balance = excluded.opening_balance,
    balance_due = excluded.balance_due,
    last_bill_at = excluded.last_bill_at,
    last_credit_at = excluded.last_credit_at,
    last_payment_at = excluded.last_payment_at,
    updated_at = now();
end;
$$;

revoke all on function refresh_customer_balance_projection(uuid) from public, anon, authenticated;

create or replace function trg_refresh_customer_balance_projection()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  old_id uuid;
  new_id uuid;
begin
  if tg_table_name = 'customers' then
    if tg_op = 'DELETE' then
      perform refresh_customer_balance_projection(old.id);
      return old;
    end if;
    perform refresh_customer_balance_projection(new.id);
    return new;
  end if;

  if tg_op = 'DELETE' then
    old_id := old.customer_id;
    perform refresh_customer_balance_projection(old_id);
    return old;
  elsif tg_op = 'UPDATE' then
    old_id := old.customer_id;
    new_id := new.customer_id;
    perform refresh_customer_balance_projection(new_id);
    if old_id is distinct from new_id then
      perform refresh_customer_balance_projection(old_id);
    end if;
    return new;
  else
    perform refresh_customer_balance_projection(new.customer_id);
    return new;
  end if;
end;
$$;

create trigger customers_balance_projection
  after insert or update of opening_balance, business_id
  on customers
  for each row execute function trg_refresh_customer_balance_projection();

create trigger bills_balance_projection
  after insert or update of customer_id, grand_total or delete
  on bills
  for each row execute function trg_refresh_customer_balance_projection();

create trigger payments_balance_projection
  after insert or update of customer_id, amount or delete
  on payments
  for each row execute function trg_refresh_customer_balance_projection();

create trigger credit_notes_balance_projection
  after insert or update of customer_id, grand_total or delete
  on credit_notes
  for each row execute function trg_refresh_customer_balance_projection();

insert into customer_balance_projections (
  customer_id,
  business_id,
  total_billed,
  total_credited,
  total_paid,
  opening_balance,
  balance_due,
  last_bill_at,
  last_credit_at,
  last_payment_at,
  updated_at
)
select
  customer_id,
  business_id,
  total_billed,
  total_credited,
  total_paid,
  opening_balance,
  balance_due,
  null,
  null,
  null,
  updated_at
from customer_balances
on conflict (customer_id) do update set
  business_id = excluded.business_id,
  total_billed = excluded.total_billed,
  total_credited = excluded.total_credited,
  total_paid = excluded.total_paid,
  opening_balance = excluded.opening_balance,
  balance_due = excluded.balance_due,
  updated_at = now();

create or replace view customer_balance_projection_drift
with (security_invoker = true) as
select
  v.customer_id,
  v.business_id,
  v.balance_due as view_balance_due,
  p.balance_due as projection_balance_due,
  v.balance_due - coalesce(p.balance_due, 0) as drift
from customer_balances v
left join customer_balance_projections p on p.customer_id = v.customer_id
where v.balance_due is distinct from p.balance_due;

comment on table customer_balance_projections is
  'Gated additive projection. Live app reads stay on customer_balances until drift is zero and latency gates pass. Rollback: keep reading the view.';

revoke all on customer_balance_projection_drift from public, anon, authenticated;
