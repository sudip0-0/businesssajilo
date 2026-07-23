-- Phase 21: server-side aggregations for low stock + total dues,
-- and an index to speed purge_business notification deletes.

create or replace function low_stock_count()
returns int
language sql
stable
security invoker
set search_path = public
as $$
  select count(*)::int
  from products p
  where p.business_id = current_business_id()
    and p.is_active = true
    and p.low_stock_threshold > 0
    and p.stock_cached <= p.low_stock_threshold
    and current_role_name() in ('owner', 'sales', 'warehouse');
$$;

grant execute on function low_stock_count() to authenticated;

create or replace function list_low_stock(p_limit int default 50)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_agg(to_jsonb(row) order by row.name)
      from (
        select
          p.id,
          p.business_id,
          p.category_id,
          p.name,
          p.name_np,
          p.sku,
          p.unit,
          p.cost_price,
          p.reference_price,
          p.image_url,
          p.low_stock_threshold,
          p.stock_cached,
          p.is_active,
          p.updated_at,
          p.created_at,
          c.name as category_name
        from products p
        left join categories c on c.id = p.category_id
        where p.business_id = current_business_id()
          and p.is_active = true
          and p.low_stock_threshold > 0
          and p.stock_cached <= p.low_stock_threshold
          and current_role_name() in ('owner', 'sales', 'warehouse')
        order by p.name
        limit greatest(coalesce(p_limit, 50), 0)
      ) row
    ),
    '[]'::jsonb
  );
$$;

grant execute on function list_low_stock(int) to authenticated;

create or replace function total_dues()
returns bigint
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce(sum(cb.balance_due), 0)::bigint
  from customer_balances cb
  where cb.business_id = current_business_id()
    and cb.balance_due > 0
    and current_role_name() in ('owner', 'sales');
$$;

grant execute on function total_dues() to authenticated;

create index if not exists notifications_business_idx
  on notifications (business_id);
