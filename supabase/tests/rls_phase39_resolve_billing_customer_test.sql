-- Stale local customer ids remap by shop name / phone onto the live row.
begin;
select plan(5);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true);

insert into customers (id, business_id, member_id, shop_name, phone, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', '+9779811111111', 0);

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
    'customer_id', 'c0c0c0c0-c0c0-4000-8000-c0c0c0c0c0c0',
    'customer_shop_name', 'Ram Store',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    ))
  ))$$,
  'create_bill remaps stale customer_id by shop name'
);

select is(
  (select customer_id from bills where id = 'f1111111-1111-1111-1111-111111111111'),
  'e1111111-1111-1111-1111-111111111111'::uuid,
  'remapped bill uses the live customer id'
);

select lives_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f2222222-2222-2222-2222-222222222222',
    'customer_id', 'c1c1c1c1-c1c1-4000-8000-c1c1c1c1c1c1',
    'customer_phone', '+9779811111111',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', '',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 2500, 'discount', 0
    ))
  ))$$,
  'create_bill remaps by phone and treats empty product_id as null'
);

select lives_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f3333333-3333-3333-3333-333333333333',
    'customer_id', 'c2c2c2c2-c2c2-4000-8000-c2c2c2c2c2c2',
    'customer_shop_name', 'Brand New Shop',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    ))
  ))$$,
  'create_bill recreates a missing customer from the shop snapshot'
);

select is(
  (select shop_name from customers where id = 'c2c2c2c2-c2c2-4000-8000-c2c2c2c2c2c2'),
  'Brand New Shop',
  'ensured customer keeps the requested id and shop name'
);

select * from finish();
rollback;
