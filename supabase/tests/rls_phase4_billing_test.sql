-- RLS tests for Phase 4 billing.
begin;
select plan(9);

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

-- Owner creates bill with auto numbering.
select test_set_auth('22222222-2222-2222-2222-222222222222');

insert into bills (id, business_id, customer_id, items_total, discount, grand_total, status, created_by)
values ('f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 10000, 0, 10000, 'due', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

select is(
  (select bill_no from bills where id = 'f1111111-1111-1111-1111-111111111111'),
  'BS-0001',
  'owner bill gets BS-0001'
);

insert into bill_items (id, bill_id, product_id, name_snapshot, qty, rate, discount, line_total)
values ('f2222222-2222-2222-2222-222222222222', 'f1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'Cola', 2, 5000, 0, 10000);

select is(
  (select count(*)::int from bill_items),
  1,
  'owner inserts bill items'
);

-- Sales creates second bill.
select test_set_auth('33333333-3333-3333-3333-333333333333');

insert into bills (id, business_id, customer_id, items_total, discount, grand_total, status, created_by)
values ('f3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 5000, 0, 5000, 'paid', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

select is(
  (select bill_no from bills where id = 'f3333333-3333-3333-3333-333333333333'),
  'BS-0002',
  'sales bill gets BS-0002'
);

insert into payments (id, business_id, customer_id, bill_id, amount, method, received_by)
values ('91111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 'f3333333-3333-3333-3333-333333333333', 5000, 'cash', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

select is(
  (select balance_due::bigint from customer_balances where customer_id = 'e1111111-1111-1111-1111-111111111111'),
  10000::bigint,
  'balance due reflects bill minus payment'
);

-- Warehouse cannot read bills.
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
