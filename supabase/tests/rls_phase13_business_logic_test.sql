-- Phase 13: credit-note discount proration + bill status after returns.
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

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', 0);

insert into categories (id, business_id, name) values
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Beverages');

insert into products (id, business_id, category_id, name, unit, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000, 100);

-- Bill: 10 units @ 5000 with 10000 line discount → line_total 40000.
insert into bills (id, business_id, customer_id, items_total, discount, grand_total, status, created_by, bill_no)
values ('f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 40000, 0, 40000, 'due', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'BS-0001');

insert into bill_items (id, bill_id, product_id, name_snapshot, qty, rate, discount, line_total)
values ('f2222222-2222-2222-2222-222222222222', 'f1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'Cola', 10, 5000, 10000, 40000);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select test_set_auth('22222222-2222-2222-2222-222222222222');

-- Partial return of 1 unit: prorated discount = floor(10000*1/10) = 1000
-- line credit = 5000 - 1000 = 4000 (NOT 5000 - 10000).
select is(
  (select (create_credit_note(jsonb_build_object(
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'restock', false,
    'reason', 'Partial',
    'items', jsonb_build_array(jsonb_build_object(
      'bill_item_id', 'f2222222-2222-2222-2222-222222222222',
      'qty_returned', 1
    ))
  ))->>'created')::boolean),
  true,
  'owner creates discounted partial credit note'
);

select is(
  (select discount::bigint from credit_note_items
   where bill_item_id = 'f2222222-2222-2222-2222-222222222222'),
  1000::bigint,
  'partial return prorates line discount'
);

select is(
  (select grand_total::bigint from credit_notes
   where bill_id = 'f1111111-1111-1111-1111-111111111111'),
  4000::bigint,
  'partial return credits net of prorated discount'
);

select is(
  (select status::text from bills where id = 'f1111111-1111-1111-1111-111111111111'),
  'partial',
  'partial credit note marks bill partial'
);

-- Return remaining 9 units → bill fully settled via credit notes.
select is(
  (select (create_credit_note(jsonb_build_object(
    'bill_id', 'f1111111-1111-1111-1111-111111111111',
    'restock', false,
    'items', jsonb_build_array(jsonb_build_object(
      'bill_item_id', 'f2222222-2222-2222-2222-222222222222',
      'qty_returned', 9
    ))
  ))->>'created')::boolean),
  true,
  'owner returns remaining qty'
);

select is(
  (select status::text from bills where id = 'f1111111-1111-1111-1111-111111111111'),
  'paid',
  'full return settles bill status to paid'
);

select * from finish();
rollback;
