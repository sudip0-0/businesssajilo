-- Phase 24: inventory performance.
-- - Recalc stock_cached incrementally instead of rescanning the whole
--   movement ledger on every insert.
-- - Composite index for per-product movement history queries.

-- ---------------------------------------------------------------------------
-- 1. Incremental stock recalculation.
-- ---------------------------------------------------------------------------
-- The previous implementation recomputed `sum(qty_delta)` across every
-- stock_movements row for the product on each insert, which degrades as the
-- ledger grows (it fires on bill lines, dispatches, returns, stock-in and
-- adjustments). We now apply the inserted delta to the cached running total
-- under a product-row lock so concurrent movements serialize correctly.
-- This matches the offline path (`_projectedStock`), which is already
-- incremental.

create or replace function recalc_product_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_stock int;
  product_row products%rowtype;
  member_row record;
begin
  -- Lock the product row so concurrent movements serialize and the running
  -- total stays exact.
  select * into product_row
  from products
  where id = NEW.product_id
  for update;

  if product_row.id is null then
    return NEW;
  end if;

  new_stock := product_row.stock_cached + NEW.qty_delta;

  update products
  set stock_cached = new_stock,
      updated_at = now()
  where id = NEW.product_id;

  -- Alert owners the first time stock goes negative (crossing only).
  if new_stock < 0 and product_row.stock_cached >= 0 then
    for member_row in
      select id from members
      where business_id = product_row.business_id
        and is_active
        and role = 'owner'
    loop
      perform insert_notification(
        product_row.business_id,
        member_row.id,
        'negative_stock',
        jsonb_build_object(
          'product_id', product_row.id,
          'name', product_row.name,
          'stock', new_stock
        )
      );
    end loop;
  end if;

  return NEW;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Per-product movement history index.
-- ---------------------------------------------------------------------------
-- Movement history lists sort by created_at within a product; the existing
-- single-column product index cannot serve that ordering.
create index if not exists stock_movements_product_created_idx
  on stock_movements(product_id, created_at);
