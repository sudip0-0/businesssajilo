-- RLS tests for Phase 3 customers & ledger.
begin;
select plan(11);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'sales@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', 'wh@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'sales', 'Sales', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'warehouse', 'WH', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', 10000);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Owner updates customer profile.
select test_set_auth('22222222-2222-2222-2222-222222222222');

update customers set shop_name = 'Ram Kirana' where id = 'e1111111-1111-1111-1111-111111111111';
select is(
  (select shop_name from customers where id = 'e1111111-1111-1111-1111-111111111111'),
  'Ram Kirana',
  'owner updates customer profile'
);

-- Owner records payment via RPC.
select record_payment(jsonb_build_object(
  'id', 'f1111111-1111-1111-1111-111111111111',
  'customer_id', 'e1111111-1111-1111-1111-111111111111',
  'bill_id', null,
  'amount', 2500,
  'method', 'cash',
  'received_by', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
));

select is(
  (select balance_due::bigint from customer_balances where customer_id = 'e1111111-1111-1111-1111-111111111111'),
  7500::bigint,
  'customer balance after payment'
);

-- Sales reads customers and balances.
select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select count(*)::int from customer_balances),
  1,
  'sales reads customer balances'
);

-- Sales records payment via RPC.
select record_payment(jsonb_build_object(
  'id', 'f2222222-2222-2222-2222-222222222222',
  'customer_id', 'e1111111-1111-1111-1111-111111111111',
  'bill_id', null,
  'amount', 1500,
  'method', 'wallet',
  'received_by', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
));

select is(
  (select balance_due::bigint from customer_balances where customer_id = 'e1111111-1111-1111-1111-111111111111'),
  6000::bigint,
  'sales payment reduces balance'
);

-- Sales cannot update customer.
update customers set shop_name = 'Hacked' where id = 'e1111111-1111-1111-1111-111111111111';
select is(
  (select shop_name from customers where id = 'e1111111-1111-1111-1111-111111111111'),
  'Ram Kirana',
  'sales cannot update customer'
);

-- Warehouse cannot read customers.
select test_set_auth('44444444-4444-4444-4444-444444444444');

select is(
  (select count(*)::int from customers),
  0,
  'warehouse cannot read customers'
);

-- Warehouse cannot insert payments.
select throws_ok(
  $$insert into payments (business_id, customer_id, amount, method, received_by)
    values ('11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 100, 'cash', 'cccccccc-cccc-cccc-cccc-cccccccccccc')$$,
  '42501',
  null,
  'warehouse cannot insert payments'
);

-- Customer reads own profile and payments.
select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select shop_name from customers),
  'Ram Kirana',
  'customer reads own profile'
);

select is(
  (select count(*)::int from payments),
  2,
  'customer reads own payments'
);

-- Customer cannot insert payments.
select throws_ok(
  $$insert into payments (business_id, customer_id, amount, method, received_by)
    values ('11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 100, 'cash', 'dddddddd-dddd-dddd-dddd-dddddddddddd')$$,
  '42501',
  null,
  'customer cannot insert payments'
);

-- Payments are append-only.
select test_set_auth('22222222-2222-2222-2222-222222222222');

update payments set amount = 1 where id = 'f1111111-1111-1111-1111-111111111111';
select is(
  (select amount from payments where id = 'f1111111-1111-1111-1111-111111111111'),
  2500::bigint,
  'payments cannot be updated'
);

select * from finish();
rollback;
