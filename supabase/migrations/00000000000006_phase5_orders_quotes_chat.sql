-- Phase 5: orders, quotes, messages, customer catalog, dispatch stock, chat storage.

-- Helper: customer row for logged-in customer member.
create or replace function own_customer_id() returns uuid
language sql stable security definer set search_path = public as $$
  select c.id
  from customers c
  join members m on m.id = c.member_id
  where m.auth_user_id = auth.uid() and m.is_active
$$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  customer_id uuid not null references customers(id),
  status order_status not null default 'placed',
  customer_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index orders_business_status_idx on orders(business_id, status);
create index orders_customer_idx on orders(customer_id);

create table order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  product_id uuid not null references products(id),
  qty int not null,
  constraint order_item_qty_positive check (qty > 0)
);

create index order_items_order_idx on order_items(order_id);

create table quotes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  version int not null,
  status quote_status not null default 'sent',
  total bigint not null default 0,
  response_comment text,
  created_by uuid not null references members(id),
  created_at timestamptz not null default now(),
  constraint quote_total_non_negative check (total >= 0),
  unique (order_id, version)
);

create index quotes_order_idx on quotes(order_id);

create table quote_items (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid not null references quotes(id) on delete cascade,
  product_id uuid not null references products(id),
  qty int not null,
  rate bigint not null default 0,
  discount bigint not null default 0,
  line_total bigint not null default 0,
  constraint quote_item_qty_positive check (qty > 0)
);

create index quote_items_quote_idx on quote_items(quote_id);

create table messages (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  business_id uuid not null references businesses(id),
  sender_member_id uuid not null references members(id),
  body text not null default '',
  image_url text,
  created_at timestamptz not null default now(),
  constraint message_has_content check (
    length(trim(body)) > 0 or image_url is not null
  )
);

create index messages_order_idx on messages(order_id);

-- FKs from prior phases
alter table bills
  add constraint bills_order_id_fkey
  foreign key (order_id) references orders(id);

alter table stock_movements
  add constraint stock_movements_ref_order_id_fkey
  foreign key (ref_order_id) references orders(id);

-- ---------------------------------------------------------------------------
-- Customer catalog view (no price columns)
-- ---------------------------------------------------------------------------

create view catalog_products
with (security_invoker = false)
as
select
  id,
  business_id,
  category_id,
  name,
  name_np,
  sku,
  unit,
  image_url,
  stock_cached,
  is_active
from products
where is_active = true;

