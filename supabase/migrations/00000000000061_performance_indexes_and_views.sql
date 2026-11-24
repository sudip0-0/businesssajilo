-- Migration 61: Backend performance optimizations — composite/partial indexes
-- on hot query paths + InitPlan wrapping on views, RLS policies, and dashboard RPCs.

-- ---------------------------------------------------------------------------
-- 1. Composite & partial indexes on hot query paths.
-- ---------------------------------------------------------------------------

-- Bills: status-filtered search & customer ledger/history.
create index if not exists bills_business_status_created_idx
  on public.bills (business_id, status, created_at desc);

create index if not exists bills_business_customer_created_idx
  on public.bills (business_id, customer_id, created_at desc)
  where customer_id is not null;

-- Orders: tenant list, status-filtered list, customer "My Orders".
create index if not exists orders_business_created_idx
  on public.orders (business_id, created_at desc);

create index if not exists orders_business_status_created_idx
  on public.orders (business_id, status, created_at desc);

create index if not exists orders_business_customer_created_idx
  on public.orders (business_id, customer_id, created_at desc);

-- Payments: customer ledger & payment history.
create index if not exists payments_business_customer_created_idx
  on public.payments (business_id, customer_id, created_at desc);

-- Credit notes: dashboard daily range & customer ledger/balance aggregation.
create index if not exists credit_notes_business_created_idx
  on public.credit_notes (business_id, created_at desc);

create index if not exists credit_notes_business_customer_created_idx
  on public.credit_notes (business_id, customer_id, created_at desc);

-- Stock movements: tenant-scoped product history & credit-note return lookup.
create index if not exists stock_movements_business_product_created_idx
  on public.stock_movements (business_id, product_id, created_at desc);

create index if not exists stock_movements_ref_credit_note_idx
  on public.stock_movements (ref_credit_note_id)
  where ref_credit_note_id is not null;

-- Notifications: operational nudge dedup, RLS-aligned recipient feed, unpushed queue.
create index if not exists notifications_business_type_created_idx
  on public.notifications (business_id, type, created_at desc);

create index if not exists notifications_business_recipient_created_idx
  on public.notifications (business_id, recipient_member_id, created_at desc);

create index if not exists notifications_unpushed_idx
  on public.notifications (created_at)
  where pushed_at is null;

-- Audit log: tenant-scoped entity timeline.
create index if not exists audit_log_business_record_idx
  on public.audit_log (business_id, table_name, record_id, changed_at desc);

-- Customer balance projections: due-customers list & total dues aggregation.
create index if not exists customer_balance_projections_business_due_idx
  on public.customer_balance_projections (business_id, balance_due desc)
  where balance_due > 0;

-- Products: active sorted listing & partial low-stock scan.
create index if not exists products_business_active_name_idx
  on public.products (business_id, is_active, name);

create index if not exists products_business_low_stock_idx
  on public.products (business_id, name)
  where is_active = true and low_stock_threshold > 0;

-- Quotes: tenant status/recency lookups (last_quoted_rate, active quotes).
create index if not exists quotes_business_status_created_idx
  on public.quotes (business_id, status, created_at desc);

-- ---------------------------------------------------------------------------
-- 2. Wrap auth helper calls in (SELECT ...) InitPlans across views and push
--    business_id into customer_balances subqueries so Postgres evaluates
--    current_role_name()/current_member_id() once per query instead of per row.
-- ---------------------------------------------------------------------------
create or replace view public.customer_balances
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
  coalesce(bill.total_billed, 0::bigint::numeric) as total_billed,
  coalesce(cn.total_credited, 0::bigint::numeric) as total_credited,
  coalesce(pay.total_paid, 0::bigint::numeric) as total_paid,
  (
    c.opening_balance::numeric
    + coalesce(bill.total_billed, 0::bigint::numeric)
    - coalesce(cn.total_credited, 0::bigint::numeric)
    - coalesce(pay.total_paid, 0::bigint::numeric)
  ) as balance_due
from public.customers c
left join (
  select business_id, customer_id, sum(grand_total) as total_billed, max(created_at) as last_at
  from public.bills
  where customer_id is not null
  group by business_id, customer_id
) bill on bill.business_id = c.business_id and bill.customer_id = c.id
left join (
  select business_id, customer_id, sum(grand_total) as total_credited, max(created_at) as last_at
  from public.credit_notes
  group by business_id, customer_id
) cn on cn.business_id = c.business_id and cn.customer_id = c.id
left join (
  select business_id, customer_id, sum(amount) as total_paid, max(created_at) as last_at
  from public.payments
  group by business_id, customer_id
) pay on pay.business_id = c.business_id and pay.customer_id = c.id
where (select public.current_role_name()) in ('owner', 'sales')
   or (
     (select public.current_role_name()) = 'customer'
     and c.member_id = (select public.current_member_id())
   );

