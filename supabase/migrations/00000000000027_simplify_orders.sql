-- Simplify orders to placed → received → billed.
-- Retires quote/fulfillment status sync; billing allowed from placed|received.

-- ---------------------------------------------------------------------------
-- 1. Drop status-dependent triggers before remapping
-- ---------------------------------------------------------------------------

drop trigger if exists orders_validate_status on orders;
drop trigger if exists orders_dispatch_stock on orders;
drop trigger if exists orders_notify_status_changed on orders;
drop trigger if exists quotes_sent_sync_order on quotes;
drop trigger if exists quotes_response_sync_order on quotes;

-- ---------------------------------------------------------------------------
-- 2. Remap status column via text, then replace enum
-- ---------------------------------------------------------------------------

alter table orders alter column status drop default;

alter table orders
  alter column status type text
  using status::text;

update orders set status = case
  when status in ('billed', 'closed') then 'billed'
  when status in ('confirmed', 'packed', 'dispatched', 'received') then 'received'
  else 'placed'
end;

drop type order_status;

create type order_status as enum ('placed', 'received', 'billed');

alter table orders
  alter column status type order_status
  using status::order_status;

alter table orders
  alter column status set default 'placed'::order_status;

-- ---------------------------------------------------------------------------
-- 2. Transitions: placed → received|billed; received → billed
-- ---------------------------------------------------------------------------

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
    when 'placed' then NEW.status in ('received', 'billed')
    when 'received' then NEW.status = 'billed'
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

-- ---------------------------------------------------------------------------
-- 3. Retire quote → order sync and dispatch stock (no-ops kept as stubs)
-- ---------------------------------------------------------------------------

create or replace function quote_sent_sync_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Quotes no longer drive order status.
  return NEW;
end;
$$;

create or replace function quote_response_sync_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Quotes no longer drive order status.
  return NEW;
end;
$$;

create or replace function dispatch_order_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Stock deduction now happens via billing, not order dispatch.
  return NEW;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Notifications: customer on received; no warehouse on confirmed
-- ---------------------------------------------------------------------------

create or replace function notify_order_status_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  member_row record;
  cust_member_id uuid;
  payload jsonb;
  notif_type text;
begin
  if OLD.status = NEW.status or NEW.status = 'placed' then
    return NEW;
  end if;

  payload := jsonb_build_object(
    'order_id', NEW.id,
    'status', NEW.status,
    'previous_status', OLD.status
  );

  notif_type := case
    when NEW.status = 'received' then 'order_received'
    else 'order_status'
  end;

  select c.member_id into cust_member_id
  from customers c where c.id = NEW.customer_id;

  if cust_member_id is not null then
    perform insert_notification(
      NEW.business_id,
      cust_member_id,
      notif_type,
      payload
    );
  end if;

  -- Staff get billed (and other non-received) updates; received is customer-only.
  if NEW.status != 'received' then
    for member_row in
      select id from members
      where business_id = NEW.business_id
        and is_active
        and role in ('owner', 'sales')
    loop
      perform insert_notification(
        NEW.business_id,
        member_row.id,
        notif_type,
        payload
      );
    end loop;
  end if;

  return NEW;
end;
$$;

create trigger orders_notify_status_changed
  after update of status on orders
  for each row execute function notify_order_status_changed();

-- ---------------------------------------------------------------------------
-- 5. create_bill: allow placed or received orders
-- ---------------------------------------------------------------------------

