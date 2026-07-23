-- Phase 21: low_stock_count / list_low_stock / total_dues + notifications index.
begin;
select plan(11);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Biz A'),
  ('99999999-9999-9999-9999-999999999999', 'Biz B');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'sales-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', 'wh-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('66666666-6666-6666-6666-666666666666', 'owner-b@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('77777777-7777-7777-7777-777777777777', 'cust2@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner A', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'sales', 'Sales A', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'warehouse', 'WH A', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust A', true),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '99999999-9999-9999-9999-999999999999', '66666666-6666-6666-6666-666666666666', 'owner', 'Owner B', true),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777777', 'customer', 'Cust2', true);

insert into categories (id, business_id, name) values
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Beverages');

insert into products (id, business_id, category_id, name, unit, reference_price, stock_cached, low_stock_threshold, is_active) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000, 2, 5, true),
  ('b2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', null, 'Plenty', 'piece', 1000, 50, 5, true),
  ('b3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', null, 'Inactive Low', 'piece', 1000, 0, 5, false),
  ('b9999999-9999-9999-9999-999999999999', '99999999-9999-9999-9999-999999999999', null, 'Other Biz Low', 'piece', 1000, 1, 5, true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Shop A', 1500),
  ('e2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Shop Credit', 0);

-- Shop A: opening 1500 - paid 500 = 1000 due.
-- Shop Credit: opening 0 - paid 300 = -300 (credit; must not reduce total_dues).
insert into payments (id, business_id, customer_id, amount, method, received_by) values
  ('f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 500, 'cash', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('f2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'e2222222-2222-2222-2222-222222222222', 300, 'cash', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- 1. Owner low_stock_count counts active products at/below threshold.
select test_set_auth('22222222-2222-2222-2222-222222222222');
select is(
  low_stock_count(),
  1,
  'owner low_stock_count is tenant-scoped and active-only'
);

-- 2. list_low_stock returns category_name and respects limit.
select is(
  (list_low_stock(10)->0->>'name'),
  'Cola',
  'list_low_stock returns the low-stock product'
);

select is(
  (list_low_stock(10)->0->>'category_name'),
  'Beverages',
  'list_low_stock includes category_name'
);

select is(
  jsonb_array_length(list_low_stock(1)),
  1,
  'list_low_stock respects p_limit'
);

-- 3. Tenant isolation — Biz B owner does not see Biz A low stock.
select test_set_auth('66666666-6666-6666-6666-666666666666');
select is(
  low_stock_count(),
  1,
  'owner B sees only own low-stock product'
);

select is(
  (list_low_stock(10)->0->>'name'),
  'Other Biz Low',
  'list_low_stock is tenant-scoped'
);

-- 4. total_dues sums only positive balances for owner/sales.
select test_set_auth('22222222-2222-2222-2222-222222222222');
select is(
  total_dues(),
  1000::bigint,
  'owner total_dues sums only positive balances'
);

select test_set_auth('33333333-3333-3333-3333-333333333333');
select is(
  total_dues(),
  1000::bigint,
  'sales can read total_dues'
);

-- 5. Warehouse/customer denied (role filter → 0).
select test_set_auth('44444444-4444-4444-4444-444444444444');
select is(
  total_dues(),
  0::bigint,
  'warehouse cannot read total_dues'
);

select test_set_auth('55555555-5555-5555-5555-555555555555');
select is(
  total_dues(),
  0::bigint,
  'customer cannot read total_dues'
);

-- 6. notifications(business_id) index exists.
select ok(
  exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and indexname = 'notifications_business_idx'
  ),
  'notifications_business_idx exists'
);

select * from finish();
rollback;
