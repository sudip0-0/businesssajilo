-- Server-side dues aging aggregation (avoids unbounded client select).

create or replace function report_dues_aging()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  with rows as (
    select
      customer_id,
      shop_name,
      balance_due,
      oldest_due_at,
      age_days,
      bucket
    from customer_dues_aging
    where business_id = current_business_id()
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
            'bucket', bucket
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
