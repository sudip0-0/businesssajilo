-- RLS/behavior tests for migration 46: record_payment delegates bill status
-- recompute to the locking refresh_bill_status_for() helper.
begin;
select plan(7);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz 46');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner46@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust46@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner46', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust46', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance, updated_at) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store 46', 0, now());

insert into products (id, business_id, name, unit, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola46', 'piece', 5000, 20);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select test_set_auth('22222222-2222-2222-2222-222222222222');

-- A due bill of 4000.
select ok(
  (create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola46', 'qty', 1, 'rate', 4000, 'discount', 0
    )),
    'payment', null
  ))->>'created')::boolean,
  'due bill created'
);

select is(
  (select status from bills where id = 'f1111111-1111-1111-1111-111111111111')::text,
  'due',
  'bill starts due'
);

-- Partial payment -> partial.
select ok(
  (record_payment(jsonb_build_object(
    'id', '91111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'amount', 1500,
    'method', 'cash'
  ))->>'created')::boolean,
  'partial payment records'
);

select is(
  (select status from bills where id = 'f1111111-1111-1111-1111-111111111111')::text,
  'partial',
  'status partial after partial payment (via locking helper)'
);

-- Paying the rest -> paid.
select ok(
  (record_payment(jsonb_build_object(
    'id', '92222222-2222-2222-2222-222222222222',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'amount', 2500,
    'method', 'cash'
  ))->>'created')::boolean,
  'final payment records'
);

select is(
  (select status from bills where id = 'f1111111-1111-1111-1111-111111111111')::text,
  'paid',
  'status paid after full payment'
);

-- Idempotent replay still returns created=false and does not double-pay.
select is(
  (record_payment(jsonb_build_object(
    'id', '92222222-2222-2222-2222-222222222222',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'amount', 2500,
    'method', 'cash'
  ))->>'created')::boolean,
  false,
  'replay returns existing payment'
);

select * from finish();
rollback;
