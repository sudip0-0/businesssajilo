create or replace function place_order(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := (p->>'id')::uuid;
  v_customer uuid := (p->>'customer_id')::uuid;
  v_business uuid := current_business_id();
  v_items jsonb;
  v_existing_items jsonb;
  v_order orders%rowtype;
  item jsonb;
begin
  if current_role_name() is distinct from 'customer'
     or v_customer is distinct from own_customer_id()
     or v_customer is null or v_business is null then
    raise exception 'forbidden';
  end if;
  if p ? 'business_id' and (p->>'business_id')::uuid is distinct from v_business then
    raise exception 'forbidden';
  end if;
  if v_id is null then raise exception 'order id is required'; end if;
  if jsonb_typeof(p->'items') is distinct from 'array' then
    raise exception 'order must have at least one item';
  end if;
  if jsonb_array_length(p->'items') = 0 then
    raise exception 'order must have at least one item';
  end if;
  for item in select * from jsonb_array_elements(p->'items') loop
    if (item->>'qty')::int is null or (item->>'qty')::int <= 0 then
      raise exception 'item qty must be positive';
    end if;
  end loop;
  select jsonb_agg(jsonb_build_object('product_id', (x->>'product_id')::uuid,
    'qty', (x->>'qty')::int) order by x->>'product_id', (x->>'qty')::int)
    into v_items from jsonb_array_elements(p->'items') x;
  perform pg_advisory_xact_lock(hashtextextended(v_id::text, 52));
  select * into v_order from orders where id = v_id;
  if found then
    if v_order.business_id is distinct from v_business or v_order.customer_id is distinct from v_customer then
      raise exception 'forbidden';
    end if;
    select jsonb_agg(jsonb_build_object('product_id', product_id, 'qty', qty)
      order by product_id::text, qty) into v_existing_items from order_items where order_id = v_id;
    if v_existing_items is distinct from v_items
       or v_order.customer_note is distinct from nullif(btrim(p->>'customer_note'), '') then
      raise exception 'order retry payload does not match';
    end if;
    return jsonb_build_object('id', v_id, 'created', false);
  end if;
  for item in select * from jsonb_array_elements(v_items) loop
    perform 1 from products where id = (item->>'product_id')::uuid
      and business_id = v_business and is_active for share;
    if not found then raise exception 'active product not found'; end if;
  end loop;
  insert into orders(id, business_id, customer_id, status, customer_note)
  values(v_id, v_business, v_customer, 'placed', nullif(btrim(p->>'customer_note'), ''));
  insert into order_items(order_id, product_id, qty)
    select v_id, (x->>'product_id')::uuid, (x->>'qty')::int from jsonb_array_elements(v_items) x;
  return jsonb_build_object('id', v_id, 'created', true);
end;
$$;
revoke all on function place_order(jsonb) from public, anon;
grant execute on function place_order(jsonb) to authenticated;
drop policy if exists "customer inserts own orders" on orders;
drop policy if exists "customer inserts own order items" on order_items;

create or replace function guard_bill_order_customer()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_customer uuid;
begin
  if new.order_id is not null then
    select customer_id into v_customer from orders
      where id = new.order_id and business_id = new.business_id for update;
    if not found then raise exception 'order not found'; end if;
    if new.customer_id is distinct from v_customer then
      raise exception 'bill customer must match order customer';
    end if;
  end if;
  return new;
end;
$$;
create trigger bills_guard_order_customer before insert on bills
for each row execute function guard_bill_order_customer();
