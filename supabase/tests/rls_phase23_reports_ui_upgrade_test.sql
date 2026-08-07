-- report_dues_aging includes phone.
begin;
select plan(2);

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
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', '9800000000', 0);

insert into products (id, business_id, name, unit, cost_price, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola', 'piece', 3000, 5000, 10);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select test_set_auth('22222222-2222-2222-2222-222222222222');

select create_bill(jsonb_build_object(
  'id', 'f1111111-1111-1111-1111-111111111111',
  'customer_id', 'e1111111-1111-1111-1111-111111111111',
  'discount', 0,
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', 'b1111111-1111-1111-1111-111111111111',
    'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
  )),
  'payment', null
));

select is(
  (select report_dues_aging()->'customers'->0->>'phone'),
  '9800000000',
  'dues aging RPC includes customer phone'
);

select is(
  (select report_dues_aging()->'customers'->0->>'shop_name'),
  'Ram Store',
  'dues aging RPC still returns shop name'
);

select * from finish();
rollback;
