-- v1.2 QoL: last_quoted_rate, oldest-first allocation, quote expiry, nudges.
begin;
select plan(13);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance, updated_at) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', 0, now());

insert into products (id, business_id, name, unit, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000, 20);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select test_set_auth('22222222-2222-2222-2222-222222222222');

select ok(
  exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'quotes'
      and column_name = 'expires_at'
  ),
  'quotes has expires_at'
);

select ok(
  exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'members'
      and column_name = 'notification_prefs'
  ),
  'members has notification_prefs'
);

-- Two due bills for oldest-first allocation.
select ok(
  (create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 4000, 'discount', 0
    )),
    'payment', null
  ))->>'created')::boolean,
  'first due bill created'
);

select ok(
  (create_bill(jsonb_build_object(
    'id', 'f2222222-2222-2222-2222-222222222222',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 6000, 'discount', 0
    )),
    'payment', null
  ))->>'created')::boolean,
  'second due bill created'
);

select ok(
  (record_payment(jsonb_build_object(
    'id', '91111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'amount', 5000,
    'method', 'cash',
    'allocate', 'oldest_first'
  ))->>'created')::boolean,
  'oldest-first payment records'
);

select is(
  (select status from bills where id = 'f1111111-1111-1111-1111-111111111111')::text,
  'paid',
  'oldest bill is fully paid by 5000 against 4000+remainder'
);

select is(
  (select status from bills where id = 'f2222222-2222-2222-2222-222222222222')::text,
  'partial',
  'newer bill receives the leftover 1000'
);

select lives_ok(
  $$select process_operational_nudges()$$,
  'owner can run operational nudges'
);

select ok(
  (select notification_prefs -> 'muted' @> '["dues_reminder"]'::jsonb
     from members
     where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'owner default prefs mute dues_reminder'
);

select is(
  insert_notification(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'dues_reminder',
    jsonb_build_object(
      'customer_id', 'e1111111-1111-1111-1111-111111111111',
      'shop_name', 'Ram Store',
      'balance_due', 5000
    )
  ),
  null::uuid,
  'insert_notification skips muted dues_reminder'
);

select is(
  (select count(*)::int from notifications where type = 'dues_reminder'),
  0,
  'muted dues reminders are not inserted by nudges'
);

select lives_ok(
  $$select update_own_notification_prefs('[]'::jsonb)$$,
  'owner can unmute dues reminders'
);

select ok(
  insert_notification(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'dues_reminder',
    jsonb_build_object(
      'customer_id', 'e1111111-1111-1111-1111-111111111111',
      'shop_name', 'Ram Store',
      'balance_due', 5000
    )
  ) is not null,
  'insert_notification allows dues_reminder when unmuted'
);

select * from finish();
rollback;