create or replace view public.customer_dues_aging
with (security_invoker = true) as
select
  cb.business_id,
  cb.customer_id,
  cb.shop_name,
  cb.balance_due,
  coalesce(oldest.oldest_due_at, c.created_at) as oldest_due_at,
  greatest(
    0,
    (now() at time zone 'Asia/Kathmandu')::date
      - (coalesce(oldest.oldest_due_at, c.created_at) at time zone 'Asia/Kathmandu')::date
  ) as age_days,
  case
    when greatest(
      0,
      (now() at time zone 'Asia/Kathmandu')::date
        - (coalesce(oldest.oldest_due_at, c.created_at) at time zone 'Asia/Kathmandu')::date
    ) <= 30 then '0_30'
    when greatest(
      0,
      (now() at time zone 'Asia/Kathmandu')::date
        - (coalesce(oldest.oldest_due_at, c.created_at) at time zone 'Asia/Kathmandu')::date
    ) <= 60 then '31_60'
    else '60_plus'
  end as bucket
from public.customer_balances cb
join public.customers c on c.id = cb.customer_id
left join (
  select business_id, customer_id, min(created_at) as oldest_due_at
  from public.bills
  where customer_id is not null
    and status in ('due', 'partial')
  group by business_id, customer_id
) oldest on oldest.business_id = cb.business_id and oldest.customer_id = cb.customer_id
where cb.balance_due > 0::numeric
  and (select public.current_role_name()) in ('owner', 'sales');

create or replace view public.customer_ledger_entries
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
  from public.customers c
  where c.opening_balance <> 0
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
  from public.bills b
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
  from public.credit_notes cn
  union all
  select
    p.customer_id,
    p.business_id,
    p.created_at,
    'payment'::text,
    coalesce(nullif(btrim(p.ref_note), ''), initcap(p.method::text)),
    0::bigint,
    p.amount,
    p.id
  from public.payments p
) entries
where (select public.current_role_name()) in ('owner', 'sales')
   or (
     (select public.current_role_name()) = 'customer'
     and customer_id = (select public.own_customer_id())
   );

create or replace view public.report_sales_daily
with (security_invoker = true) as
select
  business_id,
  sale_date,
  sum(bill_count)::integer as bill_count,
  coalesce(sum(total_sales), 0::bigint::numeric) as total_sales
from (
  select
    b.business_id,
    (b.created_at at time zone 'Asia/Kathmandu')::date as sale_date,
    1 as bill_count,
    b.grand_total as total_sales
  from public.bills b
  where (select public.current_role_name()) in ('owner', 'sales')
  union all
  select
    cn.business_id,
    (cn.created_at at time zone 'Asia/Kathmandu')::date,
    0,
    -cn.grand_total
  from public.credit_notes cn
  where (select public.current_role_name()) in ('owner', 'sales')
) s
group by business_id, sale_date;

create or replace view public.report_top_customers
with (security_invoker = true) as
select
  b.business_id,
  b.customer_id,
  c.shop_name,
  (b.created_at at time zone 'Asia/Kathmandu')::date as sale_date,
  count(*)::integer as bill_count,
  coalesce(sum(b.grand_total), 0::bigint::numeric) as revenue
from public.bills b
join public.customers c on c.id = b.customer_id
where b.customer_id is not null
  and (select public.current_role_name()) in ('owner', 'sales')
group by b.business_id, b.customer_id, c.shop_name, (b.created_at at time zone 'Asia/Kathmandu')::date;

create or replace view public.report_top_products
with (security_invoker = true) as
select
  b.business_id,
  bi.product_id,
  bi.name_snapshot,
  (b.created_at at time zone 'Asia/Kathmandu')::date as sale_date,
  sum(bi.qty) as qty_sold,
  coalesce(sum(bi.line_total), 0::bigint::numeric) as revenue
from public.bill_items bi
join public.bills b on b.id = bi.bill_id
where (select public.current_role_name()) in ('owner', 'sales')
group by b.business_id, bi.product_id, bi.name_snapshot, (b.created_at at time zone 'Asia/Kathmandu')::date;

-- ---------------------------------------------------------------------------
-- 3. Wrap own_customer_id() in (SELECT ...) InitPlans in customer RLS policies.
-- ---------------------------------------------------------------------------
drop policy if exists "customer reads own orders" on public.orders;
create policy "customer reads own orders" on public.orders
  for select
  using (
    business_id = (select public.current_business_id())
    and (select public.current_role_name()) = 'customer'
    and customer_id = (select public.own_customer_id())
  );

drop policy if exists "customer reads own order items" on public.order_items;
create policy "customer reads own order items" on public.order_items
  for select
  using (
    order_id in (
      select orders.id
      from public.orders
      where orders.customer_id = (select public.own_customer_id())
    )
  );

drop policy if exists "customer reads own quotes" on public.quotes;
create policy "customer reads own quotes" on public.quotes
  for select
  using (
    order_id in (
      select orders.id
      from public.orders
      where orders.customer_id = (select public.own_customer_id())
    )
  );

