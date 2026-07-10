-- RLS tests for Phase 8 reports.
begin;
select plan(6);

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

insert into products (id, business_id, category_id, name, unit, cost_price, reference_price, stock_cached, low_stock_threshold) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Cola', 'piece', 3000, 5000, 10, 5);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Owner creates a bill for sales report data.
select test_set_auth('22222222-2222-2222-2222-222222222222');

select create_bill(jsonb_build_object(
  'id', 'f1111111-1111-1111-1111-111111111111',
  'customer_id', 'e1111111-1111-1111-1111-111111111111',
  'discount', 0,
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', 'b1111111-1111-1111-1111-111111111111',
    'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
  )),
  'payment', null
));

select is(
  (select count(*)::int from report_sales_daily where total_sales = 5000),
  1,
  'owner reads report_sales_daily'
);

select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select count(*)::int from report_sales_daily where total_sales = 5000),
  1,
  'sales reads report_sales_daily'
);

select test_set_auth('44444444-4444-4444-4444-444444444444');

select is(
  (select count(*)::int from report_sales_daily),
  0,
  'warehouse cannot read bill-based report_sales_daily'
);

select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select count(*)::int from report_sales_daily),
  0,
  'customer cannot read report_sales_daily'
);

select test_set_auth('22222222-2222-2222-2222-222222222222');

select is(
  (select count(*)::int from report_stock_valuation where product_id = 'b1111111-1111-1111-1111-111111111111'),
  1,
  'owner reads report_stock_valuation'
);

select test_set_auth('44444444-4444-4444-4444-444444444444');

select is(
  (select count(*)::int from report_stock_valuation where product_id = 'b1111111-1111-1111-1111-111111111111'),
  1,
  'warehouse can read product valuation view via products RLS'
);

select * from finish();
rollback;
