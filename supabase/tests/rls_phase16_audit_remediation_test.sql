-- Phase 16 audit remediation: RPC-only bill/payment writes + customer_balances.updated_at.
begin;
select plan(6);

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
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', 0, now() - interval '1 day');

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

-- Direct inserts denied for owner (RPC-only).
select throws_ok(
  $$insert into bills (business_id, customer_id, items_total, discount, grand_total, status, created_by)
    values ('11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 1000, 0, 1000, 'due', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501',
  null,
  'owner cannot direct-insert bills'
);

select throws_ok(
  $$insert into payments (business_id, customer_id, amount, method, received_by)
    values ('11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 100, 'cash', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501',
  null,
  'owner cannot direct-insert payments'
);

-- customer_balances exposes updated_at for offline delta sync.
select ok(
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'customer_balances'
      and column_name = 'updated_at'
  ),
  'customer_balances has updated_at column'
);

select ok(
  (create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 2, 'rate', 5000, 'discount', 0
    )),
    'payment', null
  ))->>'created')::boolean,
  'owner can create bill via create_bill'
);

select ok(
  (record_payment(jsonb_build_object(
    'id', '91111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'amount', 2500,
    'method', 'cash',
    'received_by', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  ))->>'created')::boolean,
  'owner can record payment via record_payment'
);

-- now() is transaction-stable, so seed customer.updated_at in the past above;
-- after create_bill the view watermark must equal the bill's created_at.
select is(
  (select updated_at from customer_balances where customer_id = 'e1111111-1111-1111-1111-111111111111'),
  (select created_at from bills where id = 'f1111111-1111-1111-1111-111111111111'),
  'customer_balances.updated_at advances when a bill is created'
);

select * from finish();
rollback;
