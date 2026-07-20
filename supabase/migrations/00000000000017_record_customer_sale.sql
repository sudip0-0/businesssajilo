-- Amount-only customer sales (no product lines).
-- Used by the Record sale sheet on customer detail.

alter table bill_items
  alter column product_id drop not null;

create or replace function guard_bill_item_refs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  bill_biz uuid;
begin
  select business_id into bill_biz from bills where id = NEW.bill_id;
  -- Manual / amount-only sale lines have no product.
  if NEW.product_id is null then
    return NEW;
  end if;
  if not exists (
    select 1 from products where id = NEW.product_id and business_id = bill_biz
  ) then
    raise exception 'product does not belong to this business';
  end if;
  return NEW;
end;
$$;

create or replace function deduct_stock_for_bill_item()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  bill_row bills%rowtype;
begin
  -- Amount-only lines never touch stock.
  if NEW.product_id is null then
    return NEW;
  end if;

  select * into bill_row from bills where id = NEW.bill_id;

  -- Order-based bills deduct on dispatch; only counter bills deduct here.
  if bill_row.order_id is not null then
    return NEW;
  end if;

  if exists (
    select 1 from stock_movements
    where ref_bill_id = NEW.bill_id and product_id = NEW.product_id and type = 'dispatch'
  ) then
    return NEW;
  end if;

  insert into stock_movements (
    business_id, product_id, type, qty_delta, reason, ref_bill_id, created_by
  ) values (
    bill_row.business_id,
    NEW.product_id,
    'dispatch',
    -NEW.qty,
    'Counter sale ' || bill_row.bill_no,
    NEW.bill_id,
    bill_row.created_by
  );

  return NEW;
end;
$$;

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

  -- Idempotency: replays return the existing bill.
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
    items_total, discount, grand_total, status, created_by
  ) values (
    v_id, current_business_id(), v_customer_id, null, p->>'device_prefix',
    v_amount, 0, v_amount, v_status, v_member
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
