-- Preserve the original bill occurrence time when an offline bill syncs later.
-- create_bill / record_customer_sale used default now(), so a yesterday bill
-- that synced today was counted in today's sales (report_sales_daily).

create or replace function occurred_at_from_payload(p jsonb)
returns timestamptz
language plpgsql
stable
set search_path = public
as $$
declare
  v timestamptz;
begin
  begin
    v := nullif(btrim(coalesce(p->>'created_at', '')), '')::timestamptz;
  exception when others then
    return now();
  end;
  if v is null then
    return now();
  end if;
  if v > now() + interval '15 minutes' then
    return now();
  end if;
  return v;
end;
$$;

revoke all on function occurred_at_from_payload(jsonb) from public;

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
  v_guest_name text;
  v_created_at timestamptz;
  item jsonb;
  v_qty int;
  v_rate bigint;
  v_item_discount bigint;
  v_payment jsonb;
  v_pay_amount bigint;
  v_pay_id uuid;
  v_member uuid;
  v_role text;
  order_row orders%rowtype;
  existing jsonb;
  result jsonb;
begin
  v_role := current_role_name();
  if v_role not in ('owner', 'sales', 'warehouse') then
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
  v_guest_name := nullif(btrim(coalesce(p->>'guest_name', '')), '');
  v_created_at := occurred_at_from_payload(p);

  if v_role = 'warehouse' and v_payment is not null then
    raise exception 'warehouse cannot record payment with bill';
  end if;

  if v_customer_id is null then
    v_status := 'paid';
  else
    v_status := 'due';
    v_guest_name := null;
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
      v_guest_name := null;
    end if;
  end if;

  insert into bills (
    id, business_id, customer_id, order_id, device_prefix,
    items_total, discount, grand_total, status, created_by, guest_name,
    created_at
  ) values (
    v_id, current_business_id(), v_customer_id, v_order_id, v_device_prefix,
    v_items_total, v_discount, v_grand_total, v_status, v_member, v_guest_name,
    v_created_at
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

create or replace function record_customer_sale(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_customer_id uuid;
  v_amount bigint;
  v_note text;
  v_status bill_status;
  v_payment jsonb;
  v_pay_amount bigint;
  v_member uuid;
  v_created_at timestamptz;
  existing jsonb;
  result jsonb;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_member := current_member_id();
  v_id := coalesce((p->>'id')::uuid, gen_random_uuid());
  v_customer_id := (p->>'customer_id')::uuid;
  v_amount := (p->>'amount')::bigint;
  v_note := nullif(trim(coalesce(p->>'ref_note', '')), '');
  v_payment := p->'payment';
  v_created_at := occurred_at_from_payload(p);

  if v_customer_id is null then
    raise exception 'customer_id is required';
  end if;
  if v_amount is null or v_amount <= 0 then
    raise exception 'amount must be positive';
  end if;

  if not exists (
    select 1 from customers
    where id = v_customer_id and business_id = current_business_id()
  ) then
    raise exception 'customer not found';
  end if;

  select to_jsonb(b.*) into existing
  from bills b
  where b.id = v_id and b.business_id = current_business_id();
  if existing is not null then
    return jsonb_build_object('bill', existing, 'created', false);
  end if;

  if v_payment is not null
     and coalesce((v_payment->>'amount')::bigint, 0) > 0 then
    v_status := 'paid';
  else
    v_status := 'due';
  end if;

  insert into bills (
    id, business_id, customer_id, order_id, device_prefix,
    items_total, discount, grand_total, status, created_by, created_at
  ) values (
    v_id, current_business_id(), v_customer_id, null, p->>'device_prefix',
    v_amount, 0, v_amount, v_status, v_member, v_created_at
  );

  insert into bill_items (
    bill_id, product_id, name_snapshot, qty, rate, discount, line_total
  ) values (
    v_id,
    null,
    coalesce(v_note, 'Manual sale'),
    1,
    v_amount,
    0,
    v_amount
  );

  if v_payment is not null then
    v_pay_amount := coalesce((v_payment->>'amount')::bigint, 0);
    if v_pay_amount > 0 then
      insert into payments (
        id, business_id, customer_id, bill_id, amount, method, ref_note, received_by
      ) values (
        coalesce((v_payment->>'id')::uuid, gen_random_uuid()),
        current_business_id(),
        v_customer_id,
        v_id,
        v_pay_amount,
        (v_payment->>'method')::payment_method,
        coalesce(v_payment->>'ref_note', v_note),
        v_member
      );
    end if;
  end if;

  select to_jsonb(b.*) into result from bills b where b.id = v_id;
  return jsonb_build_object('bill', result, 'created', true);
end;
$$;

grant execute on function record_customer_sale(jsonb) to authenticated;
