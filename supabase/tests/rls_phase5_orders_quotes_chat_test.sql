-- RLS tests for Phase 5 orders, quotes, chat.
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

insert into products (id, business_id, category_id, name, unit, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000, 100);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Customer places order via catalog (no direct product price access).
select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select count(*)::int from products),
  0,
  'customer cannot read products table'
);

select is(
  (select count(*)::int from list_catalog_products()),
  1,
  'customer reads catalog without prices'
);

insert into orders (id, business_id, customer_id, status, customer_note)
values ('01111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 'placed', 'Need soon');

insert into order_items (id, order_id, product_id, qty)
values ('02111111-1111-1111-1111-111111111111', '01111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 5);

select is(
  (select status::text from orders where id = '01111111-1111-1111-1111-111111111111'),
  'placed',
  'customer order is placed'
);

-- Sales sends quote.
select test_set_auth('33333333-3333-3333-3333-333333333333');

insert into quotes (id, order_id, version, status, total, created_by)
values ('03111111-1111-1111-1111-111111111111', '01111111-1111-1111-1111-111111111111', 1, 'sent', 25000, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

insert into quote_items (id, quote_id, product_id, qty, rate, discount, line_total)
values ('04111111-1111-1111-1111-111111111111', '03111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 5, 5000, 0, 25000);

select is(
  (select status::text from orders where id = '01111111-1111-1111-1111-111111111111'),
  'quoted',
  'order moves to quoted after quote sent'
);

-- Warehouse cannot read quotes.
select test_set_auth('44444444-4444-4444-4444-444444444444');

select is(
  (select count(*)::int from quotes),
  0,
  'warehouse cannot read quotes'
);

-- Customer accepts quote.
select test_set_auth('55555555-5555-5555-5555-555555555555');

update quotes
set status = 'accepted', response_comment = 'Looks good'
where id = '03111111-1111-1111-1111-111111111111';

select is(
  (select status::text from orders where id = '01111111-1111-1111-1111-111111111111'),
  'accepted',
  'order accepted after quote acceptance'
);

-- Sales confirms order.
select test_set_auth('33333333-3333-3333-3333-333333333333');

update orders set status = 'confirmed' where id = '01111111-1111-1111-1111-111111111111';

-- Warehouse packs and dispatches.
select test_set_auth('44444444-4444-4444-4444-444444444444');

update orders set status = 'packed' where id = '01111111-1111-1111-1111-111111111111';
update orders set status = 'dispatched' where id = '01111111-1111-1111-1111-111111111111';

select is(
  (select coalesce(sum(qty_delta), 0)::int from stock_movements where ref_order_id = '01111111-1111-1111-1111-111111111111'),
  -5,
  'dispatch creates negative stock movement'
);

-- Warehouse cannot insert messages.
select throws_ok(
  $$insert into messages (id, order_id, business_id, sender_member_id, body)
    values ('05111111-1111-1111-1111-111111111111', '01111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'hi')$$,
  '42501',
  null,
  'warehouse cannot insert messages'
);

-- Customer and sales can chat.
select test_set_auth('55555555-5555-5555-5555-555555555555');

insert into messages (id, order_id, business_id, sender_member_id, body)
values ('06222222-2222-2222-2222-222222222222', '01111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Thanks');

select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select count(*)::int from messages where order_id = '01111111-1111-1111-1111-111111111111'),
  1,
  'sales reads order messages'
);

select * from finish();
rollback;
