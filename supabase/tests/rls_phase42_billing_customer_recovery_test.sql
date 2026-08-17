-- Ambiguous names must not remap; missing identity must not create a customer;
-- stale product IDs become snapshot-only; tenant isolation is preserved.
begin;
select plan(13);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz'),
  ('99999999-9999-9999-9999-999999999999', 'Other Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('66666666-6666-6666-6666-666666666666', 'other@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('77777777-7777-7777-7777-777777777777', 'cust2@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('88888888-8888-8888-8888-888888888888', 'dup1@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('99999999-aaaa-aaaa-aaaa-999999999999', 'dup2@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '99999999-9999-9999-9999-999999999999', '66666666-6666-6666-6666-666666666666', 'owner', 'Other Owner', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '99999999-9999-9999-9999-999999999999', '77777777-7777-7777-7777-777777777777', 'customer', 'Other Cust', true),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', '88888888-8888-8888-8888-888888888888', 'customer', 'Dup 1', true),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '11111111-1111-1111-1111-111111111111', '99999999-aaaa-aaaa-aaaa-999999999999', 'customer', 'Dup 2', true);

insert into customers (id, business_id, member_id, shop_name, phone, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', '+9779811111111', 0),
  ('e9999999-9999-9999-9999-999999999999', '99999999-9999-9999-9999-999999999999', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Foreign Shop', '+9779800000000', 0),
  ('e2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Common Shop', '+9779822222222', 0),
  ('e3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Common Shop', '+9779833333333', 0);

insert into products (id, business_id, name, unit, reference_price) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select test_set_auth('22222222-2222-2222-2222-222222222222');

select lives_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    ))
  ))$$,
  'create_bill accepts a live customer id in the current business'
);

select throws_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f2222222-2222-2222-2222-222222222222',
    'customer_id', 'c0c0c0c0-c0c0-4000-8000-c0c0c0c0c0c0',
    'customer_shop_name', 'Common Shop',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    ))
  ))$$,
  'P0001',
  'ambiguous customer name',
  'ambiguous shop name does not map to an arbitrary customer'
);

select throws_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f3333333-3333-3333-3333-333333333333',
    'customer_id', 'c1c1c1c1-c1c1-4000-8000-c1c1c1c1c1c1',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    ))
  ))$$,
  'P0001',
  'customer not found',
  'stale customer id without identity snapshot does not create a customer'
);

select lives_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f4444444-4444-4444-4444-444444444444',
    'customer_id', 'c2c2c2c2-c2c2-4000-8000-c2c2c2c2c2c2',
    'customer_shop_name', 'Brand New Shop',
    'customer_phone', '+9779844444444',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'deadbeef-dead-4000-8000-deadbeefdead',
      'name_snapshot', 'Old Cola', 'qty', 1, 'rate', 2500, 'discount', 0
    ))
  ))$$,
  'stale product id is recovered as a snapshot-only line'
);

select is(
  (select product_id from bill_items where bill_id = 'f4444444-4444-4444-4444-444444444444'),
  null,
  'stale product id is stored as null, not remapped by name'
);

select is(
  (select name_snapshot from bill_items where bill_id = 'f4444444-4444-4444-4444-444444444444'),
  'Old Cola',
  'snapshot name is preserved when the product id is stale'
);

select is(
  (select shop_name from customers where id = 'c2c2c2c2-c2c2-4000-8000-c2c2c2c2c2c2'),
  'Brand New Shop',
  'unique identity snapshot creates a portal-disabled customer with the requested id'
);

select is(
  (select is_active from members m
     join customers c on c.member_id = m.id
    where c.id = 'c2c2c2c2-c2c2-4000-8000-c2c2c2c2c2c2'),
  false,
  'recreated customer member is portal-disabled'
);

select lives_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f5555555-5555-5555-5555-555555555555',
    'customer_id', 'e9999999-9999-9999-9999-999999999999',
    'customer_shop_name', 'Ram Store',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    ))
  ))$$,
  'other-tenant customer id remaps by unique local shop name'
);

select is(
  (select customer_id from bills where id = 'f5555555-5555-5555-5555-555555555555'),
  'e1111111-1111-1111-1111-111111111111'::uuid,
  'remap stays inside the current business and does not steal another tenant row'
);

reset role;

select is(
  (select business_id from customers where id = 'e9999999-9999-9999-9999-999999999999'),
  '99999999-9999-9999-9999-999999999999'::uuid,
  'other tenant customer row is unchanged'
);

select test_set_auth('22222222-2222-2222-2222-222222222222');

select lives_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f4444444-4444-4444-4444-444444444444',
    'customer_id', 'c2c2c2c2-c2c2-4000-8000-c2c2c2c2c2c2',
    'customer_shop_name', 'Brand New Shop',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'deadbeef-dead-4000-8000-deadbeefdead',
      'name_snapshot', 'Old Cola', 'qty', 1, 'rate', 2500, 'discount', 0
    ))
  ))$$,
  'create_bill retry after insert is idempotent'
);

select is(
  (select count(*)::int from bills
    where id = 'f4444444-4444-4444-4444-444444444444'),
  1,
  'idempotent retry does not insert a duplicate bill'
);

select * from finish();
rollback;
