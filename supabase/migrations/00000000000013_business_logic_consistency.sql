-- Phase 13: business-logic consistency fixes
-- - Prorate credit-note line discounts on partial returns
-- - Settle bill status from payments + credit notes
-- - Lock opening balance when credit notes exist
-- - create_bill: accept payment id; derive customer-bill status from payments

-- ---------------------------------------------------------------------------
-- 1. Shared bill-status refresh (payments + credit notes vs grand_total).
-- ---------------------------------------------------------------------------

create or replace function refresh_bill_status_for(p_bill_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  bill_row bills%rowtype;
  paid_sum bigint;
  credited_sum bigint;
  new_status bill_status;
begin
  if p_bill_id is null then
    return;
  end if;

  select * into bill_row from bills where id = p_bill_id for update;
  if bill_row.id is null then
    return;
  end if;

  -- Walk-in bills stay paid (no customer ledger).
  if bill_row.customer_id is null then
    if bill_row.status is distinct from 'paid' then
      update bills set status = 'paid' where id = p_bill_id;
    end if;
    return;
  end if;

  select coalesce(sum(amount), 0) into paid_sum
  from payments where bill_id = p_bill_id;

  select coalesce(sum(grand_total), 0) into credited_sum
  from credit_notes where bill_id = p_bill_id;

  if paid_sum + credited_sum >= bill_row.grand_total then
    new_status := 'paid';
  elsif paid_sum > 0 or credited_sum > 0 then
    new_status := 'partial';
  else
    new_status := 'due';
  end if;

  if new_status is distinct from bill_row.status then
    update bills set status = new_status where id = p_bill_id;
  end if;
end;
$$;

create or replace function refresh_bill_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform refresh_bill_status_for(NEW.bill_id);
  return NEW;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Opening balance immutable once bills, payments, or credit notes exist.
-- ---------------------------------------------------------------------------

create or replace function guard_opening_balance()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.opening_balance is distinct from OLD.opening_balance then
    if exists (select 1 from bills where customer_id = NEW.id)
       or exists (select 1 from payments where customer_id = NEW.id)
       or exists (select 1 from credit_notes where customer_id = NEW.id) then
      raise exception 'opening balance cannot be changed once the customer has bills, payments, or credit notes';
    end if;
  end if;
  return NEW;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. create_credit_note: prorate line discount; refresh bill status.
--    discount = floor(bill_item.discount * qty_returned / bill_item.qty)
--    Bill-level discount is not reversed (v_discount stays 0).
-- ---------------------------------------------------------------------------

create or replace function create_credit_note(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_bill_id uuid;
  v_customer_id uuid;
  v_reason text;
  v_restock boolean;
  v_member uuid;
  v_items_total bigint := 0;
  v_discount bigint := 0;
  v_grand_total bigint := 0;
  item jsonb;
  v_bill_item_id uuid;
  v_product_id uuid;
  v_name text;
  v_qty int;
  v_rate bigint;
  v_item_discount bigint;
  v_orig_discount bigint;
  v_line bigint;
  v_bill_qty int;
  v_returned int;
  bill_row bills%rowtype;
  existing jsonb;
  v_note_id uuid;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_member := current_member_id();
  v_id := coalesce((p->>'id')::uuid, gen_random_uuid());

  select to_jsonb(cn.*) into existing
  from credit_notes cn
  where cn.id = v_id and cn.business_id = current_business_id();
  if existing is not null then
    return jsonb_build_object('credit_note', existing, 'created', false);
  end if;

  v_bill_id := (p->>'bill_id')::uuid;
  v_reason := nullif(trim(p->>'reason'), '');
  v_restock := coalesce((p->>'restock')::boolean, true);

  select * into bill_row
  from bills
  where id = v_bill_id and business_id = current_business_id();
  if not found then
    raise exception 'bill not found';
  end if;
  if bill_row.customer_id is null then
    raise exception 'walk-in bills cannot be returned';
  end if;
  v_customer_id := bill_row.customer_id;

  if p->'items' is null or jsonb_array_length(p->'items') = 0 then
    raise exception 'credit note must have at least one item';
  end if;

  for item in select * from jsonb_array_elements(p->'items')
  loop
    v_bill_item_id := (item->>'bill_item_id')::uuid;
    v_qty := (item->>'qty_returned')::int;
    if v_qty is null or v_qty <= 0 then
      raise exception 'qty must be positive';
    end if;
    select bi.qty, bi.product_id, bi.name_snapshot, bi.rate, bi.discount
      into v_bill_qty, v_product_id, v_name, v_rate, v_orig_discount
    from bill_items bi
    where bi.id = v_bill_item_id and bi.bill_id = v_bill_id;
    if not found then
      raise exception 'bill item not found';
    end if;
    select coalesce(sum(cni.qty_returned), 0) into v_returned
    from credit_note_items cni
    join credit_notes cn on cn.id = cni.credit_note_id
    where cni.bill_item_id = v_bill_item_id;
    if v_returned + v_qty > v_bill_qty then
      raise exception 'return qty exceeds remaining';
    end if;
    -- Prorate original line discount by returned qty (floor paisa).
    v_item_discount := (v_orig_discount * v_qty) / v_bill_qty;
    if v_item_discount < 0 then
      v_item_discount := 0;
    end if;
    if v_item_discount > v_qty * v_rate then
      v_item_discount := v_qty * v_rate;
    end if;
    v_line := v_qty * v_rate - v_item_discount;
    v_items_total := v_items_total + v_line;
  end loop;

  v_grand_total := v_items_total - v_discount;
  if v_grand_total < 0 then
    raise exception 'grand total must be non-negative';
  end if;

  insert into credit_notes (
    id, bill_id, customer_id, items_total, discount, grand_total,
    reason, restock, created_by
  ) values (
    v_id, v_bill_id, v_customer_id, v_items_total, v_discount, v_grand_total,
    v_reason, v_restock, v_member
  ) returning id into v_note_id;

  for item in select * from jsonb_array_elements(p->'items')
  loop
    v_bill_item_id := (item->>'bill_item_id')::uuid;
    v_qty := (item->>'qty_returned')::int;
    select bi.product_id, bi.name_snapshot, bi.rate, bi.discount, bi.qty
      into v_product_id, v_name, v_rate, v_orig_discount, v_bill_qty
    from bill_items bi
    where bi.id = v_bill_item_id;
    v_item_discount := (v_orig_discount * v_qty) / v_bill_qty;
    if v_item_discount < 0 then
      v_item_discount := 0;
    end if;
    if v_item_discount > v_qty * v_rate then
      v_item_discount := v_qty * v_rate;
    end if;
    v_line := v_qty * v_rate - v_item_discount;
    insert into credit_note_items (
      credit_note_id, bill_item_id, product_id, name_snapshot,
      qty_returned, rate, discount, line_total
    ) values (
      v_note_id, v_bill_item_id, v_product_id, v_name,
      v_qty, v_rate, v_item_discount, v_line
    );
    if v_restock then
      insert into stock_movements (
        business_id, product_id, type, qty_delta, reason,
        ref_bill_id, ref_credit_note_id, created_by
      ) values (
        current_business_id(), v_product_id, 'return', v_qty,
        coalesce(v_reason, 'Sales return'),
        v_bill_id, v_note_id, v_member
      );
    end if;
  end loop;

  perform refresh_bill_status_for(v_bill_id);

  return jsonb_build_object(
    'credit_note', (select to_jsonb(cn.*) from credit_notes cn where cn.id = v_note_id),
    'created', true
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. create_bill: payment id support; derive status for customer bills.
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

  -- Idempotency: replays (e.g. offline sync retries) return the existing bill.
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

  -- Customer bills start as due; status is derived after payment insert.
  -- Walk-in bills are forced paid below.
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
    if order_row.status != 'dispatched' then
      raise exception 'order must be dispatched before billing';
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

  -- Customer-less (walk-in) bills are settled at the counter.
  if v_customer_id is null then
    update bills set status = 'paid' where id = v_id and status != 'paid';
  else
    -- Derive from payments (and any credit notes) — never trust client status.
    perform refresh_bill_status_for(v_id);
  end if;

  if v_order_id is not null then
    update orders set status = 'billed' where id = v_order_id;
  end if;

  select to_jsonb(b.*) into result from bills b where b.id = v_id;
  return jsonb_build_object('bill', result, 'created', true);
end;
$$;
