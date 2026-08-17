-- Today's sales must be the NPT calendar day, not lifetime billed total.
-- Join on report_sales_daily.sale_date can over-count when every bill's
-- created_at lands on "today" (offline sync used to stamp now()). Query
-- bills/credit_notes with an exclusive timestamptz window instead.

create or replace function owner_dashboard_stats()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  with
  bounds as (
    select
      (timezone('Asia/Kathmandu', now())::date)::timestamp
        at time zone 'Asia/Kathmandu' as today_start,
      ((timezone('Asia/Kathmandu', now())::date + 1)::timestamp)
        at time zone 'Asia/Kathmandu' as tomorrow_start
  ),
  sales as (
    select
      coalesce((
        select sum(b.grand_total)
        from bills b
        cross join bounds bd
        where b.business_id = current_business_id()
          and b.created_at >= bd.today_start
          and b.created_at < bd.tomorrow_start
          and current_role_name() in ('owner', 'sales')
      ), 0)::bigint
      - coalesce((
        select sum(cn.grand_total)
        from credit_notes cn
        cross join bounds bd
        where cn.business_id = current_business_id()
          and cn.created_at >= bd.today_start
          and cn.created_at < bd.tomorrow_start
          and current_role_name() in ('owner', 'sales')
      ), 0)::bigint as today_sales,
      coalesce((
        select sum(b.grand_total)
        from bills b
        cross join bounds bd
        where b.business_id = current_business_id()
          and b.created_at >= bd.today_start - interval '1 day'
          and b.created_at < bd.today_start
          and current_role_name() in ('owner', 'sales')
      ), 0)::bigint
      - coalesce((
        select sum(cn.grand_total)
        from credit_notes cn
        cross join bounds bd
        where cn.business_id = current_business_id()
          and cn.created_at >= bd.today_start - interval '1 day'
          and cn.created_at < bd.today_start
          and current_role_name() in ('owner', 'sales')
      ), 0)::bigint as yesterday_sales
  ),
  dues as (
    select coalesce(sum(cb.balance_due), 0)::bigint as total_dues
    from customer_balances cb
    where cb.business_id = current_business_id()
      and cb.balance_due > 0
      and current_role_name() in ('owner', 'sales')
  ),
  low_stock as (
    select count(*)::int as low_stock_count
    from products p
    where p.business_id = current_business_id()
      and p.is_active = true
      and p.low_stock_threshold > 0
      and p.stock_cached <= p.low_stock_threshold
      and current_role_name() in ('owner', 'sales', 'warehouse')
  ),
  pending as (
    select count(*)::int as pending_orders
    from orders o
    where o.business_id = current_business_id()
      and o.status = 'placed'
      and current_role_name() in ('owner', 'sales')
  )
  select jsonb_build_object(
    'today_sales', (select today_sales from sales),
    'yesterday_sales', (select yesterday_sales from sales),
    'total_dues', (select total_dues from dues),
    'low_stock_count', (select low_stock_count from low_stock),
    'pending_orders', (select pending_orders from pending)
  );
$$;

grant execute on function owner_dashboard_stats() to authenticated;