drop policy if exists "customer responds to sent quotes" on public.quotes;
create policy "customer responds to sent quotes" on public.quotes
  for update
  using (
    order_id in (
      select orders.id
      from public.orders
      where orders.customer_id = (select public.own_customer_id())
    )
    and status = 'sent'
  )
  with check (
    order_id in (
      select orders.id
      from public.orders
      where orders.customer_id = (select public.own_customer_id())
    )
    and status in ('accepted', 'rejected')
  );

drop policy if exists "customer reads own quote items" on public.quote_items;
create policy "customer reads own quote items" on public.quote_items
  for select
  using (
    quote_id in (
      select q.id
      from public.quotes q
      join public.orders o on o.id = q.order_id
      where o.customer_id = (select public.own_customer_id())
    )
  );

-- ---------------------------------------------------------------------------
-- 4. Optimize owner_dashboard_stats(), total_dues(), and low_stock_count()
--    with InitPlan caching and index-friendly projection/range reads.
-- ---------------------------------------------------------------------------
create or replace function public.total_dues()
returns bigint
language sql
stable
set search_path = public
as $$
  select coalesce(sum(cbp.balance_due), 0)::bigint
  from public.customer_balance_projections cbp
  where cbp.business_id = (select public.current_business_id())
    and cbp.balance_due > 0
    and (select public.current_role_name()) in ('owner', 'sales');
$$;

create or replace function public.low_stock_count()
returns integer
language sql
stable
set search_path = public
as $$
  select count(*)::int
  from public.products p
  where p.business_id = (select public.current_business_id())
    and p.is_active = true
    and p.low_stock_threshold > 0
    and p.stock_cached <= p.low_stock_threshold
    and (select public.current_role_name()) in ('owner', 'sales', 'warehouse');
$$;

create or replace function public.owner_dashboard_stats()
returns jsonb
language sql
stable
set search_path = public
as $$
  with
  ctx as (
    select
      (select public.current_business_id()) as biz_id,
      (select public.current_role_name()) as role_name,
      (timezone('Asia/Kathmandu', now())::date)::timestamp
        at time zone 'Asia/Kathmandu' as today_start,
      ((timezone('Asia/Kathmandu', now())::date + 1)::timestamp)
        at time zone 'Asia/Kathmandu' as tomorrow_start
  ),
  sales as (
    select
      coalesce((
        select sum(b.grand_total)
        from public.bills b
        cross join ctx
        where b.business_id = ctx.biz_id
          and b.created_at >= ctx.today_start
          and b.created_at < ctx.tomorrow_start
          and ctx.role_name in ('owner', 'sales')
      ), 0)::bigint
      - coalesce((
        select sum(cn.grand_total)
        from public.credit_notes cn
        cross join ctx
        where cn.business_id = ctx.biz_id
          and cn.created_at >= ctx.today_start
          and cn.created_at < ctx.tomorrow_start
          and ctx.role_name in ('owner', 'sales')
      ), 0)::bigint as today_sales,
      coalesce((
        select sum(b.grand_total)
        from public.bills b
        cross join ctx
        where b.business_id = ctx.biz_id
          and b.created_at >= ctx.today_start - interval '1 day'
          and b.created_at < ctx.today_start
          and ctx.role_name in ('owner', 'sales')
      ), 0)::bigint
      - coalesce((
        select sum(cn.grand_total)
        from public.credit_notes cn
        cross join ctx
        where cn.business_id = ctx.biz_id
          and cn.created_at >= ctx.today_start - interval '1 day'
          and cn.created_at < ctx.today_start
          and ctx.role_name in ('owner', 'sales')
      ), 0)::bigint as yesterday_sales
  ),
  dues as (
    select coalesce(sum(cbp.balance_due), 0)::bigint as total_dues
    from public.customer_balance_projections cbp
    cross join ctx
    where cbp.business_id = ctx.biz_id
      and cbp.balance_due > 0
      and ctx.role_name in ('owner', 'sales')
  ),
  low_stock as (
    select count(*)::int as low_stock_count
    from public.products p
    cross join ctx
    where p.business_id = ctx.biz_id
      and p.is_active = true
      and p.low_stock_threshold > 0
      and p.stock_cached <= p.low_stock_threshold
      and ctx.role_name in ('owner', 'sales', 'warehouse')
  ),
  pending as (
    select count(*)::int as pending_orders
    from public.orders o
    cross join ctx
    where o.business_id = ctx.biz_id
      and o.status = 'placed'
      and ctx.role_name in ('owner', 'sales')
  )
  select jsonb_build_object(
    'today_sales', (select today_sales from sales),
    'yesterday_sales', (select yesterday_sales from sales),
    'total_dues', (select total_dues from dues),
    'low_stock_count', (select low_stock_count from low_stock),
    'pending_orders', (select pending_orders from pending)
  );
$$;
