-- Reports UI upgrade: dues aging includes phone.
-- Stock valuation view is reaffirmed without category columns.

create or replace view report_stock_valuation
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

grant select on report_stock_valuation to authenticated;

create or replace function report_dues_aging()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  with rows as (
    select
      a.customer_id,
      a.shop_name,
      a.balance_due,
      a.oldest_due_at,
      a.age_days,
      a.bucket,
      cust.phone
    from customer_dues_aging a
    join customers cust on cust.id = a.customer_id
    where a.business_id = current_business_id()
      and current_role_name() in ('owner', 'sales')
  ),
  buckets as (
    select
      coalesce(sum(case when bucket = '0_30' then balance_due else 0 end), 0)::bigint
        as bucket_0_30,
      coalesce(sum(case when bucket = '31_60' then balance_due else 0 end), 0)::bigint
        as bucket_31_60,
      coalesce(sum(case when bucket = '60_plus' then balance_due else 0 end), 0)::bigint
        as bucket_60_plus
    from rows
  )
  select jsonb_build_object(
    'bucket_0_30', (select bucket_0_30 from buckets),
    'bucket_31_60', (select bucket_31_60 from buckets),
    'bucket_60_plus', (select bucket_60_plus from buckets),
    'customers', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'customer_id', customer_id,
            'shop_name', shop_name,
            'balance_due', balance_due,
            'oldest_due_at', oldest_due_at,
            'age_days', age_days,
            'bucket', bucket,
            'phone', phone
          )
          order by balance_due desc
        )
        from rows
      ),
      '[]'::jsonb
    )
  );
$$;

grant execute on function report_dues_aging() to authenticated;
