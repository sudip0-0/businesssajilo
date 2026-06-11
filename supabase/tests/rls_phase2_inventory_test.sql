-- RLS tests for Phase 2 inventory.
begin;
select plan(10);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'sales@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', 'wh@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'sales', 'Sales', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'warehouse', 'WH', true);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Owner creates category and product.
select test_set_auth('22222222-2222-2222-2222-222222222222');

insert into categories (id, business_id, name) values
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Beverages');

insert into products (id, business_id, category_id, name, unit, low_stock_threshold) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5);

select is(
  (select count(*)::int from products),
  1,
  'owner reads products'
);

insert into stock_movements (id, business_id, product_id, type, qty_delta, created_by)
values ('c1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'stock_in', 10, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

select is(
  (select stock_cached from products where id = 'b1111111-1111-1111-1111-111111111111'),
  10,
  'stock_cached updated after stock_in'
);

-- Warehouse can insert stock_in.
select test_set_auth('44444444-4444-4444-4444-444444444444');

insert into stock_movements (id, business_id, product_id, type, qty_delta, created_by)
values ('d2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'stock_in', 2, 'cccccccc-cccc-cccc-cccc-cccccccccccc');

select is(
  (select stock_cached from products where id = 'b1111111-1111-1111-1111-111111111111'),
  12,
  'warehouse can stock_in'
);

-- Warehouse cannot insert category.
select throws_ok(
  $$insert into categories (business_id, name) values ('11111111-1111-1111-1111-111111111111', 'Blocked')$$,
  '42501',
  null,
  'warehouse cannot insert category'
);

-- Warehouse cannot update product.
update products set name = 'Hacked' where id = 'b1111111-1111-1111-1111-111111111111';
select is(
  (select name from products where id = 'b1111111-1111-1111-1111-111111111111'),
  'Cola',
  'warehouse cannot update product'
);

-- Sales can read products.
select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select count(*)::int from products),
  1,
  'sales reads products'
);

-- Sales cannot insert movements.
select throws_ok(
  $$insert into stock_movements (business_id, product_id, type, qty_delta, created_by)
    values ('11111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'stock_in', 1, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')$$,
  '42501',
  null,
  'sales cannot insert movements'
);

-- Low-stock notification when crossing threshold.
select test_set_auth('22222222-2222-2222-2222-222222222222');

insert into stock_movements (id, business_id, product_id, type, qty_delta, reason, created_by)
values ('e3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'adjust', -10, 'damaged', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

select is(
  (select stock_cached from products where id = 'b1111111-1111-1111-1111-111111111111'),
  2,
  'adjust reduces stock'
);

reset role;
select is(
  (select count(*)::int from notifications where type = 'low_stock'),
  2,
  'low_stock notifications created for owner and warehouse'
);

-- stock_movements are append-only.
select test_set_auth('22222222-2222-2222-2222-222222222222');

update stock_movements set qty_delta = 999 where id = 'c1111111-1111-1111-1111-111111111111';
select is(
  (select qty_delta from stock_movements where id = 'c1111111-1111-1111-1111-111111111111'),
  10,
  'stock_movements cannot be updated'
);

select * from finish();
rollback;
