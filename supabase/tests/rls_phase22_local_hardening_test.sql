-- Phase 22: credit-note RPC-only, dues parity, message body cap, audit revoke.
begin;
select plan(8);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'sales@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('77777777-7777-7777-7777-777777777777', 'cust2@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'sales', 'Sales', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777777', 'customer', 'Cust2', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Shop A', 1500),
  ('e2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Shop Credit', 0);

insert into products (id, business_id, name, unit, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000, 10);

insert into bills (id, business_id, customer_id, items_total, discount, grand_total, status, created_by, bill_no)
values ('f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 10000, 0, 10000, 'due', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'BS-0001');

insert into bill_items (id, bill_id, product_id, name_snapshot, qty, rate, discount, line_total)
values ('f2222222-2222-2222-2222-222222222222', 'f1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'Cola', 2, 5000, 0, 10000);

-- Shop A: opening 1500 - paid 500 = 1000 due.
-- Shop Credit: opening 0 - paid 300 = -300 (must not reduce dues).
insert into payments (id, business_id, customer_id, amount, method, received_by) values
  ('p1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 500, 'cash', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('p2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'e2222222-2222-2222-2222-222222222222', 300, 'cash', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

insert into orders (id, business_id, customer_id, status) values
  ('c1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 'placed');

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- 1. Direct credit_notes INSERT denied for owner.
select test_set_auth('22222222-2222-2222-2222-222222222222');
select throws_ok(
  $$insert into credit_notes (
     id, business_id, bill_id, customer_id, items_total, discount, grand_total,
     restock, created_by, credit_no
   ) values (
     'cn111111-1111-1111-1111-111111111111',
     '11111111-1111-1111-1111-111111111111',
     'f1111111-1111-1111-1111-111111111111',
     'e1111111-1111-1111-1111-111111111111',
     5000, 0, 5000, false,
     'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
     'CN-X'
   )$$,
  '42501',
  null,
  'owner cannot insert credit_notes directly'
);

-- 2. Direct credit_note_items INSERT denied for sales.
select test_set_auth('33333333-3333-3333-3333-333333333333');
select throws_ok(
  $$insert into credit_note_items (
     id, credit_note_id, bill_item_id, product_id, name_snapshot,
     qty_returned, rate, discount, line_total
   ) values (
     'ci111111-1111-1111-1111-111111111111',
     'cn111111-1111-1111-1111-111111111111',
     'f2222222-2222-2222-2222-222222222222',
     'b1111111-1111-1111-1111-111111111111',
     'Cola', 1, 5000, 0, 5000
   )$$,
  '42501',
  null,
  'sales cannot insert credit_note_items directly'
);

-- 3. create_credit_note RPC still works for owner.
select test_set_auth('22222222-2222-2222-2222-222222222222');
select is(
  (select (create_credit_note(jsonb_build_object(
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'restock', false,
    'reason', 'Test',
    'items', jsonb_build_array(jsonb_build_object(
      'bill_item_id', 'f2222222-2222-2222-2222-222222222222',
      'qty_returned', 1,
      'rate', 5000,
      'discount', 0
    ))
  ))->>'created')::boolean),
  true,
  'create_credit_note RPC still works'
);

-- 4–5. Dues parity: owner_dashboard_stats.total_dues == total_dues().
select is(
  total_dues(),
  1000::bigint,
  'total_dues sums only positive balances'
);

select is(
  (owner_dashboard_stats()->>'total_dues')::bigint,
  total_dues(),
  'owner_dashboard_stats.total_dues matches total_dues'
);

-- 6. Oversized chat body rejected.
select throws_ok(
  $$insert into messages (order_id, business_id, sender_member_id, body)
    values (
      'c1111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      repeat('x', 4001)
    )$$,
  '23514',
  null,
  'messages body longer than 4000 is rejected'
);

-- 7. Body at the limit is accepted.
select lives_ok(
  $$insert into messages (order_id, business_id, sender_member_id, body)
    values (
      'c1111111-1111-1111-1111-111111111111',
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      repeat('y', 4000)
    )$$,
  'messages body of exactly 4000 is accepted'
);

-- 8. insert_audit_log no longer executable by authenticated clients.
select throws_ok(
  $$select insert_audit_log(
     'products', 'b1111111-1111-1111-1111-111111111111',
     'name', 'a', 'b', 'sync_lww'
   )$$,
  '42501',
  null,
  'authenticated cannot execute insert_audit_log'
);

select * from finish();
rollback;
