-- Phase 11: credit notes (sales returns), ledger/report updates, stock return type.

alter type stock_movement_type add value if not exists 'return';

alter table stock_movements
  add column if not exists ref_credit_note_id uuid;

create table credit_note_sequences (
  business_id uuid primary key references businesses(id),
  next_no int not null default 1
);

alter table credit_note_sequences enable row level security;
alter table credit_note_sequences force row level security;
revoke all on credit_note_sequences from authenticated, anon;

create table credit_notes (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  bill_id uuid not null references bills(id),
  customer_id uuid not null references customers(id),
  credit_no text not null default '',
  items_total bigint not null default 0,
  discount bigint not null default 0,
  grand_total bigint not null default 0,
  reason text,
  restock boolean not null default true,
  created_by uuid not null references members(id),
  created_at timestamptz not null default now(),
  constraint credit_note_grand_total_non_negative check (grand_total >= 0)
);

create index credit_notes_business_idx on credit_notes(business_id);
create index credit_notes_bill_idx on credit_notes(bill_id);
create index credit_notes_customer_idx on credit_notes(customer_id);

create table credit_note_items (
  id uuid primary key default gen_random_uuid(),
  credit_note_id uuid not null references credit_notes(id) on delete cascade,
  bill_item_id uuid not null references bill_items(id),
  product_id uuid not null references products(id),
  name_snapshot text not null,
  qty_returned int not null,
  rate bigint not null default 0,
  discount bigint not null default 0,
  line_total bigint not null default 0,
  constraint credit_note_item_qty_positive check (qty_returned > 0),
  constraint credit_note_item_line_math check (line_total = qty_returned * rate - discount)
);

create index credit_note_items_note_idx on credit_note_items(credit_note_id);
create index credit_note_items_bill_item_idx on credit_note_items(bill_item_id);

create trigger credit_notes_set_business
  before insert on credit_notes
  for each row execute function set_row_business_id();

create or replace function assign_credit_note_number()
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
    raise exception 'cannot assign credit note number without business context';
  end if;
  NEW.business_id := biz;

  insert into credit_note_sequences (business_id, next_no)
  values (biz, 2)
  on conflict (business_id) do update
    set next_no = credit_note_sequences.next_no + 1
  returning credit_note_sequences.next_no - 1 into seq;

  NEW.credit_no := 'CN-' || lpad(seq::text, 4, '0');
  return NEW;
end;
$$;

create trigger credit_notes_assign_number
  before insert on credit_notes
  for each row
  execute function assign_credit_note_number();

alter table credit_notes enable row level security;
alter table credit_note_items enable row level security;
alter table credit_notes force row level security;
alter table credit_note_items force row level security;

create policy "owner sales read credit notes" on credit_notes
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  );

create policy "customer reads own credit notes" on credit_notes
  for select using (
    business_id = current_business_id()
    and current_role_name() = 'customer'
    and customer_id in (
      select id from customers
      where member_id = current_member_id()
    )
  );

create policy "owner inserts credit notes" on credit_notes
  for insert with check (
    business_id = current_business_id()
    and current_role_name() = 'owner'
    and created_by = current_member_id()
  );

create policy "sales inserts credit notes" on credit_notes
  for insert with check (
    business_id = current_business_id()
    and current_role_name() = 'sales'
    and created_by = current_member_id()
  );

create policy "owner sales read credit note items" on credit_note_items
  for select using (
    exists (
      select 1 from credit_notes cn
      where cn.id = credit_note_id
        and cn.business_id = current_business_id()
        and current_role_name() in ('owner', 'sales')
    )
  );

create policy "customer reads own credit note items" on credit_note_items
  for select using (
    exists (
      select 1 from credit_notes cn
      join customers c on c.id = cn.customer_id
      where cn.id = credit_note_id
        and cn.business_id = current_business_id()
        and current_role_name() = 'customer'
        and c.member_id = current_member_id()
    )
  );

create policy "owner inserts credit note items" on credit_note_items
  for insert with check (
    exists (
      select 1 from credit_notes cn
      where cn.id = credit_note_id
        and cn.business_id = current_business_id()
        and current_role_name() = 'owner'
        and cn.created_by = current_member_id()
    )
  );

create policy "sales inserts credit note items" on credit_note_items
  for insert with check (
    exists (
      select 1 from credit_notes cn
      where cn.id = credit_note_id
        and cn.business_id = current_business_id()
        and current_role_name() = 'sales'
        and cn.created_by = current_member_id()
    )
  );