-- Customer catalog access via security definer RPC (view has no column-level RLS).
create or replace function list_catalog_products()
returns table (
  id uuid,
  business_id uuid,
  category_id uuid,
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
    p.category_id,
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

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

create trigger orders_set_business
  before insert on orders
  for each row execute function set_row_business_id();

create trigger messages_set_business
  before insert on messages
  for each row execute function set_row_business_id();

create or replace function orders_bump_updated_at()
returns trigger
language plpgsql
as $$
begin
  NEW.updated_at := now();
  return NEW;
end;
$$;

create trigger orders_updated_at
  before update on orders
  for each row execute function orders_bump_updated_at();

-- Validate order status transitions (mirrors lib/domain/enums.dart orderTransitions).
create or replace function validate_order_status_transition()
returns trigger
language plpgsql
as $$
declare
  allowed boolean;
begin
  if OLD.status = NEW.status then
    return NEW;
  end if;

  allowed := case OLD.status
    when 'draft' then NEW.status in ('placed', 'cancelled')
    when 'placed' then NEW.status in ('quoted', 'cancelled')
    when 'quoted' then NEW.status in ('accepted', 'rejected', 'quoted', 'cancelled')
    when 'accepted' then NEW.status in ('confirmed', 'cancelled')
    when 'rejected' then NEW.status in ('quoted', 'cancelled')
    when 'confirmed' then NEW.status in ('packed', 'cancelled')
    when 'packed' then NEW.status = 'dispatched'
    when 'dispatched' then NEW.status = 'billed'
    when 'billed' then NEW.status = 'closed'
    else false
  end;

  if not allowed then
    raise exception 'invalid order status transition: % -> %', OLD.status, NEW.status;
  end if;

  return NEW;
end;
$$;

create trigger orders_validate_status
  before update of status on orders
  for each row execute function validate_order_status_transition();

-- Auto stock deduction when order is dispatched.
create or replace function dispatch_order_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  item record;
  mover uuid;
begin
  if NEW.status != 'dispatched' or OLD.status = 'dispatched' then
    return NEW;
  end if;

  if exists (
    select 1 from stock_movements
    where ref_order_id = NEW.id and type = 'dispatch'
  ) then
    return NEW;
  end if;

  mover := current_member_id();
  if mover is null then
    select id into mover from members
    where business_id = NEW.business_id and role = 'owner' and is_active
    limit 1;
  end if;

  for item in
    select product_id, qty from order_items where order_id = NEW.id
  loop
    insert into stock_movements (
      business_id, product_id, type, qty_delta, reason, ref_order_id, created_by
    ) values (
      NEW.business_id,
      item.product_id,
      'dispatch',
      -item.qty,
      'Order dispatch',
      NEW.id,
      mover
    );
  end loop;

  return NEW;
end;
$$;

create trigger orders_dispatch_stock
  after update of status on orders
  for each row execute function dispatch_order_stock();

-- When a quote is sent, move order to quoted.
create or replace function quote_sent_sync_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.status = 'sent' then
    update orders
    set status = 'quoted'
    where id = NEW.order_id
      and status in ('placed', 'quoted', 'rejected');
  end if;
  return NEW;
end;
$$;

create trigger quotes_sent_sync_order
  after insert on quotes
  for each row execute function quote_sent_sync_order();

-- When customer accepts/rejects quote, sync order status.
create or replace function quote_response_sync_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if OLD.status = 'sent' and NEW.status = 'accepted' then
    update orders set status = 'accepted' where id = NEW.order_id and status = 'quoted';
  elsif OLD.status = 'sent' and NEW.status = 'rejected' then
    update orders set status = 'rejected' where id = NEW.order_id and status = 'quoted';
  end if;
  return NEW;
end;
$$;

create trigger quotes_response_sync_order
  after update of status on quotes
  for each row execute function quote_response_sync_order();

-- ---------------------------------------------------------------------------
-- RLS: categories — customer read for catalog labels
-- ---------------------------------------------------------------------------

create policy "customer reads categories" on categories
  for select using (
    business_id = current_business_id()
    and current_role_name() = 'customer'
  );

-- ---------------------------------------------------------------------------
-- RLS: orders
-- ---------------------------------------------------------------------------

alter table orders enable row level security;

create policy "customer inserts own orders" on orders
  for insert with check (
    business_id = current_business_id()
    and current_role_name() = 'customer'
    and customer_id = own_customer_id()
    and status = 'placed'
  );

create policy "customer reads own orders" on orders
  for select using (
    business_id = current_business_id()
    and current_role_name() = 'customer'
    and customer_id = own_customer_id()
  );

create policy "owner sales read orders" on orders
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  );

create policy "warehouse reads fulfillment orders" on orders
  for select using (
    business_id = current_business_id()
    and current_role_name() = 'warehouse'
    and status in ('confirmed', 'packed', 'dispatched')
  );

create policy "owner sales update orders" on orders
  for update using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  )
  with check (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  );

create policy "warehouse updates fulfillment orders" on orders
  for update using (
    business_id = current_business_id()
    and current_role_name() = 'warehouse'
    and status in ('confirmed', 'packed')
  )
  with check (
    business_id = current_business_id()
    and current_role_name() = 'warehouse'
    and status in ('packed', 'dispatched')
  );

