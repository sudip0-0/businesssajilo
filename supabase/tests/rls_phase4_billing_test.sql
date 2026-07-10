-- RLS tests for Phase 4 billing.
begin;
select plan(10);

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
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', 0);

insert into categories (id, business_id, name) values
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Beverages');

insert into products (id, business_id, category_id, name, unit, reference_price) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Owner creates bill via create_bill (RPC-only writes).
select test_set_auth('22222222-2222-2222-2222-222222222222');

select is(
  (create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 2, 'rate', 5000, 'discount', 0
    )),
    'payment', null
  ))->'bill'->>'bill_no'),
  'BS-0001',
  'owner bill gets BS-0001'
);

select is(
  (select count(*)::int from bill_items where bill_id = 'f1111111-1111-1111-1111-111111111111'),
  1,
  'owner create_bill inserts bill items'
);

-- Sales creates second bill and records payment via RPCs.
select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (create_bill(jsonb_build_object(
    'id', 'f3333333-3333-3333-3333-333333333333',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    )),
    'payment', null
  ))->'bill'->>'bill_no'),
  'BS-0002',
  'sales bill gets BS-0002'
);

select record_payment(jsonb_build_object(
  'id', '91111111-1111-1111-1111-111111111111',
  'customer_id', 'e1111111-1111-1111-1111-111111111111',
  'bill_id', 'f3333333-3333-3333-3333-333333333333',
  'amount', 5000,
  'method', 'cash',
  'received_by', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
));

select is(
  (select balance_due::bigint from customer_balances where customer_id = 'e1111111-1111-1111-1111-111111111111'),
  10000::bigint,
  'balance due reflects bill minus payment'
);

-- Warehouse cannot read or insert bills.
select test_set_auth('44444444-4444-4444-4444-444444444444');

select is(
  (select count(*)::int from bills),
  0,
  'warehouse cannot read bills'
);

select throws_ok(
  $$insert into bills (business_id, customer_id, items_total, discount, grand_total, status, created_by)
    values ('11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 1000, 0, 1000, 'due', 'cccccccc-cccc-cccc-cccc-cccccccccccc')$$,
  '42501',
  null,
  'warehouse cannot insert bills'
);

-- Owner also cannot direct-insert bills (RPC-only).
select test_set_auth('22222222-2222-2222-2222-222222222222');

select throws_ok(
  $$insert into bills (business_id, customer_id, items_total, discount, grand_total, status, created_by)
    values ('11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 1000, 0, 1000, 'due', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501',
  null,
  'owner cannot direct-insert bills'
);

-- Customer reads own bills.
select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select count(*)::int from bills),
  2,
  'customer reads own bills'
);

-- Ledger includes bill entries.
select is(
  (select count(*)::int from customer_ledger_entries where entry_type = 'bill'),
  2,
  'ledger includes bill entries'
);

-- Bills are immutable.
select test_set_auth('22222222-2222-2222-2222-222222222222');

update bills set grand_total = 1 where id = 'f1111111-1111-1111-1111-111111111111';
select is(
  (select grand_total from bills where id = 'f1111111-1111-1111-1111-111111111111'),
  10000::bigint,
  'bills cannot be updated'
);

select * from finish();
rollback;
