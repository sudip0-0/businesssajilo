-- Customer own-bill search, warehouse billing-draft boundary, audit-log deny.
begin;
select plan(24);

insert into businesses (id, name) values
  ('58000000-0000-4000-8000-000000000001', 'Search Prefill Biz'),
  ('58000000-0000-4000-8000-000000000002', 'Other Prefill Biz');

insert into auth.users (id, email, aud, role) values
  ('58000000-0000-4000-8000-000000000011', 'owner58@test.com', 'authenticated', 'authenticated'),
  ('58000000-0000-4000-8000-000000000012', 'sales58@test.com', 'authenticated', 'authenticated'),
  ('58000000-0000-4000-8000-000000000013', 'warehouse58@test.com', 'authenticated', 'authenticated'),
  ('58000000-0000-4000-8000-000000000014', 'customer58@test.com', 'authenticated', 'authenticated'),
  ('58000000-0000-4000-8000-000000000015', 'customer58b@test.com', 'authenticated', 'authenticated'),
  ('58000000-0000-4000-8000-000000000016', 'otherowner58@test.com', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('58100000-0000-4000-8000-000000000011', '58000000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000011', 'owner', 'Owner', true),
  ('58100000-0000-4000-8000-000000000012', '58000000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000012', 'sales', 'Sales', true),
  ('58100000-0000-4000-8000-000000000013', '58000000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000013', 'warehouse', 'Warehouse', true),
  ('58100000-0000-4000-8000-000000000014', '58000000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000014', 'customer', 'Customer', true),
  ('58100000-0000-4000-8000-000000000015', '58000000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000015', 'customer', 'Other Customer', true),
  ('58100000-0000-4000-8000-000000000016', '58000000-0000-4000-8000-000000000002', '58000000-0000-4000-8000-000000000016', 'owner', 'Other Owner', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('58200000-0000-4000-8000-000000000014', '58000000-0000-4000-8000-000000000001', '58100000-0000-4000-8000-000000000014', 'Ram Store', 10000),
  ('58200000-0000-4000-8000-000000000015', '58000000-0000-4000-8000-000000000001', '58100000-0000-4000-8000-000000000015', 'Sita Store', 20000);

insert into products (id, business_id, name, unit, reference_price) values
  ('58300000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000001', 'Rice', 'bag', 2500);

insert into orders (id, business_id, customer_id, status) values
  ('58400000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000001', '58200000-0000-4000-8000-000000000014', 'received'),
  ('58400000-0000-4000-8000-000000000002', '58000000-0000-4000-8000-000000000001', '58200000-0000-4000-8000-000000000014', 'received');

insert into order_items (id, business_id, order_id, product_id, qty, product_name) values
  ('58410000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000001', '58400000-0000-4000-8000-000000000001', '58300000-0000-4000-8000-000000000001', 2, 'Rice'),
  ('58410000-0000-4000-8000-000000000002', '58000000-0000-4000-8000-000000000001', '58400000-0000-4000-8000-000000000002', '58300000-0000-4000-8000-000000000001', 1, 'Rice');

insert into quotes (id, business_id, order_id, version, status, total, created_by, response_comment) values
  ('58500000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000001', '58400000-0000-4000-8000-000000000001', 1, 'rejected', 19998, '58100000-0000-4000-8000-000000000011', 'too high'),
  ('58500000-0000-4000-8000-000000000002', '58000000-0000-4000-8000-000000000001', '58400000-0000-4000-8000-000000000001', 2, 'accepted', 3740, '58100000-0000-4000-8000-000000000011', 'ok');

insert into quote_items (id, business_id, quote_id, product_id, qty, rate, discount, line_total) values
  ('58510000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000001', '58500000-0000-4000-8000-000000000001', '58300000-0000-4000-8000-000000000001', 2, 9999, 0, 19998),
  ('58510000-0000-4000-8000-000000000002', '58000000-0000-4000-8000-000000000001', '58500000-0000-4000-8000-000000000002', '58300000-0000-4000-8000-000000000001', 3, 1255, 25, 3740);

insert into bills (id, business_id, created_by, customer_id, status, items_total, discount, grand_total)
values
  ('58600000-0000-4000-8000-000000000001', '58000000-0000-4000-8000-000000000001', '58100000-0000-4000-8000-000000000011', '58200000-0000-4000-8000-000000000014', 'due', 1000, 0, 1000),
  ('58600000-0000-4000-8000-000000000002', '58000000-0000-4000-8000-000000000001', '58100000-0000-4000-8000-000000000011', '58200000-0000-4000-8000-000000000015', 'due', 500, 0, 500);

reset role;
insert into audit_log (business_id, table_name, record_id, field_name, old_value, new_value, source)
values (
  '58000000-0000-4000-8000-000000000001',
  'customers',
  '58200000-0000-4000-8000-000000000014',
  'opening_balance',
  '10000',
  '25000',
  'manual'
);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select set_config('test.ram_bill', (select bill_no from bills where id = '58600000-0000-4000-8000-000000000001'), true);
select set_config('test.sita_bill', (select bill_no from bills where id = '58600000-0000-4000-8000-000000000002'), true);

select test_set_auth('58000000-0000-4000-8000-000000000013');
select is((select count(*)::int from orders), 0, 'warehouse cannot read orders');
select is((select count(*)::int from quotes), 0, 'warehouse cannot read quote history');
select is((select count(*)::int from quote_items), 0, 'warehouse cannot read quote items');
select is((select count(*)::int from audit_log), 0, 'warehouse cannot read audit log');
select is(
  billing_draft_from_order('58400000-0000-4000-8000-000000000001')->>'source',
  'accepted_quote',
  'warehouse billing draft uses accepted quote'
);
select is(
  (billing_draft_from_order('58400000-0000-4000-8000-000000000001')->'lines'->0->>'qty'),
  '3',
  'warehouse draft preserves accepted quote quantity'
);
select is(
  (billing_draft_from_order('58400000-0000-4000-8000-000000000001')->'lines'->0->>'rate'),
  '1255',
  'warehouse draft preserves accepted quote rate'
);
select is(
  (billing_draft_from_order('58400000-0000-4000-8000-000000000001')->'lines'->0->>'discount'),
  '25',
  'warehouse draft preserves accepted quote discount'
);
select is(
  billing_draft_from_order('58400000-0000-4000-8000-000000000001')->>'shop_name',
  'Ram Store',
  'warehouse draft includes directory identity'
);
select ok(
  not (billing_draft_from_order('58400000-0000-4000-8000-000000000001') ? 'quotes')
  and not (billing_draft_from_order('58400000-0000-4000-8000-000000000001') ? 'opening_balance')
  and not (billing_draft_from_order('58400000-0000-4000-8000-000000000001') ? 'balance_due')
  and not (billing_draft_from_order('58400000-0000-4000-8000-000000000001') ? 'response_comment')
  and position('too high' in billing_draft_from_order('58400000-0000-4000-8000-000000000001')::text) = 0
  and position('9999' in billing_draft_from_order('58400000-0000-4000-8000-000000000001')::text) = 0,
  'warehouse draft omits quote history and finance'
);
select is(
  billing_draft_from_order('58400000-0000-4000-8000-000000000002')->>'source',
  'order_items',
  'warehouse draft without quote uses order items'
);
select is(
  (billing_draft_from_order('58400000-0000-4000-8000-000000000002')->'lines'->0->>'rate'),
  '2500',
  'warehouse order-item draft uses reference price'
);

select test_set_auth('58000000-0000-4000-8000-000000000011');
select is((select count(*)::int from audit_log), 1, 'owner can read tenant audit log');
select is(
  billing_draft_from_order('58400000-0000-4000-8000-000000000001')->'lines'->0->>'rate',
  '1255',
  'owner billing draft uses accepted quote'
);

select test_set_auth('58000000-0000-4000-8000-000000000012');
select is((select count(*)::int from audit_log), 1, 'sales can read tenant audit log');

select test_set_auth('58000000-0000-4000-8000-000000000014');
select is(jsonb_array_length(search_bills('Ram Store')), 1, 'customer can search own bills by shop name');
select is(
  jsonb_array_length(search_bills(current_setting('test.ram_bill'))),
  1,
  'customer can search own bills by number'
);
select is(jsonb_array_length(search_bills('Sita Store')), 0, 'customer cannot search another customer by shop name');
select is(
  jsonb_array_length(search_bills(current_setting('test.sita_bill'))),
  0,
  'customer cannot search another customer bill number'
);
select throws_ok(
  $$select billing_draft_from_order('58400000-0000-4000-8000-000000000001')$$,
  'P0001',
  'forbidden',
  'customer cannot load staff billing draft'
);
select is((select count(*)::int from audit_log), 0, 'customer cannot read audit log');

select test_set_auth('58000000-0000-4000-8000-000000000015');
select is(jsonb_array_length(search_bills('Ram Store')), 0, 'other customer cannot search first customer bills');

select test_set_auth('58000000-0000-4000-8000-000000000016');
select is((select count(*)::int from audit_log), 0, 'other tenant cannot read audit log');
select throws_ok(
  $$select billing_draft_from_order('58400000-0000-4000-8000-000000000001')$$,
  'P0001',
  'order not found',
  'other tenant cannot load billing draft'
);

select * from finish();
rollback;
