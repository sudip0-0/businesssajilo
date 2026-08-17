-- Gated customer_balance_projections stay off the live read path.
begin;
select plan(9);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz'),
  ('22222222-2222-2222-2222-222222222222', 'Other Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner37@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'wh37@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', 'other37@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust37@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'warehouse', 'Wh', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444', 'owner', 'Other', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('c1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Traders', 500);

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

select is(
  (select balance_due from customer_balance_projections where customer_id = 'c1111111-1111-1111-1111-111111111111'),
  500::bigint,
  'projection backfills opening balance'
);

select test_set_auth('22222222-2222-2222-2222-222222222222');
select isnt_empty(
  $$select 1 from customer_balance_projections$$,
  'owner can read projections'
);

select ok(
  (create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'c1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 2, 'rate', 5000, 'discount', 0
    )),
    'payment', null
  ))->>'created')::boolean,
  'owner can create bill via create_bill'
);

select is(
  (select balance_due from customer_balance_projections where customer_id = 'c1111111-1111-1111-1111-111111111111')::bigint,
  (select balance_due from customer_balances where customer_id = 'c1111111-1111-1111-1111-111111111111')::bigint,
  'projection matches live view after bill'
);

select ok(
  (record_payment(jsonb_build_object(
    'id', '91111111-1111-1111-1111-111111111111',
    'customer_id', 'c1111111-1111-1111-1111-111111111111',
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'amount', 2500,
    'method', 'cash',
    'received_by', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  ))->>'created')::boolean,
  'owner can record payment via record_payment'
);

select is(
  (select balance_due from customer_balance_projections where customer_id = 'c1111111-1111-1111-1111-111111111111')::bigint,
  (select balance_due from customer_balances where customer_id = 'c1111111-1111-1111-1111-111111111111')::bigint,
  'projection matches live view after payment'
);

select test_set_auth('33333333-3333-3333-3333-333333333333');
select is_empty(
  $$select 1 from customer_balance_projections$$,
  'warehouse cannot read projections'
);

select test_set_auth('44444444-4444-4444-4444-444444444444');
select is_empty(
  $$select 1 from customer_balance_projections where customer_id = 'c1111111-1111-1111-1111-111111111111'$$,
  'other tenant cannot read first-business projections'
);

reset role;
select is(
  (select count(*) from customer_balance_projection_drift),
  0::bigint,
  'projection matches live customer_balances view'
);

select * from finish();
rollback;
