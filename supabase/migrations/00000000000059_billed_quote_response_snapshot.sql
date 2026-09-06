alter table quote_items add column if not exists product_name text;

update quote_items qi
set product_name = p.name
from products p
where p.id = qi.product_id
  and p.business_id = qi.business_id
  and qi.product_name is null;

create or replace function quote_items_snapshot_product_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
  v_business uuid;
begin
  v_business := new.business_id;
  if v_business is null then
    select q.business_id into v_business from quotes q where q.id = new.quote_id;
  end if;
  select p.name into v_name
  from products p
  where p.id = new.product_id
    and p.business_id = v_business;
  if v_name is not null then
    new.product_name := v_name;
  end if;
  return new;
end;
$$;

revoke all on function quote_items_snapshot_product_name() from public, anon, authenticated;

create trigger quote_items_snapshot_product_name
  before insert on quote_items
  for each row execute function quote_items_snapshot_product_name();

create or replace function guard_authenticated_order_billed()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.status = 'billed'
     and old.status is distinct from 'billed'
     and current_user is not distinct from 'authenticated' then
    raise exception 'order can only be billed via create_bill';
  end if;
  return new;
end;
$$;

revoke all on function guard_authenticated_order_billed() from public, anon, authenticated;

create trigger orders_guard_authenticated_billed
  before update of status on orders
  for each row execute function guard_authenticated_order_billed();

create or replace function guard_authenticated_quote_response()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if current_user is distinct from 'authenticated' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    if new.status in ('accepted', 'rejected') then
      raise exception 'quote response must use respond_quote';
    end if;
    return new;
  end if;
  if new.status is not distinct from old.status then
    return new;
  end if;
  if new.status in ('accepted', 'rejected')
     and current_role_name() is distinct from 'customer' then
    raise exception 'quote response must use respond_quote';
  end if;
  return new;
end;
$$;

revoke all on function guard_authenticated_quote_response() from public, anon, authenticated;

create trigger quotes_guard_authenticated_response
  before insert or update on quotes
  for each row execute function guard_authenticated_quote_response();

create or replace function public.billing_draft_from_order(p_order_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_role text := current_role_name();
  v_business uuid := current_business_id();
  v_order public.orders%rowtype;
  v_shop text;
  v_quote_id uuid;
  v_lines jsonb;
begin
  if v_role is null or v_role not in ('owner', 'sales', 'warehouse') then
    raise exception 'forbidden';
  end if;
  if p_order_id is null or v_business is null then
    raise exception 'order not found';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id and business_id = v_business;
  if not found then
    raise exception 'order not found';
  end if;
  if v_order.status = 'billed' then
    raise exception 'order already billed';
  end if;

  select shop_name into v_shop
  from public.customer_directory
  where customer_id = v_order.customer_id;

  select q.id into v_quote_id
  from public.quotes q
  where q.order_id = v_order.id
    and q.business_id = v_business
    and q.status = 'accepted'
  order by q.version desc
  limit 1;

  if v_quote_id is not null then
    select coalesce(jsonb_agg(line order by ord), '[]'::jsonb)
    into v_lines
    from (
      select jsonb_build_object(
        'product_id', qi.product_id,
        'name_snapshot', coalesce(qi.product_name, p.name, ''),
        'qty', qi.qty,
        'rate', qi.rate,
        'discount', qi.discount,
        'line_total', qi.line_total
      ) as line,
      qi.product_id::text as ord
      from public.quote_items qi
      left join public.products p on p.id = qi.product_id
      where qi.quote_id = v_quote_id
        and qi.business_id = v_business
    ) quoted;
    return jsonb_build_object(
      'order_id', v_order.id,
      'customer_id', v_order.customer_id,
      'shop_name', v_shop,
      'source', 'accepted_quote',
      'lines', v_lines
    );
  end if;

  select coalesce(jsonb_agg(line order by ord), '[]'::jsonb)
  into v_lines
  from (
    select jsonb_build_object(
      'product_id', oi.product_id,
      'name_snapshot', coalesce(oi.product_name, p.name, ''),
      'qty', oi.qty,
      'rate', coalesce(p.reference_price, 0),
      'discount', 0,
      'line_total', (oi.qty::bigint * coalesce(p.reference_price, 0))
    ) as line,
    oi.product_id::text as ord
    from public.order_items oi
    left join public.products p on p.id = oi.product_id
    where oi.order_id = v_order.id
      and oi.business_id = v_business
  ) unordered;

  return jsonb_build_object(
    'order_id', v_order.id,
    'customer_id', v_order.customer_id,
    'shop_name', v_shop,
    'source', 'order_items',
    'lines', v_lines
  );
end;
$$;

grant execute on function public.billing_draft_from_order(uuid) to authenticated;

notify pgrst, 'reload schema';
