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
  v_locked uuid[];
  existing jsonb;
  result jsonb;
  bill_row bills%rowtype;
  open_bill record;
  first_payment jsonb;
begin
  if coalesce(current_role_name(), '') not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;

  v_member := current_member_id();
  v_id := coalesce((p->>'id')::uuid, gen_random_uuid());
  perform pg_advisory_xact_lock(hashtextextended('record_payment:' || v_id::text, 0));

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
    select array_agg(locked.id) into v_locked
    from (
      select b.id from bills b
      where b.business_id = current_business_id()
        and b.customer_id = v_customer_id
        and b.status in ('due', 'partial')
      order by b.created_at, b.id
      for update of b
    ) locked;

    for open_bill in
      select b.id, b.grand_total
        - coalesce((select sum(pay.amount) from payments pay where pay.bill_id = b.id), 0)
        - coalesce((select sum(cn.grand_total) from credit_notes cn where cn.bill_id = b.id), 0) as due_left
      from bills b
      where b.id = any(v_locked)
        and b.business_id = current_business_id()
      order by b.created_at, b.id
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
        current_business_id(), v_customer_id, open_bill.id, v_chunk, v_method,
        nullif(trim(coalesce(v_ref_note, '')), ''), v_member
      );
      perform refresh_bill_status_for(open_bill.id);
      if first_payment is null then
        select to_jsonb(pay.*) into first_payment from payments pay where pay.id = v_id;
      end if;
      v_remaining := v_remaining - v_chunk;
    end loop;

    if v_remaining > 0 then
      insert into payments (
        id, business_id, customer_id, bill_id, amount, method, ref_note, received_by
      ) values (
        case when first_payment is null then v_id else gen_random_uuid() end,
        current_business_id(), v_customer_id, null, v_remaining, v_method,
        nullif(trim(coalesce(v_ref_note, '')), ''), v_member
      );
      if first_payment is null then
        select to_jsonb(pay.*) into first_payment from payments pay where pay.id = v_id;
      end if;
    end if;
    if first_payment is null then
      raise exception 'nothing to allocate';
    end if;
    return jsonb_build_object('payment', first_payment, 'created', true);
  end if;

  if v_bill_id is not null then
    select * into bill_row from bills
    where id = v_bill_id and business_id = current_business_id()
    for update;
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
    v_id, current_business_id(), v_customer_id, v_bill_id, v_amount, v_method,
    nullif(trim(coalesce(v_ref_note, '')), ''), v_member
  );
  perform refresh_bill_status_for(v_bill_id);
  select to_jsonb(pay.*) into result from payments pay where pay.id = v_id;
  return jsonb_build_object('payment', result, 'created', true);
end;
$$;
