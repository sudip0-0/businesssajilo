-- Test Phase 45: Profit analytics and cross-entity analytics RPCs
begin;
select plan(7);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Profit Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@profit.test', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'sales@profit.test', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', 'wh@profit.test', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust@profit.test', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'sales', 'Sales', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'warehouse', 'Warehouse', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true);

insert into customers (id, business_id, member_id, shop_name, phone, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Super Store', '9811111111', 0);

insert into products (id, business_id, name, unit, cost_price, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Juice Box', 'piece', 6000, 10000, 50);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Authenticate as owner to create a bill
select test_set_auth('22222222-2222-2222-2222-222222222222');

-- Sell 2 Juice Boxes at 10000 (Cost is 6000 each -> Total Revenue = 20000, Cost = 12000, Profit = 8000)
select create_bill(jsonb_build_object(
  'id', 'f1111111-1111-1111-1111-111111111111',
  'customer_id', 'e1111111-1111-1111-1111-111111111111',
  'discount', 0,
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', 'b1111111-1111-1111-1111-111111111111',
    'name_snapshot', 'Juice Box', 'qty', 2, 'rate', 10000, 'discount', 0
  )),
  'payment', null
));

-- 1. Owner can view profit summary
select is(
  (select (report_profit_summary('2020-01-01'::date, '2030-01-01'::date)->>'gross_profit')::bigint),
  8000::bigint,
  'owner can read accurate gross profit from report_profit_summary'
);

select is(
  (select (report_profit_summary('2020-01-01'::date, '2030-01-01'::date)->>'total_revenue')::bigint),
  20000::bigint,
  'owner can read total revenue from report_profit_summary'
);

-- 2. Owner can view top profitable products
select is(
  (select gross_profit from report_top_profitable_products('2020-01-01'::date, '2030-01-01'::date, 10) limit 1),
  8000::bigint,
  'report_top_profitable_products returns accurate product profit'
);

-- 3. Owner can view top profitable customers
select is(
  (select gross_profit from report_top_profitable_customers('2020-01-01'::date, '2030-01-01'::date, 10) limit 1),
  8000::bigint,
  'report_top_profitable_customers returns accurate customer profit'
);

-- 4. Cross analytics: Top products for a customer
select is(
  (select gross_profit from report_customer_top_products('e1111111-1111-1111-1111-111111111111'::uuid) limit 1),
  8000::bigint,
  'report_customer_top_products returns profit for customer'
);

-- 5. Cross analytics: Top customers for a product
select is(
  (select gross_profit from report_product_top_customers('b1111111-1111-1111-1111-111111111111'::uuid) limit 1),
  8000::bigint,
  'report_product_top_customers returns customer breakdown for product'
);

-- 6. Deny path: Warehouse cannot access profit summary
select test_set_auth('44444444-4444-4444-4444-444444444444');
select throws_ok(
  $$ select report_profit_summary('2020-01-01'::date, '2030-01-01'::date) $$,
  'Permission denied: cannot view profit analytics',
  'warehouse is denied access to profit analytics'
);

select * from finish();
rollback;
