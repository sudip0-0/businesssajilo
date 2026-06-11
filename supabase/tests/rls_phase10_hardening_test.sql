-- Tests for Phase 10 hardening: bill_sequences lockdown, cross-tenant guards,
-- RPC role checks, transactional bill/quote RPCs, bill status lifecycle,
-- walk-in stock deduction, column pinning, opening-balance guard.
begin;
select plan(18);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Biz A'),
  ('99999999-9999-9999-9999-999999999999', 'Biz B');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'sales-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', 'wh-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('66666666-6666-6666-6666-666666666666', 'owner-b@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner A', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'sales', 'Sales A', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'warehouse', 'WH A', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust A', true),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '99999999-9999-9999-9999-999999999999', '66666666-6666-6666-6666-666666666666', 'owner', 'Owner B', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', 0);

insert into products (id, business_id, name, unit, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000, 0),
  ('b9999999-9999-9999-9999-999999999999', '99999999-9999-9999-9999-999999999999', 'Foreign Soda', 'piece', 5000, 0);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- 1. bill_sequences is not readable by authenticated users.
select test_set_auth('22222222-2222-2222-2222-222222222222');
select throws_ok(
  $$select * from bill_sequences$$,
  '42501',
  null,
  'authenticated cannot read bill_sequences'
);

-- 2. Cross-tenant product UUID rejected on stock movements.
select throws_ok(
  $$insert into stock_movements (business_id, product_id, type, qty_delta, created_by)
    values ('11111111-1111-1111-1111-111111111111', 'b9999999-9999-9999-9999-999999999999', 'stock_in', 5, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  'product does not belong to this business'
);

-- 3. create_bill validates totals server-side and assigns numbering.
select is(
  (create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'status', 'due',
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 2, 'rate', 5000, 'discount', 0
    ))
  ))->'bill'->>'bill_no'),
  'BS-0001',
  'create_bill assigns sequential number'
);

-- 4. create_bill is idempotent on replay.
select is(
  (create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 2, 'rate', 5000, 'discount', 0
    ))
  ))->>'created')::boolean,
  false,
  'create_bill replay returns existing bill'
);

-- 5. Counter bill deducted stock.
select is(
  (select stock_cached from products where id = 'b1111111-1111-1111-1111-111111111111'),
  -2,
  'walk-in bill deducts stock'
);

-- 6. Excessive discount rejected.
select throws_ok(
  $$select create_bill(jsonb_build_object(
      'customer_id', 'e1111111-1111-1111-1111-111111111111',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', 'b1111111-1111-1111-1111-111111111111',
        'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 9000
      ))
    ))$$,
  'item discount out of range'
);

-- 7. Tampered direct bill_items line math rejected.
select throws_ok(
  $$insert into bill_items (bill_id, product_id, name_snapshot, qty, rate, discount, line_total)
    values ('f1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'Cola', 1, 5000, 0, 99999)$$,
  '23514',
  null,
  'bill item line math constraint enforced'
);

-- 8. Payment equal to grand total flips bill to paid.
insert into payments (business_id, customer_id, bill_id, amount, method, received_by)
values ('11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111',
        'f1111111-1111-1111-1111-111111111111', 10000, 'cash', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

select is(
  (select status::text from bills where id = 'f1111111-1111-1111-1111-111111111111'),
  'paid',
  'full payment flips bill status to paid'
);

-- 9. Cross-tenant bill_id rejected on payments.
select test_set_auth('66666666-6666-6666-6666-666666666666');
select throws_ok(
  $$insert into payments (business_id, customer_id, bill_id, amount, method, received_by)
    values ('99999999-9999-9999-9999-999999999999', 'e1111111-1111-1111-1111-111111111111',
            'f1111111-1111-1111-1111-111111111111', 100, 'cash', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee')$$,
  'customer does not belong to this business'
);

-- 10. apply_product_sync forbidden for customers.
select test_set_auth('55555555-5555-5555-5555-555555555555');
select throws_ok(
  $$select apply_product_sync('b1111111-1111-1111-1111-111111111111', 'Hacked', null, null, null,
    'piece', 0, 0, null, 0, 0, true, now() + interval '1 day')$$,
  'forbidden'
);

-- 11. insert_audit_log forbidden for customers.
select throws_ok(
  $$select insert_audit_log('products', 'b1111111-1111-1111-1111-111111111111', 'name', 'a', 'b', 'sync_lww')$$,
  'forbidden'
);

-- 12. Owner cannot escalate member roles.
select test_set_auth('22222222-2222-2222-2222-222222222222');
select throws_ok(
  $$update members set role = 'owner' where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'$$,
  'member role and tenancy cannot be changed'
);

-- 13. Opening balance locked once ledger has activity.
select throws_ok(
  $$update customers set opening_balance = 777 where id = 'e1111111-1111-1111-1111-111111111111'$$,
  'opening balance cannot be changed once the customer has bills or payments'
);

-- 14/15. send_quote: order flow, supersede prior sent quotes.
select test_set_auth('55555555-5555-5555-5555-555555555555');
insert into orders (id, business_id, customer_id, status)
values ('01111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
        'e1111111-1111-1111-1111-111111111111', 'placed');
insert into order_items (order_id, product_id, qty)
values ('01111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 3);

select test_set_auth('33333333-3333-3333-3333-333333333333');
select is(
  (send_quote('01111111-1111-1111-1111-111111111111', jsonb_build_array(jsonb_build_object(
    'product_id', 'b1111111-1111-1111-1111-111111111111', 'qty', 3, 'rate', 5000, 'discount', 0
  )))->>'version')::int,
  1,
  'send_quote creates version 1'
);

select is(
  (send_quote('01111111-1111-1111-1111-111111111111', jsonb_build_array(jsonb_build_object(
    'product_id', 'b1111111-1111-1111-1111-111111111111', 'qty', 3, 'rate', 4500, 'discount', 0
  )))->>'version')::int,
  2,
  'send_quote re-quote creates version 2'
);

select is(
  (select status::text from quotes where order_id = '01111111-1111-1111-1111-111111111111' and version = 1),
  'superseded',
  'previous sent quote is superseded'
);

-- 16. Double-billing an order is blocked (after dispatch flow).
update quotes set status = 'accepted'
where order_id = '01111111-1111-1111-1111-111111111111' and version = 2;
update orders set status = 'confirmed' where id = '01111111-1111-1111-1111-111111111111';
update orders set status = 'packed' where id = '01111111-1111-1111-1111-111111111111';
update orders set status = 'dispatched' where id = '01111111-1111-1111-1111-111111111111';

select is(
  (create_bill(jsonb_build_object(
    'order_id', '01111111-1111-1111-1111-111111111111',
    'status', 'due',
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 3, 'rate', 4500, 'discount', 0
    ))
  ))->>'created')::boolean,
  true,
  'create_bill bills a dispatched order'
);

select throws_ok(
  $$select create_bill(jsonb_build_object(
      'order_id', '01111111-1111-1111-1111-111111111111',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', 'b1111111-1111-1111-1111-111111111111',
        'name_snapshot', 'Cola', 'qty', 3, 'rate', 4500, 'discount', 0
      ))
    ))$$,
  'order is already billed',
  'double billing an order is rejected'
);

select * from finish();
rollback;
