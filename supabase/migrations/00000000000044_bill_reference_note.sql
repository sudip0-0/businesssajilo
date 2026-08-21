alter table bills add column reference_note text;

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
  v_reference_note text;
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
  v_id := coalesce(uuid_from_json(p->>'id'), gen_random_uuid());

  select to_jsonb(b.*) into existing
  from bills b
  where b.id = v_id and b.business_id = current_business_id();
  if existing is not null then
    return jsonb_build_object('bill', existing, 'created', false);
  end if;

  v_customer_id := resolve_billing_customer(p);
  v_order_id := uuid_from_json(p->>'order_id');
  v_discount := coalesce((p->>'discount')::bigint, 0);
  v_device_prefix := p->>'device_prefix';
  v_payment := p->'payment';
  v_guest_name := nullif(btrim(coalesce(p->>'guest_name', '')), '');
  v_reference_note := nullif(btrim(coalesce(p->>'reference_note', '')), '');
  v_created_at := occurred_at_from_payload(p);

  if v_role = 'warehouse' and v_payment is not null then
    raise exception 'warehouse cannot record payment with bill';
  end if;

  if v_payment is not null and v_payment != 'null'::jsonb then
    v_reference_note := null;
  end if;

  if v_customer_id is null then
    v_status := 'paid';
  else
    v_status := 'due';
    v_guest_name := null;
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
    reference_note, created_at
  ) values (
    v_id, current_business_id(), v_customer_id, v_order_id, v_device_prefix,
    v_items_total, v_discount, v_grand_total, v_status, v_member, v_guest_name,
    v_reference_note, v_created_at
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
      uuid_from_json(item->>'product_id'),
      coalesce(item->>'name_snapshot', ''),
      v_qty,
      v_rate,
      v_item_discount,
      v_qty * v_rate - v_item_discount
    );
  end loop;

  if v_payment is not null and v_payment != 'null'::jsonb then
    v_pay_amount := coalesce((v_payment->>'amount')::bigint, 0);
    if v_pay_amount > 0 then
      if v_customer_id is null then
        raise exception 'payment requires a customer';
      end if;
      v_pay_id := coalesce(uuid_from_json(v_payment->>'id'), gen_random_uuid());
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
