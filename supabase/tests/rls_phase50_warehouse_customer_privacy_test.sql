begin;
select plan(37);

insert into businesses (id, name) values
  ('50000000-0000-4000-8000-000000000001', 'Privacy Test Biz'),
  ('50000000-0000-4000-8000-000000000002', 'Other Privacy Biz');

insert into auth.users (id, email, aud, role) values
  ('50000000-0000-4000-8000-000000000011', 'owner50@test.com', 'authenticated', 'authenticated'),
  ('50000000-0000-4000-8000-000000000012', 'sales50@test.com', 'authenticated', 'authenticated'),
  ('50000000-0000-4000-8000-000000000013', 'warehouse50@test.com', 'authenticated', 'authenticated'),
  ('50000000-0000-4000-8000-000000000014', 'customer50@test.com', 'authenticated', 'authenticated'),
  ('50000000-0000-4000-8000-000000000015', 'customer50b@test.com', 'authenticated', 'authenticated'),
  ('50000000-0000-4000-8000-000000000016', 'otherowner50@test.com', 'authenticated', 'authenticated'),
  ('50000000-0000-4000-8000-000000000017', 'othercustomer50@test.com', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('51000000-0000-4000-8000-000000000011', '50000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000011', 'owner', 'Owner', true),
  ('51000000-0000-4000-8000-000000000012', '50000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000012', 'sales', 'Sales', true),
  ('51000000-0000-4000-8000-000000000013', '50000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000013', 'warehouse', 'Warehouse', true),
  ('51000000-0000-4000-8000-000000000014', '50000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000014', 'customer', 'Customer', true),
  ('51000000-0000-4000-8000-000000000015', '50000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000015', 'customer', 'Second Customer', true),
  ('51000000-0000-4000-8000-000000000016', '50000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000016', 'owner', 'Other Owner', true),
  ('51000000-0000-4000-8000-000000000017', '50000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000017', 'customer', 'Other Customer', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('52000000-0000-4000-8000-000000000014', '50000000-0000-4000-8000-000000000001', '51000000-0000-4000-8000-000000000014', 'Ram Store', 10000),
  ('52000000-0000-4000-8000-000000000015', '50000000-0000-4000-8000-000000000001', '51000000-0000-4000-8000-000000000015', 'Sita Store', 20000),
  ('52000000-0000-4000-8000-000000000017', '50000000-0000-4000-8000-000000000002', '51000000-0000-4000-8000-000000000017', 'Other Store', 30000);

insert into products (id, business_id, name, unit, reference_price) values
  ('53000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', 'Rice', 'bag', 2500);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select test_set_auth('50000000-0000-4000-8000-000000000011');
select is((select count(*)::int from customer_directory), 2, 'owner sees own business directory');
select is((select opening_balance from customers where id = '52000000-0000-4000-8000-000000000014'), 10000::bigint, 'owner retains opening balance access');
select record_payment(jsonb_build_object(
  'id', '55000000-0000-4000-8000-000000000001',
  'customer_id', '52000000-0000-4000-8000-000000000014',
  'amount', 1000, 'method', 'cash'
));

select test_set_auth('50000000-0000-4000-8000-000000000012');
select is((select count(*)::int from customer_directory), 2, 'sales sees own business directory');
select is((select count(*)::int from customer_balances), 2, 'sales retains financial access');

select test_set_auth('50000000-0000-4000-8000-000000000013');
select is((select count(*)::int from customer_directory), 2, 'warehouse sees billing identities');
select is((select shop_name from customer_directory where customer_id = '52000000-0000-4000-8000-000000000014'), 'Ram Store', 'warehouse can select a customer by ID');
select is_empty($$select opening_balance from customers$$, 'warehouse cannot read raw opening balances');
select is_empty($$select * from customer_balances$$, 'warehouse cannot read balances');
select is_empty($$select * from customer_ledger_entries$$, 'warehouse cannot read ledger');
select is_empty($$select * from payments$$, 'warehouse cannot read payments');
select is_empty($$select * from customer_dues_aging$$, 'warehouse cannot read dues aging');
select is_empty($$select * from customer_balance_projections$$, 'warehouse cannot read gated projections');
select is_empty($$select * from customer_directory where customer_id = '52000000-0000-4000-8000-000000000017'$$, 'warehouse cannot read another tenant by customer ID');
select is_empty($$select * from customer_directory where business_id = '50000000-0000-4000-8000-000000000002'$$, 'warehouse cannot filter into another tenant');
select is(
  (create_bill(jsonb_build_object(
    'id', '54000000-0000-4000-8000-000000000001',
    'customer_id', '52000000-0000-4000-8000-000000000014',
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', '53000000-0000-4000-8000-000000000001',
      'name_snapshot', 'Rice', 'qty', 1, 'rate', 2500, 'discount', 0
    ))
  ))->'bill'->>'status'), 'due', 'warehouse can create a customer bill without payment'
);
select is(
  (select d.shop_name from bills b join customer_directory d on d.customer_id = b.customer_id where b.id = '54000000-0000-4000-8000-000000000001'),
  'Ram Store', 'warehouse can reopen a bill with its customer identity'
);
select is((select line_total from bill_items where bill_id = '54000000-0000-4000-8000-000000000001'), 2500::bigint, 'warehouse can read immutable bill items');
select is(jsonb_array_length(search_bills('Ram Store')), 1, 'warehouse can search bills by customer name');
select is(search_bills('Ram Store')->0->'customers'->>'shop_name', 'Ram Store', 'warehouse bill search preserves customer identity');
select throws_ok(
  $$select create_bill(jsonb_build_object(
    'customer_id', '52000000-0000-4000-8000-000000000014',
    'items', jsonb_build_array(jsonb_build_object('name_snapshot', 'Rice', 'qty', 1, 'rate', 2500)),
    'payment', jsonb_build_object('amount', 2500, 'method', 'cash')
  ))$$,
  'P0001', 'warehouse cannot record payment with bill', 'warehouse cannot embed a payment'
);
select throws_ok(
  $$select record_payment(jsonb_build_object('customer_id', '52000000-0000-4000-8000-000000000014', 'amount', 100, 'method', 'cash'))$$,
  'P0001', 'forbidden', 'warehouse cannot call payment RPC'
);
select throws_ok(
  $$update customer_directory set shop_name = 'Unauthorized' where customer_id = '52000000-0000-4000-8000-000000000014'$$,
  '42501', null, 'identity directory is read-only'
);
select is(
  (select count(*)::int from information_schema.columns where table_schema = 'public' and table_name = 'customer_directory' and column_name in ('opening_balance', 'balance_due', 'total_paid', 'total_billed')),
  0, 'directory does not expose financial columns'
);

