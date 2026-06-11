-- Phase 6: notification fan-out triggers, realtime, optional push dispatch.

-- Shared helper for all notification inserts.
create or replace function insert_notification(
  p_business_id uuid,
  p_recipient_member_id uuid,
  p_type text,
  p_payload jsonb default '{}'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
begin
  insert into notifications (business_id, recipient_member_id, type, payload)
  values (p_business_id, p_recipient_member_id, p_type, coalesce(p_payload, '{}'::jsonb))
  returning id into new_id;
  return new_id;
end;
$$;

-- Refactor low-stock to use insert_notification.
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
      perform insert_notification(
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

-- Notify owner + sales when customer places an order.
create or replace function notify_order_placed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  member_row record;
begin
  if NEW.status != 'placed' then
    return NEW;
  end if;

  for member_row in
    select id from members
    where business_id = NEW.business_id
      and is_active
      and role in ('owner', 'sales')
  loop
    perform insert_notification(
      NEW.business_id,
      member_row.id,
      'order_placed',
      jsonb_build_object('order_id', NEW.id, 'status', NEW.status)
    );
  end loop;

  return NEW;
end;
$$;

create trigger orders_notify_placed
  after insert on orders
  for each row execute function notify_order_placed();

-- Notify customer when a quote is sent.
create or replace function notify_quote_sent()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  cust_member_id uuid;
  order_business_id uuid;
begin
  if NEW.status != 'sent' then
    return NEW;
  end if;

  select o.business_id, c.member_id
  into order_business_id, cust_member_id
  from orders o
  join customers c on c.id = o.customer_id
  where o.id = NEW.order_id;

  if cust_member_id is not null then
    perform insert_notification(
      order_business_id,
      cust_member_id,
      'quote_received',
      jsonb_build_object(
        'order_id', NEW.order_id,
        'quote_id', NEW.id,
        'version', NEW.version
      )
    );
  end if;

  return NEW;
end;
$$;

create trigger quotes_notify_sent
  after insert on quotes
  for each row execute function notify_quote_sent();

-- Notify staff when customer accepts/rejects a quote.
create or replace function notify_quote_response()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  member_row record;
  order_business_id uuid;
  notif_type text;
begin
  if OLD.status != 'sent' or NEW.status not in ('accepted', 'rejected') then
    return NEW;
  end if;

  notif_type := case NEW.status
    when 'accepted' then 'quote_accepted'
    else 'quote_rejected'
  end;

  select business_id into order_business_id
  from orders where id = NEW.order_id;

  -- Notify quote author.
  perform insert_notification(
    order_business_id,
    NEW.created_by,
    notif_type,
    jsonb_build_object(
      'order_id', NEW.order_id,
      'quote_id', NEW.id,
      'response_comment', NEW.response_comment
    )
  );

  -- Notify other active owner/sales (excluding duplicate on created_by).
  for member_row in
    select id from members
    where business_id = order_business_id
      and is_active
      and role in ('owner', 'sales')
      and id != NEW.created_by
  loop
    perform insert_notification(
      order_business_id,
      member_row.id,
      notif_type,
      jsonb_build_object(
        'order_id', NEW.order_id,
        'quote_id', NEW.id,
        'response_comment', NEW.response_comment
      )
    );
  end loop;

  return NEW;
end;
$$;

create trigger quotes_notify_response
  after update of status on quotes
  for each row execute function notify_quote_response();

-- Notify on order status changes.
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
begin
  if OLD.status = NEW.status or NEW.status = 'placed' then
    return NEW;
  end if;

  payload := jsonb_build_object(
    'order_id', NEW.id,
    'status', NEW.status,
    'previous_status', OLD.status
  );

  select c.member_id into cust_member_id
  from customers c where c.id = NEW.customer_id;

  if cust_member_id is not null then
    perform insert_notification(
      NEW.business_id,
      cust_member_id,
      'order_status',
      payload
    );
  end if;

  if NEW.status = 'confirmed' then
    for member_row in
      select id from members
      where business_id = NEW.business_id
        and is_active
        and role = 'warehouse'
    loop
      perform insert_notification(
        NEW.business_id,
        member_row.id,
        'order_status',
        payload
      );
    end loop;
  end if;

  for member_row in
    select id from members
    where business_id = NEW.business_id
      and is_active
      and role in ('owner', 'sales')
  loop
    perform insert_notification(
      NEW.business_id,
      member_row.id,
      'order_status',
      payload
    );
  end loop;

  return NEW;
end;
$$;

create trigger orders_notify_status_changed
  after update of status on orders
  for each row execute function notify_order_status_changed();

-- Notify on new chat messages.
create or replace function notify_chat_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  member_row record;
  sender_role member_role;
  cust_member_id uuid;
  payload jsonb;
begin
  select role into sender_role
  from members where id = NEW.sender_member_id;

  payload := jsonb_build_object(
    'order_id', NEW.order_id,
    'message_id', NEW.id,
    'sender_member_id', NEW.sender_member_id
  );

  if sender_role = 'customer' then
    for member_row in
      select id from members
      where business_id = NEW.business_id
        and is_active
        and role in ('owner', 'sales')
    loop
      perform insert_notification(
        NEW.business_id,
        member_row.id,
        'chat_message',
        payload
      );
    end loop;
  else
    select c.member_id into cust_member_id
    from orders o
    join customers c on c.id = o.customer_id
    where o.id = NEW.order_id;

    if cust_member_id is not null and cust_member_id != NEW.sender_member_id then
      perform insert_notification(
        NEW.business_id,
        cust_member_id,
        'chat_message',
        payload
      );
    end if;
  end if;

  return NEW;
end;
$$;

create trigger messages_notify_chat
  after insert on messages
  for each row execute function notify_chat_message();

-- Notify customer when payment is recorded.
create or replace function notify_payment_recorded()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  cust_member_id uuid;
begin
  select c.member_id into cust_member_id
  from customers c where c.id = NEW.customer_id;

  if cust_member_id is not null then
    perform insert_notification(
      NEW.business_id,
      cust_member_id,
      'payment_recorded',
      jsonb_build_object(
        'payment_id', NEW.id,
        'bill_id', NEW.bill_id,
        'customer_id', NEW.customer_id,
        'amount', NEW.amount
      )
    );
  end if;

  return NEW;
end;
$$;

create trigger payments_notify_recorded
  after insert on payments
  for each row execute function notify_payment_recorded();

-- Realtime for in-app notification feed.
alter publication supabase_realtime add table notifications;

-- Optional push dispatch via pg_net (no-op if extension unavailable).
do $do$
begin
  create extension if not exists pg_net with schema extensions;
exception
  when others then
    raise notice 'pg_net not available; push dispatch disabled until webhook configured';
end;
$do$;

create or replace function trigger_dispatch_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  notify_url text;
  service_key text;
begin
  if to_regprocedure('net.http_post(uuid,text,jsonb,jsonb,integer)') is null then
    return NEW;
  end if;

  notify_url := coalesce(
    current_setting('app.settings.notify_function_url', true),
    'http://host.docker.internal:54321/functions/v1/notify'
  );
  service_key := current_setting('app.settings.service_role_key', true);

  perform net.http_post(
    url := notify_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || coalesce(service_key, '')
    ),
    body := jsonb_build_object('notification_id', NEW.id)
  );

  return NEW;
exception
  when others then
    return NEW;
end;
$$;

create trigger notifications_dispatch_push
  after insert on notifications
  for each row execute function trigger_dispatch_push();
