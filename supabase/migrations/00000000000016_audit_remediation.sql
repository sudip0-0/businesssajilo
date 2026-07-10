-- Audit remediation (2026-07-10):
-- 1. Restore customer_balances.updated_at for offline delta sync (incl. financial activity).
-- 2. Revoke direct INSERT on bills / bill_items / payments — RPC-only writes.
-- 3. Add record_payment SECURITY DEFINER RPC with validation.

-- ---------------------------------------------------------------------------
-- 1. customer_balances.updated_at (broken since migration 11 dropped it)
-- ---------------------------------------------------------------------------

drop view if exists customer_dues_aging;
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
) entries;

grant select on customer_balances to authenticated;
grant select on customer_ledger_entries to authenticated;
alter view customer_balances set (security_invoker = true);
alter view customer_ledger_entries set (security_invoker = true);

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

grant select on customer_dues_aging to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Bills / bill_items: RPC-only creation (create_bill is SECURITY DEFINER)
-- ---------------------------------------------------------------------------

drop policy if exists "owner inserts bills" on bills;
drop policy if exists "sales inserts bills" on bills;
drop policy if exists "owner inserts bill items" on bill_items;
drop policy if exists "sales inserts bill items" on bill_items;

-- ---------------------------------------------------------------------------
-- 3. record_payment RPC + revoke direct payment INSERT
-- ---------------------------------------------------------------------------

create or replace function record_payment(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_customer_id uuid;
  v_bill_id uuid;
  v_amount bigint;
  v_method payment_method;
  v_ref_note text;
  v_member uuid;
  existing jsonb;
  result jsonb;
  bill_row bills%rowtype;
  paid_sum bigint;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_member := current_member_id();
  v_id := coalesce((p->>'id')::uuid, gen_random_uuid());

  select to_jsonb(pay.*) into existing
  from payments pay
  where pay.id = v_id and pay.business_id = current_business_id();
  if existing is not null then
    return jsonb_build_object('payment', existing, 'created', false);
  end if;

  v_customer_id := (p->>'customer_id')::uuid;
  v_bill_id := (p->>'bill_id')::uuid;
  v_amount := (p->>'amount')::bigint;
  v_method := (p->>'method')::payment_method;
  v_ref_note := p->>'ref_note';

  if v_customer_id is null then
    raise exception 'customer_id required';
  end if;
  if v_amount is null or v_amount <= 0 then
    raise exception 'amount must be positive';
  end if;
  if v_amount > 100000000000 then -- 1e9 NPR in paisa
    raise exception 'amount out of range';
  end if;

  if not exists (
    select 1 from customers
    where id = v_customer_id and business_id = current_business_id()
  ) then
    raise exception 'customer not found';
  end if;

  if v_bill_id is not null then
    select * into bill_row from bills
    where id = v_bill_id and business_id = current_business_id();
    if not found then
      raise exception 'bill not found';
    end if;
    if bill_row.customer_id is distinct from v_customer_id then
      raise exception 'bill customer mismatch';
    end if;
  end if;

  insert into payments (
    id, business_id, customer_id, bill_id, amount, method, ref_note, received_by
  ) values (
    v_id,
    current_business_id(),
    v_customer_id,
    v_bill_id,
    v_amount,
    v_method,
    nullif(trim(coalesce(v_ref_note, '')), ''),
    coalesce((p->>'received_by')::uuid, v_member)
  );

  -- Refresh linked bill status from payments when bill_id is set.
  if v_bill_id is not null then
    select coalesce(sum(amount), 0) into paid_sum
    from payments where bill_id = v_bill_id;
    update bills set
      status = case
        when paid_sum >= grand_total then 'paid'::bill_status
        when paid_sum > 0 then 'partial'::bill_status
        else 'due'::bill_status
      end,
      updated_at = now()
    where id = v_bill_id;
  end if;

  select to_jsonb(pay.*) into result
  from payments pay where pay.id = v_id;
  return jsonb_build_object('payment', result, 'created', true);
end;
$$;

grant execute on function record_payment(jsonb) to authenticated;

drop policy if exists "owner inserts payments" on payments;
drop policy if exists "sales inserts payments" on payments;
