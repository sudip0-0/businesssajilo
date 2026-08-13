-- v1.2 QoL: quote expiry, last-quoted-rate, oldest-first payment allocation,
-- operational nudges (stale quotes / dues), notification mute prefs.

-- ---------------------------------------------------------------------------
-- 1. Schema
-- ---------------------------------------------------------------------------

alter table quotes
  add column if not exists expires_at timestamptz;

comment on column quotes.expires_at is
  'When a sent quote should be treated as stale; defaulted by send_quote.';

create index if not exists quotes_sent_expires_idx
  on quotes (expires_at)
  where status = 'sent';

alter table members
  add column if not exists notification_prefs jsonb not null
    default '{"muted": ["dues_reminder"]}'::jsonb;

comment on column members.notification_prefs is
  'Optional {"muted": ["chat_message","low_stock","dues_reminder"]}. dues_reminder is muted by default.';

-- ---------------------------------------------------------------------------
-- 2. insert_notification respects mute prefs
-- ---------------------------------------------------------------------------

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
  muted boolean;
begin
  select coalesce(notification_prefs -> 'muted' ? p_type, false)
    into muted
  from members
  where id = p_recipient_member_id;

  if coalesce(muted, false) then
    return null;
  end if;

  insert into notifications (business_id, recipient_member_id, type, payload)
  values (
    p_business_id,
    p_recipient_member_id,
    p_type,
    coalesce(p_payload, '{}'::jsonb)
  )
  returning id into new_id;
  return new_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. send_quote stamps expires_at (7 days)
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

  insert into quotes (order_id, version, status, total, created_by, expires_at)
  values (
    p_order_id,
    v_version,
    'sent',
    v_total,
    current_member_id(),
    now() + interval '7 days'
  )
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
    'total', v_total,
    'expires_at', (now() + interval '7 days')
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Last quoted rate for a customer + product (accepted preferred, then sent)
-- ---------------------------------------------------------------------------

create or replace function last_quoted_rate(
  p_customer_id uuid,
  p_product_id uuid
)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select qi.rate
  from quote_items qi
  join quotes q on q.id = qi.quote_id
  join orders o on o.id = q.order_id
  where o.business_id = current_business_id()
    and o.customer_id = p_customer_id
    and qi.product_id = p_product_id
    and q.status in ('accepted', 'sent')
    and current_role_name() in ('owner', 'sales')
  order by
    case when q.status = 'accepted' then 0 else 1 end,
    q.created_at desc
  limit 1
$$;

