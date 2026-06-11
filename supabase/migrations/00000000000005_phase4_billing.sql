-- Phase 4: bills, bill_items, bill numbering, ledger view updates.

create table bill_sequences (
  business_id uuid primary key references businesses(id),
  next_no int not null default 1
);

create table bills (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  customer_id uuid references customers(id),
  order_id uuid,
  bill_no text not null default '',
  device_prefix text,
  items_total bigint not null default 0,
  discount bigint not null default 0,
  grand_total bigint not null default 0,
  status bill_status not null,
  created_by uuid not null references members(id),
  created_at timestamptz not null default now(),
  constraint bill_grand_total_non_negative check (grand_total >= 0)
);

create index bills_business_idx on bills(business_id);
create index bills_customer_idx on bills(customer_id);
create index bills_created_at_idx on bills(created_at);

create table bill_items (
  id uuid primary key default gen_random_uuid(),
  bill_id uuid not null references bills(id) on delete cascade,
  product_id uuid not null references products(id),
  name_snapshot text not null,
  qty int not null,
  rate bigint not null default 0,
  discount bigint not null default 0,
  line_total bigint not null default 0,
  constraint bill_item_qty_positive check (qty > 0)
);

create index bill_items_bill_idx on bill_items(bill_id);

create trigger bills_set_business
  before insert on bills
  for each row execute function set_row_business_id();

-- Assign per-business sequential bill numbers (BS-0001).
create or replace function assign_bill_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  seq int;
begin
  insert into bill_sequences (business_id, next_no)
  values (NEW.business_id, 2)
  on conflict (business_id) do update
    set next_no = bill_sequences.next_no + 1
  returning bill_sequences.next_no - 1 into seq;

  NEW.bill_no := 'BS-' || lpad(seq::text, 4, '0');
  return NEW;
end;
$$;

create trigger bills_assign_number
  before insert on bills
  for each row
  execute function assign_bill_number();

-- FK from payments to bills.
alter table payments
  add constraint payments_bill_id_fkey
  foreign key (bill_id) references bills(id);

-- Replace ledger views to include bill debits.
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

-- RLS: bills (warehouse blocked — no policies for warehouse)
alter table bills enable row level security;

create policy "owner sales read bills" on bills
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  );

create policy "customer reads own bills" on bills
  for select using (
    customer_id in (
      select id from customers
      where member_id = (
        select id from members
        where auth_user_id = auth.uid() and is_active
      )
    )
  );

create policy "owner inserts bills" on bills
  for insert with check (
    business_id = current_business_id()
    and current_role_name() = 'owner'
    and created_by = current_member_id()
  );

create policy "sales inserts bills" on bills
  for insert with check (
    business_id = current_business_id()
    and current_role_name() = 'sales'
    and created_by = current_member_id()
  );

-- RLS: bill_items
alter table bill_items enable row level security;

create policy "owner sales read bill items" on bill_items
  for select using (
    bill_id in (
      select id from bills
      where business_id = current_business_id()
        and current_role_name() in ('owner', 'sales')
    )
  );

create policy "customer reads own bill items" on bill_items
  for select using (
    bill_id in (
      select b.id from bills b
      join customers c on c.id = b.customer_id
      where c.member_id = (
        select id from members
        where auth_user_id = auth.uid() and is_active
      )
    )
  );

create policy "owner inserts bill items" on bill_items
  for insert with check (
    bill_id in (
      select id from bills
      where business_id = current_business_id()
        and current_role_name() = 'owner'
        and created_by = current_member_id()
    )
  );

create policy "sales inserts bill items" on bill_items
  for insert with check (
    bill_id in (
      select id from bills
      where business_id = current_business_id()
        and current_role_name() = 'sales'
        and created_by = current_member_id()
    )
  );

alter table bills force row level security;
alter table bill_items force row level security;