-- ---------------------------------------------------------------------------
-- RLS: order_items
-- ---------------------------------------------------------------------------

alter table order_items enable row level security;

create policy "customer inserts own order items" on order_items
  for insert with check (
    order_id in (
      select id from orders
      where customer_id = own_customer_id()
        and status = 'placed'
        and business_id = current_business_id()
    )
  );

create policy "customer reads own order items" on order_items
  for select using (
    order_id in (
      select id from orders where customer_id = own_customer_id()
    )
  );

create policy "staff read order items" on order_items
  for select using (
    order_id in (
      select id from orders where business_id = current_business_id()
        and current_role_name() in ('owner', 'sales', 'warehouse')
    )
  );

-- ---------------------------------------------------------------------------
-- RLS: quotes
-- ---------------------------------------------------------------------------

alter table quotes enable row level security;

create policy "owner sales manage quotes" on quotes
  for all using (
    order_id in (
      select id from orders
      where business_id = current_business_id()
        and current_role_name() in ('owner', 'sales')
    )
  )
  with check (
    order_id in (
      select id from orders
      where business_id = current_business_id()
        and current_role_name() in ('owner', 'sales')
    )
    and created_by = current_member_id()
  );

create policy "customer reads own quotes" on quotes
  for select using (
    order_id in (
      select id from orders
      where customer_id = own_customer_id()
    )
  );

create policy "customer responds to sent quotes" on quotes
  for update using (
    order_id in (
      select id from orders
      where customer_id = own_customer_id()
    )
    and status = 'sent'
  )
  with check (
    order_id in (
      select id from orders
      where customer_id = own_customer_id()
    )
    and status in ('accepted', 'rejected')
  );

-- ---------------------------------------------------------------------------
-- RLS: quote_items
-- ---------------------------------------------------------------------------

alter table quote_items enable row level security;

create policy "owner sales manage quote items" on quote_items
  for all using (
    quote_id in (
      select q.id from quotes q
      join orders o on o.id = q.order_id
      where o.business_id = current_business_id()
        and current_role_name() in ('owner', 'sales')
    )
  )
  with check (
    quote_id in (
      select q.id from quotes q
      join orders o on o.id = q.order_id
      where o.business_id = current_business_id()
        and current_role_name() in ('owner', 'sales')
    )
  );

create policy "customer reads own quote items" on quote_items
  for select using (
    quote_id in (
      select q.id from quotes q
      join orders o on o.id = q.order_id
      where o.customer_id = own_customer_id()
    )
  );

-- ---------------------------------------------------------------------------
-- RLS: messages (append-only)
-- ---------------------------------------------------------------------------

alter table messages enable row level security;

create policy "customer reads own order messages" on messages
  for select using (
    order_id in (
      select id from orders where customer_id = own_customer_id()
    )
  );

create policy "customer inserts own order messages" on messages
  for insert with check (
    business_id = current_business_id()
    and current_role_name() = 'customer'
    and sender_member_id = current_member_id()
    and order_id in (
      select id from orders where customer_id = own_customer_id()
    )
  );

create policy "owner sales read order messages" on messages
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  );

create policy "owner sales insert order messages" on messages
  for insert with check (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
    and sender_member_id = current_member_id()
    and order_id in (
      select id from orders where business_id = current_business_id()
    )
  );

-- Force RLS
alter table orders force row level security;
alter table order_items force row level security;
alter table quotes force row level security;
alter table quote_items force row level security;
alter table messages force row level security;

-- ---------------------------------------------------------------------------
-- Storage: order chat images
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'order-chat-images',
  'order-chat-images',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy "chat participants read images" on storage.objects
  for select using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() in ('owner', 'sales', 'customer')
  );

create policy "chat participants upload images" on storage.objects
  for insert with check (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() in ('owner', 'sales', 'customer')
  );

-- Realtime for order chat
alter publication supabase_realtime add table messages;
