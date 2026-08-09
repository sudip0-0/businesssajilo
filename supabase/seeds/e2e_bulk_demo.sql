-- Bulk demo data for the E2E owner business (local / db reset only).
-- Requires supabase/seed.sql (e2e-owner@test.com) to have run first.
-- Idempotent: skips when the E2E business already has >= 50 products.
--
-- Volumes: 55 products, 55 customers, 220 bills.

do $$
declare
  v_biz uuid := 'e2e00000-0000-4000-8000-000000000010';
  v_owner_auth uuid := 'e2e00000-0000-4000-8000-000000000001';
  v_owner_member uuid := 'e2e00000-0000-4000-8000-000000000020';
  v_product_count int;
  v_i int;
  v_j int;
  v_auth uuid;
  v_member uuid;
  v_customer uuid;
  v_product uuid;
  v_product2 uuid;
  v_bill uuid;
  v_pay uuid;
  v_rate bigint;
  v_rate2 bigint;
  v_qty int;
  v_qty2 int;
  v_name text;
  v_name2 text;
  v_items jsonb;
  v_total bigint;
  v_payment jsonb;
begin
  if not exists (select 1 from businesses where id = v_biz) then
    raise exception 'E2E business % missing — run seed.sql first', v_biz;
  end if;

  select count(*)::int into v_product_count
  from products
  where business_id = v_biz;

  if v_product_count >= 50 then
    raise notice 'E2E bulk demo already seeded (% products) - skipping', v_product_count;
    return;
  end if;

  -- 55 products with enough stock for ~220 bills.
  for v_i in 1..55 loop
    v_product := ('a1000000-0000-4000-8000-' || lpad(to_hex(v_i), 12, '0'))::uuid;
    v_rate := 5000 + ((v_i - 1) % 10) * 4500; -- 50..455 NPR in paisa steps

    insert into products (
      id, business_id, name, sku, unit,
      cost_price, reference_price, low_stock_threshold, is_active
    ) values (
      v_product,
      v_biz,
      'Product ' || lpad(v_i::text, 2, '0'),
      'SKU-' || lpad(v_i::text, 3, '0'),
      'piece',
      (v_rate * 70 / 100),
      v_rate,
      10,
      true
    )
    on conflict (id) do nothing;

    insert into stock_movements (
      id, business_id, product_id, type, qty_delta, reason, created_by
    ) values (
      ('a7000000-0000-4000-8000-' || lpad(to_hex(v_i), 12, '0'))::uuid,
      v_biz,
      v_product,
      'stock_in',
      1000,
      'E2E bulk seed',
      v_owner_member
    )
    on conflict (id) do nothing;
  end loop;

  -- 55 customers (auth user + member + customers row).
  for v_i in 1..55 loop
    v_auth := ('a2000000-0000-4000-8000-' || lpad(to_hex(v_i), 12, '0'))::uuid;
    v_member := ('a3000000-0000-4000-8000-' || lpad(to_hex(v_i), 12, '0'))::uuid;
    v_customer := ('a4000000-0000-4000-8000-' || lpad(to_hex(v_i), 12, '0'))::uuid;

    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new,
      email_change, email_change_token_current, phone_change, phone_change_token
    ) values (
      v_auth,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'e2e-customer-' || v_i || '@test.com',
      crypt('password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      now(),
      now(),
      '', '', '', '', '', '', ''
    )
    on conflict (id) do nothing;

    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    ) values (
      v_auth,
      v_auth,
      jsonb_build_object(
        'sub', v_auth::text,
        'email', 'e2e-customer-' || v_i || '@test.com'
      ),
      'email',
      v_auth::text,
      now(),
      now(),
      now()
    )
    on conflict do nothing;

    insert into members (
      id, business_id, auth_user_id, role, display_name, phone, is_active
    ) values (
      v_member,
      v_biz,
      v_auth,
      'customer',
      'Customer ' || lpad(v_i::text, 2, '0'),
      '+97798100' || lpad(v_i::text, 5, '0'),
      true
    )
    on conflict (id) do nothing;

    insert into customers (
      id, business_id, member_id, shop_name, contact_name, phone, opening_balance
    ) values (
      v_customer,
      v_biz,
      v_member,
      'Shop ' || lpad(v_i::text, 2, '0'),
      'Contact ' || lpad(v_i::text, 2, '0'),
      '+97798100' || lpad(v_i::text, 5, '0'),
      0
    )
    on conflict (id) do nothing;
  end loop;

  -- Act as E2E owner for create_bill (checks current_role_name via auth.uid()).
  perform set_config('request.jwt.claim.sub', v_owner_auth::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  for v_i in 1..220 loop
    v_bill := ('a5000000-0000-4000-8000-' || lpad(to_hex(v_i), 12, '0'))::uuid;
    v_pay := ('a6000000-0000-4000-8000-' || lpad(to_hex(v_i), 12, '0'))::uuid;

    v_j := ((v_i - 1) % 55) + 1;
    v_customer := ('a4000000-0000-4000-8000-' || lpad(to_hex(v_j), 12, '0'))::uuid;

    v_j := ((v_i - 1) % 55) + 1;
    v_product := ('a1000000-0000-4000-8000-' || lpad(to_hex(v_j), 12, '0'))::uuid;
    select name, reference_price into v_name, v_rate
    from products where id = v_product;

    v_qty := 1 + ((v_i - 1) % 3);
    v_items := jsonb_build_array(
      jsonb_build_object(
        'product_id', v_product,
        'name_snapshot', v_name,
        'qty', v_qty,
        'rate', v_rate,
        'discount', 0
      )
    );
    v_total := v_qty * v_rate;

    -- Every third bill gets a second line item.
    if v_i % 3 = 0 then
      v_j := (v_i % 55) + 1;
      v_product2 := ('a1000000-0000-4000-8000-' || lpad(to_hex(v_j), 12, '0'))::uuid;
      select name, reference_price into v_name2, v_rate2
      from products where id = v_product2;
      v_qty2 := 1 + (v_i % 2);
      v_items := v_items || jsonb_build_array(
        jsonb_build_object(
          'product_id', v_product2,
          'name_snapshot', v_name2,
          'qty', v_qty2,
          'rate', v_rate2,
          'discount', 0
        )
      );
      v_total := v_total + v_qty2 * v_rate2;
    end if;

    -- Alternate paid (cash) vs due.
    if v_i % 2 = 0 then
      v_payment := jsonb_build_object(
        'id', v_pay,
        'amount', v_total,
        'method', 'cash',
        'ref_note', 'E2E bulk seed'
      );
    else
      v_payment := null;
    end if;

    perform create_bill(
      jsonb_build_object(
        'id', v_bill,
        'customer_id', v_customer,
        'discount', 0,
        'items', v_items,
        'payment', v_payment
      )
    );
  end loop;

  raise notice 'E2E bulk demo seeded: 55 products, 55 customers, 220 bills';
end;
$$;
