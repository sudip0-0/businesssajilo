-- Phase 19: security & integrity hotfix
-- - Order-scope order-chat-images storage policies (customers cannot read
--   other customers' chat images in the same tenant).
-- - Owner/staff/customer DELETE so orphan upload cleanup works.
-- - Index payments(bill_id) for record_payment bill-status refresh.
-- - record_payment always attributes received_by to the calling member.
-- - Negative-stock crossing notifies owners (alert only; no CHECK / block).

-- ---------------------------------------------------------------------------
-- 1. Chat storage: order-scoped policies
-- ---------------------------------------------------------------------------

drop policy if exists "chat participants read images" on storage.objects;
drop policy if exists "chat participants upload images" on storage.objects;

-- Staff (owner/sales) read any chat image under their business folder.
create policy "staff read chat images" on storage.objects
  for select using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() in ('owner', 'sales')
  );

-- Customers read only images under their own orders.
create policy "customer read own order chat images" on storage.objects
  for select using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() = 'customer'
    and (storage.foldername(name))[2] in (
      select id::text from orders where customer_id = own_customer_id()
    )
  );

-- Staff upload under any order in the business.
create policy "staff upload chat images" on storage.objects
  for insert with check (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() in ('owner', 'sales')
    and (storage.foldername(name))[2] in (
      select id::text from orders where business_id = current_business_id()
    )
  );

-- Customers upload only under their own orders.
create policy "customer upload own order chat images" on storage.objects
  for insert with check (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() = 'customer'
    and (storage.foldername(name))[2] in (
      select id::text from orders where customer_id = own_customer_id()
    )
  );

-- DELETE for uploaders so orphan cleanup after a failed message insert works.
-- Owner/sales: any object in the business folder.
-- Customer: only objects under their own orders.
create policy "staff delete chat images" on storage.objects
  for delete using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() in ('owner', 'sales')
  );

create policy "customer delete own order chat images" on storage.objects
  for delete using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = current_business_id()::text
    and current_role_name() = 'customer'
    and (storage.foldername(name))[2] in (
      select id::text from orders where customer_id = own_customer_id()
    )
  );

-- ---------------------------------------------------------------------------
-- 2. payments(bill_id) index
-- ---------------------------------------------------------------------------

create index if not exists payments_bill_id_idx on payments(bill_id);

-- ---------------------------------------------------------------------------
-- 3. record_payment: always use current_member_id() for received_by
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
  v_method payment_method;
  v_ref_note text;
  v_member uuid;
  existing jsonb;
  result jsonb;
  bill_row bills%rowtype;
  paid_sum bigint;
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

  if v_customer_id is null then
    raise exception 'customer_id required';
  end if;
  if v_amount is null or v_amount <= 0 then
    raise exception 'amount must be positive';
  end if;
  if v_amount > 100000000000 then -- 1e9 NPR in paisa
    raise exception 'amount out of range';
  end if;

  if not exists (
    select 1 from customers
    where id = v_customer_id and business_id = current_business_id()
  ) then
    raise exception 'customer not found';
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
    v_member  -- never trust client-supplied received_by
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

grant execute on function record_payment(jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Negative-stock alert (no blocking)
-- When stock_cached crosses from >= 0 to < 0, notify active owners.
-- ---------------------------------------------------------------------------

create or replace function recalc_product_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_stock int;
  old_stock int;
  product_row products%rowtype;
  member_row record;
begin
  perform 1 from products where id = NEW.product_id for update;

  select stock_cached into old_stock
  from products where id = NEW.product_id;

  select coalesce(sum(qty_delta), 0)::int into new_stock
  from stock_movements
  where product_id = NEW.product_id;

  update products
  set stock_cached = new_stock,
      updated_at = now()
  where id = NEW.product_id;

  -- Alert owners the first time stock goes negative (crossing only).
  if new_stock < 0 and coalesce(old_stock, 0) >= 0 then
    select * into product_row from products where id = NEW.product_id;
    for member_row in
      select id from members
      where business_id = product_row.business_id
        and is_active
        and role = 'owner'
    loop
      perform insert_notification(
        product_row.business_id,
        member_row.id,
        'negative_stock',
        jsonb_build_object(
          'product_id', product_row.id,
          'name', product_row.name,
          'stock', new_stock
        )
      );
    end loop;
  end if;

  return NEW;
end;
$$;
