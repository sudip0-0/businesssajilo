-- Phase 45: Profit analytics, profit margins, and cross-entity analytics (Top products per customer, top customers per product).

-- 1. Profit Summary RPC for a date range
create or replace function report_profit_summary(
  p_from date,
  p_to date
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public
as $$
declare
  v_biz uuid;
  v_role member_role;
  v_result jsonb;
begin
  v_biz := current_business_id();
  v_role := current_role_name();

  if v_role not in ('owner', 'sales') then
    raise exception 'Permission denied: cannot view profit analytics';
  end if;

  with item_metrics as (
    select
      bi.line_total::bigint as revenue,
      (bi.qty * coalesce(p.cost_price, 0))::bigint as cogs,
      1 as bill_count
    from bill_items bi
    join bills b on b.id = bi.bill_id
    left join products p on p.id = bi.product_id
    where b.business_id = v_biz
      and (b.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (b.created_at at time zone 'Asia/Kathmandu')::date < p_to
    union all
    select
      -cni.line_total::bigint as revenue,
      -(cni.qty_returned * coalesce(p.cost_price, 0))::bigint as cogs,
      0 as bill_count
    from credit_note_items cni
    join credit_notes cn on cn.id = cni.credit_note_id
    left join products p on p.id = cni.product_id
    where cn.business_id = v_biz
      and (cn.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (cn.created_at at time zone 'Asia/Kathmandu')::date < p_to
  ),
  aggregated as (
    select
      coalesce(sum(revenue), 0)::bigint as total_revenue,
      coalesce(sum(cogs), 0)::bigint as total_cogs,
      coalesce(sum(revenue) - sum(cogs), 0)::bigint as gross_profit,
      coalesce(sum(bill_count), 0)::int as total_bills
    from item_metrics
  )
  select jsonb_build_object(
    'total_revenue', total_revenue,
    'total_cogs', total_cogs,
    'gross_profit', gross_profit,
    'margin_pct', case
      when total_revenue > 0 then round(((gross_profit::numeric / total_revenue::numeric) * 100), 2)
      else 0.0
    end,
    'total_bills', total_bills
  ) into v_result
  from aggregated;

  return v_result;
end;
$$;

grant execute on function report_profit_summary(date, date) to authenticated;

-- 2. Top Profitable Products RPC
create or replace function report_top_profitable_products(
  p_from date,
  p_to date,
  p_limit int default 10
)
returns table (
  product_id uuid,
  name_snapshot text,
  qty_sold bigint,
  revenue bigint,
  cogs bigint,
  gross_profit bigint,
  margin_pct numeric
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
    coalesce(sum(revenue), 0::bigint) as revenue,
    coalesce(sum(cogs), 0::bigint) as cogs,
    coalesce(sum(revenue) - sum(cogs), 0::bigint) as gross_profit,
    case
      when sum(revenue) > 0 then round(((sum(revenue) - sum(cogs))::numeric / sum(revenue)::numeric) * 100, 2)
      else 0.0
    end as margin_pct
  from (
    select
      bi.product_id,
      bi.name_snapshot,
      bi.qty::bigint as qty,
      bi.line_total::bigint as revenue,
      (bi.qty * coalesce(p.cost_price, 0))::bigint as cogs
    from bill_items bi
    join bills b on b.id = bi.bill_id
    left join products p on p.id = bi.product_id
    where b.business_id = current_business_id()
      and current_role_name() in ('owner', 'sales')
      and (b.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (b.created_at at time zone 'Asia/Kathmandu')::date < p_to
    union all
    select
      cni.product_id,
      cni.name_snapshot,
      -cni.qty_returned::bigint as qty,
      -cni.line_total::bigint as revenue,
      -(cni.qty_returned * coalesce(p.cost_price, 0))::bigint as cogs
    from credit_note_items cni
    join credit_notes cn on cn.id = cni.credit_note_id
    left join products p on p.id = cni.product_id
    where cn.business_id = current_business_id()
      and current_role_name() in ('owner', 'sales')
      and (cn.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (cn.created_at at time zone 'Asia/Kathmandu')::date < p_to
  ) x
  group by product_id, name_snapshot
  order by gross_profit desc
  limit greatest(p_limit, 1);
$$;

grant execute on function report_top_profitable_products(date, date, int) to authenticated;

-- 3. Top Profitable Customers RPC
create or replace function report_top_profitable_customers(
  p_from date,
  p_to date,
  p_limit int default 10
)
returns table (
  customer_id uuid,
  shop_name text,
  bill_count int,
  revenue bigint,
  cogs bigint,
  gross_profit bigint,
  margin_pct numeric
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
    coalesce(sum(revenue), 0::bigint) as revenue,
    coalesce(sum(cogs), 0::bigint) as cogs,
    coalesce(sum(revenue) - sum(cogs), 0::bigint) as gross_profit,
    case
      when sum(revenue) > 0 then round(((sum(revenue) - sum(cogs))::numeric / sum(revenue)::numeric) * 100, 2)
      else 0.0
    end as margin_pct
  from (
    select
      b.customer_id,
      c.shop_name,
      1 as bill_count,
      bi.line_total::bigint as revenue,
      (bi.qty * coalesce(p.cost_price, 0))::bigint as cogs
    from bills b
    join bill_items bi on bi.bill_id = b.id
    join customers c on c.id = b.customer_id
    left join products p on p.id = bi.product_id
    where b.business_id = current_business_id()
      and b.customer_id is not null
      and current_role_name() in ('owner', 'sales')
      and (b.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (b.created_at at time zone 'Asia/Kathmandu')::date < p_to
    union all
    select
      cn.customer_id,
      c.shop_name,
      0 as bill_count,
      -cni.line_total::bigint as revenue,
      -(cni.qty_returned * coalesce(p.cost_price, 0))::bigint as cogs
    from credit_notes cn
    join credit_note_items cni on cni.credit_note_id = cn.id
    join customers c on c.id = cn.customer_id
    left join products p on p.id = cni.product_id
    where cn.business_id = current_business_id()
      and current_role_name() in ('owner', 'sales')
      and (cn.created_at at time zone 'Asia/Kathmandu')::date >= p_from
      and (cn.created_at at time zone 'Asia/Kathmandu')::date < p_to
  ) x
  group by customer_id, shop_name
  order by gross_profit desc
  limit greatest(p_limit, 1);
$$;

grant execute on function report_top_profitable_customers(date, date, int) to authenticated;

-- 4. Cross-analytics: Top Products for a specific Customer
create or replace function report_customer_top_products(
  p_customer_id uuid,
  p_from date default null,
  p_to date default null,
  p_limit int default 10
)
returns table (
  product_id uuid,
  name_snapshot text,
  qty_sold bigint,
  revenue bigint,
  gross_profit bigint
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
    coalesce(sum(revenue), 0::bigint) as revenue,
    coalesce(sum(revenue) - sum(cogs), 0::bigint) as gross_profit
  from (
    select
      bi.product_id,
      bi.name_snapshot,
      bi.qty::bigint as qty,
      bi.line_total::bigint as revenue,
      (bi.qty * coalesce(p.cost_price, 0))::bigint as cogs
    from bill_items bi
    join bills b on b.id = bi.bill_id
    left join products p on p.id = bi.product_id
    where b.business_id = current_business_id()
      and b.customer_id = p_customer_id
      and current_role_name() in ('owner', 'sales')
      and (p_from is null or (b.created_at at time zone 'Asia/Kathmandu')::date >= p_from)
      and (p_to is null or (b.created_at at time zone 'Asia/Kathmandu')::date < p_to)
    union all
    select
      cni.product_id,
      cni.name_snapshot,
      -cni.qty_returned::bigint as qty,
      -cni.line_total::bigint as revenue,
      -(cni.qty_returned * coalesce(p.cost_price, 0))::bigint as cogs
    from credit_note_items cni
    join credit_notes cn on cn.id = cni.credit_note_id
    left join products p on p.id = cni.product_id
    where cn.business_id = current_business_id()
      and cn.customer_id = p_customer_id
      and current_role_name() in ('owner', 'sales')
      and (p_from is null or (cn.created_at at time zone 'Asia/Kathmandu')::date >= p_from)
      and (p_to is null or (cn.created_at at time zone 'Asia/Kathmandu')::date < p_to)
  ) x
  group by product_id, name_snapshot
  order by revenue desc
  limit greatest(p_limit, 1);
$$;

grant execute on function report_customer_top_products(uuid, date, date, int) to authenticated;

-- 5. Cross-analytics: Top Customers for a specific Product
create or replace function report_product_top_customers(
  p_product_id uuid,
  p_from date default null,
  p_to date default null,
  p_limit int default 10
)
returns table (
  customer_id uuid,
  shop_name text,
  qty_sold bigint,
  revenue bigint,
  gross_profit bigint
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    customer_id,
    shop_name,
    sum(qty)::bigint as qty_sold,
    coalesce(sum(revenue), 0::bigint) as revenue,
    coalesce(sum(revenue) - sum(cogs), 0::bigint) as gross_profit
  from (
    select
      b.customer_id,
      c.shop_name,
      bi.qty::bigint as qty,
      bi.line_total::bigint as revenue,
      (bi.qty * coalesce(p.cost_price, 0))::bigint as cogs
    from bills b
    join bill_items bi on bi.bill_id = b.id
    join customers c on c.id = b.customer_id
    left join products p on p.id = bi.product_id
    where b.business_id = current_business_id()
      and bi.product_id = p_product_id
      and b.customer_id is not null
      and current_role_name() in ('owner', 'sales')
      and (p_from is null or (b.created_at at time zone 'Asia/Kathmandu')::date >= p_from)
      and (p_to is null or (b.created_at at time zone 'Asia/Kathmandu')::date < p_to)
    union all
    select
      cn.customer_id,
      c.shop_name,
      -cni.qty_returned::bigint as qty,
      -cni.line_total::bigint as revenue,
      -(cni.qty_returned * coalesce(p.cost_price, 0))::bigint as cogs
    from credit_notes cn
    join credit_note_items cni on cni.credit_note_id = cn.id
    join customers c on c.id = cn.customer_id
    left join products p on p.id = cni.product_id
    where cn.business_id = current_business_id()
      and cni.product_id = p_product_id
      and current_role_name() in ('owner', 'sales')
      and (p_from is null or (cn.created_at at time zone 'Asia/Kathmandu')::date >= p_from)
      and (p_to is null or (cn.created_at at time zone 'Asia/Kathmandu')::date < p_to)
  ) x
  group by customer_id, shop_name
  order by revenue desc
  limit greatest(p_limit, 1);
$$;

grant execute on function report_product_top_customers(uuid, date, date, int) to authenticated;
