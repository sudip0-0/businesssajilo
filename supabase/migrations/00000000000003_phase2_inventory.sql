-- Phase 2: categories, products, stock_movements, notifications, storage.

create table categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  name text not null,
  name_np text,
  created_at timestamptz not null default now()
);

create index categories_business_idx on categories(business_id);

create table products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  category_id uuid references categories(id) on delete set null,
  name text not null,
  name_np text,
  sku text,
  unit text not null default 'piece',
  cost_price bigint not null default 0,
  reference_price bigint not null default 0,
  image_url text,
  low_stock_threshold int not null default 0,
  stock_cached int not null default 0,
  was_above_threshold boolean not null default true,
  is_active boolean not null default true,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index products_business_idx on products(business_id);
create index products_category_idx on products(category_id);

create table stock_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  product_id uuid not null references products(id),
  type stock_movement_type not null,
  qty_delta int not null,
  reason text,
  ref_order_id uuid,
  created_by uuid not null references members(id),
  created_at timestamptz not null default now(),
  constraint adjust_requires_reason check (
    type != 'adjust' or (reason is not null and length(trim(reason)) > 0)
  ),
  constraint qty_delta_nonzero check (qty_delta != 0)
);

create index stock_movements_product_idx on stock_movements(product_id);
create index stock_movements_business_idx on stock_movements(business_id);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  recipient_member_id uuid not null references members(id),
  type text not null,
  payload jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_recipient_idx on notifications(recipient_member_id);

-- Auto-set business_id on insert from JWT context.
create or replace function set_row_business_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.business_id is null then
    NEW.business_id := current_business_id();
  end if;
  return NEW;
end;
$$;

create trigger categories_set_business
  before insert on categories
  for each row execute function set_row_business_id();

create trigger products_set_business
  before insert on products
  for each row execute function set_row_business_id();

create trigger stock_movements_set_business
  before insert on stock_movements
  for each row execute function set_row_business_id();

-- Helper: current member id for created_by fields.
create or replace function current_member_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from members where auth_user_id = auth.uid() and is_active
$$;

-- Recalculate stock_cached after movement insert.
create or replace function recalc_product_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_stock int;
begin
  select coalesce(sum(qty_delta), 0)::int into new_stock
  from stock_movements
  where product_id = NEW.product_id;

  update products
  set stock_cached = new_stock,
      updated_at = now()
  where id = NEW.product_id;

  return NEW;
end;
$$;

create trigger stock_movements_recalc_stock
  after insert on stock_movements
  for each row
  execute function recalc_product_stock();

-- Low-stock notification when crossing below threshold.
create or replace function notify_low_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  member_row record;
begin
  if NEW.low_stock_threshold <= 0 then
    return NEW;
  end if;

  if NEW.stock_cached <= NEW.low_stock_threshold
     and (OLD.stock_cached > OLD.low_stock_threshold or OLD.was_above_threshold) then
    for member_row in
      select id from members
      where business_id = NEW.business_id
        and is_active
        and role in ('owner', 'warehouse')
    loop
      insert into notifications (business_id, recipient_member_id, type, payload)
      values (
        NEW.business_id,
        member_row.id,
        'low_stock',
        jsonb_build_object(
          'product_id', NEW.id,
          'name', NEW.name,
          'stock', NEW.stock_cached,
          'threshold', NEW.low_stock_threshold
        )
      );
    end loop;
    NEW.was_above_threshold := false;
  elsif NEW.stock_cached > NEW.low_stock_threshold then
    NEW.was_above_threshold := true;
  end if;

  return NEW;
end;
$$;

create trigger products_notify_low_stock
  before update of stock_cached on products
  for each row
  execute function notify_low_stock();

-- RLS: categories
alter table categories enable row level security;

create policy "staff read categories" on categories
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales', 'warehouse')
  );

create policy "owner manages categories" on categories
  for all using (
    business_id = current_business_id()
    and current_role_name() = 'owner'
  )
  with check (
    business_id = current_business_id()
    and current_role_name() = 'owner'
  );

-- RLS: products
alter table products enable row level security;

create policy "staff read active products" on products
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales', 'warehouse')
    and (is_active or current_role_name() = 'owner')
  );

create policy "owner manages products" on products
  for all using (
    business_id = current_business_id()
    and current_role_name() = 'owner'
  )
  with check (
    business_id = current_business_id()
    and current_role_name() = 'owner'
  );

-- RLS: stock_movements (append-only — no update/delete policies)
alter table stock_movements enable row level security;

create policy "staff read movements" on stock_movements
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales', 'warehouse')
  );

create policy "owner warehouse insert movements" on stock_movements
  for insert with check (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'warehouse')
    and created_by = current_member_id()
  );

-- RLS: notifications
alter table notifications enable row level security;

create policy "recipient reads own notifications" on notifications
  for select using (
    business_id = current_business_id()
    and recipient_member_id = current_member_id()
  );

create policy "recipient marks notifications read" on notifications
  for update using (
    business_id = current_business_id()
    and recipient_member_id = current_member_id()
  )
  with check (
    business_id = current_business_id()
    and recipient_member_id = current_member_id()
  );

-- Force RLS
alter table categories force row level security;
alter table products force row level security;
alter table stock_movements force row level security;
alter table notifications force row level security;

-- Storage bucket for product images
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
);

create policy "staff read product images" on storage.objects
  for select using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() in ('owner', 'sales', 'warehouse')
  );

create policy "owner upload product images" on storage.objects
  for insert with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() = 'owner'
  );

create policy "owner update product images" on storage.objects
  for update using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() = 'owner'
  );

create policy "owner delete product images" on storage.objects
  for delete using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() = 'owner'
  );
