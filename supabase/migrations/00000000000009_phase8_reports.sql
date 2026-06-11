-- Phase 8: owner report views (tenant-scoped via underlying table RLS + security_invoker).

create view report_sales_daily
with (security_invoker = true) as
select
  b.business_id,
  (b.created_at at time zone 'UTC')::date as sale_date,
  count(*)::int as bill_count,
  coalesce(sum(b.grand_total), 0::bigint) as total_sales
from bills b
where current_role_name() in ('owner', 'sales')
group by b.business_id, (b.created_at at time zone 'UTC')::date;

create view report_top_products
with (security_invoker = true) as
select
  b.business_id,
  bi.product_id,
  bi.name_snapshot,
  (b.created_at at time zone 'UTC')::date as sale_date,
  sum(bi.qty)::bigint as qty_sold,
  coalesce(sum(bi.line_total), 0::bigint) as revenue
from bill_items bi
join bills b on b.id = bi.bill_id
where current_role_name() in ('owner', 'sales')
group by b.business_id, bi.product_id, bi.name_snapshot, (b.created_at at time zone 'UTC')::date;

create view report_top_customers
with (security_invoker = true) as
select
  b.business_id,
  b.customer_id,
  c.shop_name,
  (b.created_at at time zone 'UTC')::date as sale_date,
  count(*)::int as bill_count,
  coalesce(sum(b.grand_total), 0::bigint) as revenue
from bills b
join customers c on c.id = b.customer_id
where b.customer_id is not null
  and current_role_name() in ('owner', 'sales')
group by b.business_id, b.customer_id, c.shop_name, (b.created_at at time zone 'UTC')::date;

create view customer_dues_aging
with (security_invoker = true) as
select
  cb.business_id,
  cb.customer_id,
  cb.shop_name,
  cb.balance_due,
  coalesce(oldest.oldest_due_at, c.created_at) as oldest_due_at,
  greatest(
    0,
    (current_date - coalesce(oldest.oldest_due_at, c.created_at)::date)
  )::int as age_days,
  case
    when greatest(
      0,
      (current_date - coalesce(oldest.oldest_due_at, c.created_at)::date)
    ) <= 30 then '0_30'
    when greatest(
      0,
      (current_date - coalesce(oldest.oldest_due_at, c.created_at)::date)
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

create view report_stock_valuation
with (security_invoker = true) as
select
  p.business_id,
  p.id as product_id,
  p.name,
  p.stock_cached,
  p.cost_price,
  (p.stock_cached * p.cost_price)::bigint as valuation,
  (p.low_stock_threshold > 0 and p.stock_cached <= p.low_stock_threshold) as is_low_stock
from products p
where p.is_active = true;

grant select on report_sales_daily to authenticated;
grant select on report_top_products to authenticated;
grant select on report_top_customers to authenticated;
grant select on customer_dues_aging to authenticated;
grant select on report_stock_valuation to authenticated;
