-- Phase 25: remove categories (feature retired).
-- Drops the categories table, the products.category_id column, and strips
-- category columns from views / RPCs. Any existing category assignments are
-- discarded (back up before running).
--
-- Ordering matters: views/RPCs that reference category_id or categories must
-- be recreated before the column/table are dropped.

-- 1. Catalog view + RPC: drop category_id (view depends on the column).
create or replace view catalog_products
with (security_invoker = false)
as
select
  id,
  business_id,
  name,
  name_np,
  sku,
  unit,
  image_url,
  stock_cached,
  is_active
from products
where is_active = true;

-- CREATE OR REPLACE cannot change a function's OUT-parameter row type, so
-- drop the old RPC (which still returned category_id) first.
drop function if exists list_catalog_products();

create or replace function list_catalog_products()
returns table (
  id uuid,
  business_id uuid,
  name text,
  name_np text,
  sku text,
  unit text,
  image_url text,
  stock_cached int,
  is_active boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.business_id,
    p.name,
    p.name_np,
    p.sku,
    p.unit,
    p.image_url,
    p.stock_cached,
    p.is_active
  from products p
  where p.is_active = true
    and p.business_id = current_business_id()
    and current_role_name() = 'customer';
$$;

grant execute on function list_catalog_products() to authenticated;

-- 2. list_low_stock no longer joins categories.
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
          p.created_at
        from products p
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

-- 3. Drop the column (removes the FK + products_category_idx) and the table.
alter table products drop column if exists category_id;
drop index if exists products_category_idx;
drop table if exists categories;