grant execute on function last_quoted_rate(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. record_payment: oldest-first allocation when p.allocate = 'oldest_first'
-- ---------------------------------------------------------------------------

create or replace function record_payment(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_customer_id uuid;
  v_bill_id uuid;
  v_amount bigint;
  v_remaining bigint;
  v_chunk bigint;
  v_method payment_method;
  v_ref_note text;
  v_allocate text;
  v_member uuid;
  existing jsonb;
  result jsonb;
  bill_row bills%rowtype;
  paid_sum bigint;
  open_bill record;
  first_payment jsonb;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_member := current_member_id();
  v_id := coalesce((p->>'id')::uuid, gen_random_uuid());

  select to_jsonb(pay.*) into existing
  from payments pay
  where pay.id = v_id and pay.business_id = current_business_id();
  if existing is not null then
    return jsonb_build_object('payment', existing, 'created', false);
  end if;

  v_customer_id := (p->>'customer_id')::uuid;
  v_bill_id := (p->>'bill_id')::uuid;
  v_amount := (p->>'amount')::bigint;
  v_method := (p->>'method')::payment_method;
  v_ref_note := p->>'ref_note';
  v_allocate := coalesce(p->>'allocate', '');

  if v_customer_id is null then
    raise exception 'customer_id required';
  end if;
  if v_amount is null or v_amount <= 0 then
    raise exception 'amount must be positive';
  end if;
  if v_amount > 100000000000 then
    raise exception 'amount out of range';
  end if;

  if not exists (
    select 1 from customers
    where id = v_customer_id and business_id = current_business_id()
  ) then
    raise exception 'customer not found';
  end if;

  if v_allocate = 'oldest_first' and v_bill_id is null then
    v_remaining := v_amount;
    first_payment := null;

    for open_bill in
      select b.id, b.grand_total,
        (b.grand_total - coalesce((
          select sum(pay.amount) from payments pay where pay.bill_id = b.id
        ), 0)) as due_left
      from bills b
      where b.business_id = current_business_id()
        and b.customer_id = v_customer_id
        and b.status in ('due', 'partial')
      order by b.created_at asc
    loop
      exit when v_remaining <= 0;
      if open_bill.due_left <= 0 then
        continue;
      end if;
      v_chunk := least(v_remaining, open_bill.due_left);

      insert into payments (
        id, business_id, customer_id, bill_id, amount, method, ref_note, received_by
      ) values (
        case when first_payment is null then v_id else gen_random_uuid() end,
        current_business_id(),
        v_customer_id,
        open_bill.id,
        v_chunk,
        v_method,
        nullif(trim(coalesce(v_ref_note, '')), ''),
        v_member
      );

      select coalesce(sum(amount), 0) into paid_sum
      from payments where bill_id = open_bill.id;
      update bills set
        status = case
          when paid_sum >= grand_total then 'paid'::bill_status
          when paid_sum > 0 then 'partial'::bill_status
          else 'due'::bill_status
        end,
        updated_at = now()
      where id = open_bill.id;

      if first_payment is null then
        select to_jsonb(pay.*) into first_payment
        from payments pay where pay.id = v_id;
      end if;
      v_remaining := v_remaining - v_chunk;
    end loop;

    if v_remaining > 0 then
      insert into payments (
        id, business_id, customer_id, bill_id, amount, method, ref_note, received_by
      ) values (
        case when first_payment is null then v_id else gen_random_uuid() end,
        current_business_id(),
        v_customer_id,
        null,
        v_remaining,
        v_method,
        nullif(trim(coalesce(v_ref_note, '')), ''),
        v_member
      );
      if first_payment is null then
        select to_jsonb(pay.*) into first_payment
        from payments pay where pay.id = v_id;
      end if;
    end if;

    if first_payment is null then
      raise exception 'nothing to allocate';
    end if;
    return jsonb_build_object('payment', first_payment, 'created', true);
  end if;

  if v_bill_id is not null then
    select * into bill_row from bills
    where id = v_bill_id and business_id = current_business_id();
    if not found then
      raise exception 'bill not found';
    end if;
    if bill_row.customer_id is distinct from v_customer_id then
      raise exception 'bill customer mismatch';
    end if;
  end if;

  insert into payments (
    id, business_id, customer_id, bill_id, amount, method, ref_note, received_by
  ) values (
    v_id,
    current_business_id(),
    v_customer_id,
    v_bill_id,
    v_amount,
    v_method,
    nullif(trim(coalesce(v_ref_note, '')), ''),
    v_member
  );

  if v_bill_id is not null then
    select coalesce(sum(amount), 0) into paid_sum
    from payments where bill_id = v_bill_id;
    update bills set
      status = case
        when paid_sum >= grand_total then 'paid'::bill_status
        when paid_sum > 0 then 'partial'::bill_status
        else 'due'::bill_status
      end,
      updated_at = now()
    where id = v_bill_id;
  end if;

  select to_jsonb(pay.*) into result
  from payments pay where pay.id = v_id;
  return jsonb_build_object('payment', result, 'created', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Operational nudges (stale quotes + dues). Owner/sales, rate-limited.
-- ---------------------------------------------------------------------------

create or replace function process_operational_nudges()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int := 0;
  rec record;
  member_row record;
  v_biz uuid;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;
  v_biz := current_business_id();

  for rec in
    select q.id, q.order_id
    from quotes q
    join orders o on o.id = q.order_id
    where o.business_id = v_biz
      and q.status = 'sent'
      and q.expires_at is not null
      and q.expires_at < now()
  loop
    if exists (
      select 1 from notifications n
      where n.business_id = v_biz
        and n.type = 'quote_stale'
        and n.payload->>'quote_id' = rec.id::text
        and n.created_at > now() - interval '24 hours'
    ) then
      continue;
    end if;
    for member_row in
      select id from members
      where business_id = v_biz and is_active and role in ('owner', 'sales')
    loop
      if insert_notification(
        v_biz,
        member_row.id,
        'quote_stale',
        jsonb_build_object('quote_id', rec.id, 'order_id', rec.order_id)
      ) is not null then
        v_count := v_count + 1;
      end if;
    end loop;
  end loop;

  for rec in
    select c.id, c.shop_name, c.member_id, cb.balance_due
    from customers c
    join customer_balances cb on cb.customer_id = c.id
    where c.business_id = v_biz
      and cb.balance_due > 0
    order by cb.balance_due desc
    limit 25
  loop
    if exists (
      select 1 from notifications n
      where n.business_id = v_biz
        and n.type = 'dues_reminder'
        and n.payload->>'customer_id' = rec.id::text
        and n.created_at > now() - interval '7 days'
    ) then
      continue;
    end if;
    for member_row in
      select id from members
      where business_id = v_biz
        and is_active
        and (
          role = 'owner'
          or id = rec.member_id
        )
    loop
      if insert_notification(
        v_biz,
        member_row.id,
        'dues_reminder',
        jsonb_build_object(
          'customer_id', rec.id,
          'shop_name', rec.shop_name,
          'balance_due', rec.balance_due
        )
      ) is not null then
        v_count := v_count + 1;
      end if;
    end loop;
  end loop;

  return v_count;
end;
$$;

grant execute on function process_operational_nudges() to authenticated;

grant execute on function record_payment(jsonb) to authenticated;

grant execute on function send_quote(uuid, jsonb) to authenticated;

create or replace function update_own_notification_prefs(p_muted text[])
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update members
  set notification_prefs = jsonb_build_object('muted', to_jsonb(coalesce(p_muted, '{}'::text[])))
  where id = current_member_id();
end;
$$;

grant execute on function update_own_notification_prefs(text[]) to authenticated;