create or replace function create_bill(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_customer_id uuid;
  v_order_id uuid;
  v_discount bigint;
  v_items_total bigint := 0;
  v_grand_total bigint;
  v_status bill_status;
  v_device_prefix text;
  item jsonb;
  v_qty int;
  v_rate bigint;
  v_item_discount bigint;
  v_payment jsonb;
  v_pay_amount bigint;
  v_pay_id uuid;
  v_member uuid;
  order_row orders%rowtype;
  existing jsonb;
  result jsonb;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_member := current_member_id();
  v_id := coalesce((p->>'id')::uuid, gen_random_uuid());

  select to_jsonb(b.*) into existing
  from bills b
  where b.id = v_id and b.business_id = current_business_id();
  if existing is not null then
    return jsonb_build_object('bill', existing, 'created', false);
  end if;

  v_customer_id := (p->>'customer_id')::uuid;
  v_order_id := (p->>'order_id')::uuid;
  v_discount := coalesce((p->>'discount')::bigint, 0);
  v_device_prefix := p->>'device_prefix';
  v_payment := p->'payment';

  if v_customer_id is null then
    v_status := 'paid';
  else
    v_status := 'due';
  end if;

  if v_customer_id is not null and not exists (
    select 1 from customers
    where id = v_customer_id and business_id = current_business_id()
  ) then
    raise exception 'customer not found';
  end if;

  if p->'items' is null or jsonb_array_length(p->'items') = 0 then
    raise exception 'bill must have at least one item';
  end if;

  for item in select * from jsonb_array_elements(p->'items')
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_item_discount := coalesce((item->>'discount')::bigint, 0);
    if v_qty is null or v_qty <= 0 then
      raise exception 'item qty must be positive';
    end if;
    if v_rate is null or v_rate < 0 then
      raise exception 'item rate cannot be negative';
    end if;
    if v_item_discount < 0 or v_item_discount > v_qty * v_rate then
      raise exception 'item discount out of range';
    end if;
    v_items_total := v_items_total + (v_qty * v_rate - v_item_discount);
  end loop;

  if v_discount < 0 or v_discount > v_items_total then
    raise exception 'bill discount out of range';
  end if;
  v_grand_total := v_items_total - v_discount;

  if v_order_id is not null then
    select * into order_row from orders
    where id = v_order_id and business_id = current_business_id()
    for update;
    if order_row.id is null then
      raise exception 'order not found';
    end if;
    if exists (select 1 from bills where order_id = v_order_id) then
      raise exception 'order is already billed';
    end if;
    if order_row.status not in ('placed', 'received') then
      raise exception 'order must be placed or received before billing';
    end if;
    if v_customer_id is null then
      v_customer_id := order_row.customer_id;
      v_status := 'due';
    end if;
  end if;

  insert into bills (
    id, business_id, customer_id, order_id, device_prefix,
    items_total, discount, grand_total, status, created_by
  ) values (
    v_id, current_business_id(), v_customer_id, v_order_id, v_device_prefix,
    v_items_total, v_discount, v_grand_total, v_status, v_member
  );

  for item in select * from jsonb_array_elements(p->'items')
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_item_discount := coalesce((item->>'discount')::bigint, 0);
    insert into bill_items (
      bill_id, product_id, name_snapshot, qty, rate, discount, line_total
    ) values (
      v_id,
      (item->>'product_id')::uuid,
      coalesce(item->>'name_snapshot', ''),
      v_qty,
      v_rate,
      v_item_discount,
      v_qty * v_rate - v_item_discount
    );
  end loop;

  if v_payment is not null then
    v_pay_amount := coalesce((v_payment->>'amount')::bigint, 0);
    if v_pay_amount > 0 then
      if v_customer_id is null then
        raise exception 'payment requires a customer';
      end if;
      v_pay_id := coalesce((v_payment->>'id')::uuid, gen_random_uuid());
      insert into payments (
        id, business_id, customer_id, bill_id, amount, method, ref_note, received_by
      ) values (
        v_pay_id,
        current_business_id(),
        v_customer_id,
        v_id,
        v_pay_amount,
        (v_payment->>'method')::payment_method,
        v_payment->>'ref_note',
        v_member
      );
    end if;
  end if;

  if v_customer_id is null then
    update bills set status = 'paid' where id = v_id and status != 'paid';
  else
    perform refresh_bill_status_for(v_id);
  end if;

  if v_order_id is not null then
    update orders set status = 'billed' where id = v_order_id;
  end if;

  select to_jsonb(b.*) into result from bills b where b.id = v_id;
  return jsonb_build_object('bill', result, 'created', true);
end;
$$;

grant execute on function create_bill(jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. send_quote: allow placed/received only; do not mutate order status
-- ---------------------------------------------------------------------------

create or replace function send_quote(
  p_order_id uuid,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  order_row orders%rowtype;
  item jsonb;
  v_version int;
  v_total bigint := 0;
  v_qty int;
  v_rate bigint;
  v_discount bigint;
  v_line bigint;
  v_quote_id uuid;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  select * into order_row from orders
  where id = p_order_id and business_id = current_business_id()
  for update;

  if order_row.id is null then
    raise exception 'order not found';
  end if;

  if order_row.status not in ('placed', 'received') then
    raise exception 'order cannot be quoted in status %', order_row.status;
  end if;

  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'quote must have at least one item';
  end if;

  for item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_discount := coalesce((item->>'discount')::bigint, 0);
    if v_qty is null or v_qty <= 0 then
      raise exception 'item qty must be positive';
    end if;
    if v_rate is null or v_rate < 0 then
      raise exception 'item rate cannot be negative';
    end if;
    if v_discount < 0 or v_discount > v_qty * v_rate then
      raise exception 'item discount out of range';
    end if;
    v_total := v_total + (v_qty * v_rate - v_discount);
  end loop;

  update quotes set status = 'superseded'
  where order_id = p_order_id and status = 'sent';

  select coalesce(max(version), 0) + 1 into v_version
  from quotes where order_id = p_order_id;

  insert into quotes (order_id, version, status, total, created_by)
  values (p_order_id, v_version, 'sent', v_total, current_member_id())
  returning id into v_quote_id;

  for item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := (item->>'qty')::int;
    v_rate := (item->>'rate')::bigint;
    v_discount := coalesce((item->>'discount')::bigint, 0);
    v_line := v_qty * v_rate - v_discount;
    insert into quote_items (quote_id, product_id, qty, rate, discount, line_total)
    values (
      v_quote_id,
      (item->>'product_id')::uuid,
      v_qty,
      v_rate,
      v_discount,
      v_line
    );
  end loop;

  return jsonb_build_object(
    'id', v_quote_id,
    'order_id', p_order_id,
    'version', v_version,
    'status', 'sent',
    'total', v_total
  );
end;
$$;

grant execute on function send_quote(uuid, jsonb) to authenticated;
