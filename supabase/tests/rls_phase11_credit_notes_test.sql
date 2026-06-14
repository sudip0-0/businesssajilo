-- RLS tests for Phase 11 credit notes (sales returns).
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

insert into products (id, business_id, category_id, name, unit, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000, 0);

insert into bills (id, business_id, customer_id, items_total, discount, grand_total, status, created_by, bill_no)
values ('f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 10000, 0, 10000, 'due', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'BS-0001');

insert into bill_items (id, bill_id, product_id, name_snapshot, qty, rate, discount, line_total)
values ('f2222222-2222-2222-2222-222222222222', 'f1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'Cola', 2, 5000, 0, 10000);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Owner creates partial credit note with restock.
select test_set_auth('22222222-2222-2222-2222-222222222222');

select is(
  (select (create_credit_note(jsonb_build_object(
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'restock', true,
    'reason', 'Damaged',
    'items', jsonb_build_array(jsonb_build_object(
      'bill_item_id', 'f2222222-2222-2222-2222-222222222222',
      'qty_returned', 1,
      'rate', 5000,
      'discount', 0
    ))
  ))->>'created')::boolean),
  true,
  'owner creates partial credit note'
);

select is(
  (select credit_no from credit_notes where bill_id = 'f1111111-1111-1111-1111-111111111111'),
  'CN-0001',
  'credit note gets CN-0001'
);

select is(
  (select grand_total::bigint from credit_notes where bill_id = 'f1111111-1111-1111-1111-111111111111'),
  5000::bigint,
  'partial return totals 5000'
);

select is(
  (select count(*)::int from stock_movements where type = 'return'),
  1,
  'restock creates return stock movement'
);

select is(
  (select balance_due::bigint from customer_balances where customer_id = 'e1111111-1111-1111-1111-111111111111'),
  5000::bigint,
  'balance due net of credit note'
);

select is(
  (select count(*)::int from customer_ledger_entries where entry_type = 'credit_note'),
  1,
  'ledger includes credit note entry'
);

-- Sales reads credit notes.
select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select count(*)::int from credit_notes),
  1,
  'sales reads credit notes'
);

-- Warehouse blocked from credit notes.
select test_set_auth('44444444-4444-4444-4444-444444444444');

select is(
  (select count(*)::int from credit_notes),
  0,
  'warehouse cannot read credit notes'
);

select throws_ok(
  $$select create_credit_note(jsonb_build_object(
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'restock', false,
    'items', jsonb_build_array(jsonb_build_object(
      'bill_item_id', 'f2222222-2222-2222-2222-222222222222',
      'qty_returned', 1,
      'rate', 5000,
      'discount', 0
    ))
  ))$$,
  'P0001',
  'forbidden',
  'warehouse cannot create credit notes'
);

-- Customer reads own credit note.
select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select count(*)::int from credit_notes),
  1,
  'customer reads own credit notes'
);

select * from finish();
rollback;