select test_set_auth('50000000-0000-4000-8000-000000000014');
select is((select count(*)::int from customer_directory), 1, 'customer directory is own-profile only');
select is(jsonb_array_length(search_bills('Ram Store')), 1, 'customer can search own bills');
select is_empty($$select * from customer_directory where customer_id = '52000000-0000-4000-8000-000000000015'$$, 'customer cannot read another customer in same tenant');
select is((select balance_due::bigint from customer_balances), 11500::bigint, 'customer retains own financial access after warehouse billing');
select throws_ok(
  $$select create_bill(jsonb_build_object('items', jsonb_build_array(jsonb_build_object('name_snapshot', 'Rice', 'qty', 1, 'rate', 2500))))$$,
  'P0001', 'forbidden', 'customer cannot create bills'
);

select test_set_auth('50000000-0000-4000-8000-000000000016');
select is((select count(*)::int from customer_directory), 1, 'other owner only sees own tenant directory');
select is_empty($$select * from customer_directory where customer_id = '52000000-0000-4000-8000-000000000014'$$, 'other owner cannot read first tenant identity');
select is_empty($$select * from bills where id = '54000000-0000-4000-8000-000000000001'$$, 'other owner cannot read warehouse bill');
select is(jsonb_array_length(search_bills('Ram Store')), 0, 'bill search cannot cross tenants');

reset role;
update members set is_active = false where id = '51000000-0000-4000-8000-000000000013';
select test_set_auth('50000000-0000-4000-8000-000000000013');
select is_empty($$select * from customer_directory$$, 'deactivated warehouse cannot read directory');
select is_empty($$select * from bills$$, 'deactivated warehouse cannot read bills');
select is(jsonb_array_length(search_bills('Ram Store')), 0, 'deactivated warehouse cannot search bills');

reset role;
select set_config('request.jwt.claim.sub', '', true);
set local role anon;
select throws_ok($$select * from customer_directory$$, '42501', null, 'anonymous cannot read directory');
reset role;
select ok(
  not has_table_privilege('authenticated', 'customer_directory', 'INSERT')
  and not has_table_privilege('authenticated', 'customer_directory', 'UPDATE')
  and not has_table_privilege('authenticated', 'customer_directory', 'DELETE'),
  'directory grants no client mutation privileges'
);

select * from finish();
rollback;