-- Ledger views: subtract credit notes from customer balance.
drop view if exists customer_ledger_entries;
drop view if exists customer_dues_aging;
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
  coalesce(cn.total_credited, 0::bigint) as total_credited,
  coalesce(pay.total_paid, 0::bigint) as total_paid,
  c.opening_balance
    + coalesce(bill.total_billed, 0::bigint)
    - coalesce(cn.total_credited, 0::bigint)
    - coalesce(pay.total_paid, 0::bigint) as balance_due
from customers c
left join (
  select customer_id, sum(grand_total) as total_billed
  from bills
  where customer_id is not null
  group by customer_id
) bill on bill.customer_id = c.id
left join (
  select customer_id, sum(grand_total) as total_credited
  from credit_notes
  group by customer_id
) cn on cn.customer_id = c.id
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

-- Net-of-returns sales reports.
create or replace view report_sales_daily
with (security_invoker = true) as
select
  business_id,
  sale_date,
  sum(bill_count)::int as bill_count,
  coalesce(sum(total_sales), 0::bigint) as total_sales
from (
  select
    b.business_id,
    (b.created_at at time zone 'Asia/Kathmandu')::date as sale_date,
    1 as bill_count,
    b.grand_total as total_sales
  from bills b
  where current_role_name() in ('owner', 'sales')
  union all
  select
    cn.business_id,
    (cn.created_at at time zone 'Asia/Kathmandu')::date,
    0,
    -cn.grand_total
  from credit_notes cn
  where current_role_name() in ('owner', 'sales')
) s
group by business_id, sale_date;

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
security invoker
set search_path = public
as $$
  select
    product_id,
    name_snapshot,
    sum(qty)::bigint as qty_sold,
    coalesce(sum(revenue), 0::bigint) as revenue
  from (
    select
      bi.product_id,
      bi.name_snapshot,
      bi.qty::bigint as qty,
      bi.line_total::bigint as revenue
    from bill_items bi
    join bills b on b.id = bi.bill_id
    where b.business_id = current_business_id()
      and current_role_name() in ('owner', 'sales')
      and (b.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (b.created_at at time zone 'Asia/Kathmandu')::date < p_to
    union all
    select
      cni.product_id,
      cni.name_snapshot,
      -cni.qty_returned::bigint,
      -cni.line_total::bigint
    from credit_note_items cni
    join credit_notes cn on cn.id = cni.credit_note_id
    where cn.business_id = current_business_id()
      and current_role_name() in ('owner', 'sales')
      and (cn.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (cn.created_at at time zone 'Asia/Kathmandu')::date < p_to
  ) x
  group by product_id, name_snapshot
  order by revenue desc
  limit greatest(p_limit, 1);
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
security invoker
set search_path = public
as $$
  select
    customer_id,
    shop_name,
    sum(bill_count)::int as bill_count,
    coalesce(sum(revenue), 0::bigint) as revenue
  from (
    select
      b.customer_id,
      c.shop_name,
      1 as bill_count,
      b.grand_total::bigint as revenue
    from bills b
    join customers c on c.id = b.customer_id
    where b.business_id = current_business_id()
      and b.customer_id is not null
      and current_role_name() in ('owner', 'sales')
      and (b.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (b.created_at at time zone 'Asia/Kathmandu')::date < p_to
    union all
    select
      cn.customer_id,
      c.shop_name,
      0,
      -cn.grand_total::bigint
    from credit_notes cn
    join customers c on c.id = cn.customer_id
    where cn.business_id = current_business_id()
      and current_role_name() in ('owner', 'sales')
      and (cn.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (cn.created_at at time zone 'Asia/Kathmandu')::date < p_to
  ) x
  group by customer_id, shop_name
  order by revenue desc
  limit greatest(p_limit, 1);
$$;

grant execute on function report_top_products_range(date, date, int) to authenticated;
grant execute on function report_top_customers_range(date, date, int) to authenticated;

-- Transactional credit note creation.
create or replace function create_credit_note(p jsonb)
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
  v_items_total bigint := 0;
  v_discount bigint := 0;
  v_grand_total bigint := 0;
  item jsonb;
  v_bill_item_id uuid;
  v_product_id uuid;
  v_name text;
  v_qty int;
  v_rate bigint;
  v_item_discount bigint;
  v_line bigint;
  v_bill_qty int;
  v_returned int;
  bill_row bills%rowtype;
  existing jsonb;
  v_note_id uuid;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_member := current_member_id();
  v_id := coalesce((p->>'id')::uuid, gen_random_uuid());

  select to_jsonb(cn.*) into existing
  from credit_notes cn
  where cn.id = v_id and cn.business_id = current_business_id();
  if existing is not null then
    return jsonb_build_object('credit_note', existing, 'created', false);
  end if;

  v_bill_id := (p->>'bill_id')::uuid;
  v_reason := nullif(trim(p->>'reason'), '');
  v_restock := coalesce((p->>'restock')::boolean, true);

  select * into bill_row
  from bills
  where id = v_bill_id and business_id = current_business_id();
  if not found then
    raise exception 'bill not found';
  end if;
  if bill_row.customer_id is null then
    raise exception 'walk-in bills cannot be returned';
  end if;
  v_customer_id := bill_row.customer_id;

  if p->'items' is null or jsonb_array_length(p->'items') = 0 then
    raise exception 'credit note must have at least one item';
  end if;

  for item in select * from jsonb_array_elements(p->'items')
  loop
    v_bill_item_id := (item->>'bill_item_id')::uuid;
    v_qty := (item->>'qty_returned')::int;
    v_rate := coalesce((item->>'rate')::bigint, 0);
    v_item_discount := coalesce((item->>'discount')::bigint, 0);
    v_line := v_qty * v_rate - v_item_discount;
    if v_qty <= 0 then
      raise exception 'qty must be positive';
    end if;
    select bi.qty, bi.product_id, bi.name_snapshot, bi.rate, bi.discount
      into v_bill_qty, v_product_id, v_name, v_rate, v_item_discount
    from bill_items bi
    where bi.id = v_bill_item_id and bi.bill_id = v_bill_id;
    if not found then
      raise exception 'bill item not found';
    end if;
    select coalesce(sum(cni.qty_returned), 0) into v_returned
    from credit_note_items cni
    join credit_notes cn on cn.id = cni.credit_note_id
    where cni.bill_item_id = v_bill_item_id;
    if v_returned + v_qty > v_bill_qty then
      raise exception 'return qty exceeds remaining';
    end if;
    v_line := v_qty * v_rate - v_item_discount;
    v_items_total := v_items_total + v_line;
  end loop;

  v_grand_total := v_items_total - v_discount;
  if v_grand_total < 0 then
    raise exception 'grand total must be non-negative';
  end if;

  insert into credit_notes (
    id, bill_id, customer_id, items_total, discount, grand_total,
    reason, restock, created_by
  ) values (
    v_id, v_bill_id, v_customer_id, v_items_total, v_discount, v_grand_total,
    v_reason, v_restock, v_member
  ) returning id into v_note_id;

  for item in select * from jsonb_array_elements(p->'items')
  loop
    v_bill_item_id := (item->>'bill_item_id')::uuid;
    v_qty := (item->>'qty_returned')::int;
    select bi.product_id, bi.name_snapshot, bi.rate, bi.discount
      into v_product_id, v_name, v_rate, v_item_discount
    from bill_items bi
    where bi.id = v_bill_item_id;
    v_line := v_qty * v_rate - v_item_discount;
    insert into credit_note_items (
      credit_note_id, bill_item_id, product_id, name_snapshot,
      qty_returned, rate, discount, line_total
    ) values (
      v_note_id, v_bill_item_id, v_product_id, v_name,
      v_qty, v_rate, v_item_discount, v_line
    );
    if v_restock then
      insert into stock_movements (
        business_id, product_id, type, qty_delta, reason,
        ref_bill_id, ref_credit_note_id, created_by
      ) values (
        current_business_id(), v_product_id, 'return', v_qty,
        coalesce(v_reason, 'Sales return'),
        v_bill_id, v_note_id, v_member
      );
    end if;
  end loop;

  return jsonb_build_object(
    'credit_note', (select to_jsonb(cn.*) from credit_notes cn where cn.id = v_note_id),
    'created', true
  );
end;
$$;

grant execute on function create_credit_note(jsonb) to authenticated;

-- Helper: returned qty per bill item (for UI validation).
create or replace function bill_returned_qty(p_bill_id uuid)
returns table (bill_item_id uuid, returned_qty int)
language sql
stable
security invoker
set search_path = public
as $$
  select cni.bill_item_id, coalesce(sum(cni.qty_returned), 0)::int as returned_qty
  from credit_note_items cni
  join credit_notes cn on cn.id = cni.credit_note_id
  where cn.bill_id = p_bill_id
    and cn.business_id = current_business_id()
  group by cni.bill_item_id;
$$;

grant execute on function bill_returned_qty(uuid) to authenticated;
