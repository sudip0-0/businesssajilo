-- Hide financial balance/ledger views from warehouse (they may read customers/bills
-- for billing, but must not see balances).

drop view if exists customer_dues_aging;
drop view if exists customer_ledger_entries;
drop view if exists customer_balances;

create view customer_balances
with (security_invoker = true) as
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
  greatest(
    c.updated_at,
    coalesce(bill.last_at, '-infinity'::timestamptz),
    coalesce(cn.last_at, '-infinity'::timestamptz),
    coalesce(pay.last_at, '-infinity'::timestamptz)
  ) as updated_at,
  coalesce(bill.total_billed, 0::bigint) as total_billed,
  coalesce(cn.total_credited, 0::bigint) as total_credited,
  coalesce(pay.total_paid, 0::bigint) as total_paid,
  c.opening_balance
    + coalesce(bill.total_billed, 0::bigint)
    - coalesce(cn.total_credited, 0::bigint)
    - coalesce(pay.total_paid, 0::bigint) as balance_due
from customers c
left join (
  select
    customer_id,
    sum(grand_total) as total_billed,
    max(created_at) as last_at
  from bills
  where customer_id is not null
  group by customer_id
) bill on bill.customer_id = c.id
left join (
  select
    customer_id,
    sum(grand_total) as total_credited,
    max(created_at) as last_at
  from credit_notes
  group by customer_id
) cn on cn.customer_id = c.id
left join (
  select
    customer_id,
    sum(amount) as total_paid,
    max(created_at) as last_at
  from payments
  group by customer_id
) pay on pay.customer_id = c.id
where current_role_name() in ('owner', 'sales')
   or (
     current_role_name() = 'customer'
     and c.member_id = current_member_id()
   );

create view customer_ledger_entries
with (security_invoker = true) as
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
    cn.customer_id,
    cn.business_id,
    cn.created_at,
    'credit_note'::text,
    cn.credit_no,
    0::bigint,
    cn.grand_total,
    cn.id
  from credit_notes cn
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
) entries
where current_role_name() in ('owner', 'sales')
   or (
     current_role_name() = 'customer'
     and customer_id in (
       select id from customers where member_id = current_member_id()
     )
   );

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

grant select on customer_balances to authenticated;
grant select on customer_ledger_entries to authenticated;
grant select on customer_dues_aging to authenticated;
