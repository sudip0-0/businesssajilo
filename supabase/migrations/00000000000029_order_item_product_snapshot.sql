-- Snapshot product display fields onto order_items so customers can see
-- names/units/images without SELECT on products (prices stay hidden).

alter table order_items
  add column if not exists product_name text,
  add column if not exists product_name_np text,
  add column if not exists unit text,
  add column if not exists image_url text;

comment on column order_items.product_name is
  'Display name snapped at order time; customers cannot join products.';

update order_items oi
set
  product_name = coalesce(oi.product_name, p.name),
  product_name_np = coalesce(oi.product_name_np, p.name_np),
  unit = coalesce(oi.unit, p.unit),
  image_url = coalesce(oi.image_url, p.image_url)
from products p
where p.id = oi.product_id
  and (
    oi.product_name is null
    or oi.unit is null
    or oi.image_url is null
    or oi.product_name_np is null
  );

create or replace function order_items_snapshot_product()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  p products%rowtype;
begin
  select * into p from products where id = NEW.product_id;
  if found then
    NEW.product_name := coalesce(NEW.product_name, p.name);
    NEW.product_name_np := coalesce(NEW.product_name_np, p.name_np);
    NEW.unit := coalesce(NEW.unit, p.unit);
    NEW.image_url := coalesce(NEW.image_url, p.image_url);
  end if;
  return NEW;
end;
$$;

drop trigger if exists order_items_snapshot_product on order_items;
create trigger order_items_snapshot_product
  before insert on order_items
  for each row execute function order_items_snapshot_product();
