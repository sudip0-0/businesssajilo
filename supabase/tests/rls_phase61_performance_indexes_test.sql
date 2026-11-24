-- pgTAP tests for Migration 61: performance indexes + InitPlan views & dashboard parity.
begin;
select no_plan();

-- Verify composite & partial indexes exist on hot query paths.
select has_index('bills', 'bills_business_status_created_idx', 'bills status/date index exists');
select has_index('bills', 'bills_business_customer_created_idx', 'bills customer/date partial index exists');
select has_index('orders', 'orders_business_created_idx', 'orders tenant/date index exists');
select has_index('orders', 'orders_business_status_created_idx', 'orders status/date index exists');
select has_index('orders', 'orders_business_customer_created_idx', 'orders customer/date index exists');
select has_index('payments', 'payments_business_customer_created_idx', 'payments customer/date index exists');
select has_index('credit_notes', 'credit_notes_business_created_idx', 'credit_notes tenant/date index exists');
select has_index('credit_notes', 'credit_notes_business_customer_created_idx', 'credit_notes customer/date index exists');
select has_index('stock_movements', 'stock_movements_business_product_created_idx', 'stock_movements product/date index exists');
select has_index('notifications', 'notifications_business_type_created_idx', 'notifications nudge-dedup index exists');
select has_index('notifications', 'notifications_business_recipient_created_idx', 'notifications recipient/date index exists');
select has_index('audit_log', 'audit_log_business_record_idx', 'audit_log record timeline index exists');
select has_index('customer_balance_projections', 'customer_balance_projections_business_due_idx', 'projections partial due index exists');
select has_index('products', 'products_business_active_name_idx', 'products active/name index exists');
select has_index('products', 'products_business_low_stock_idx', 'products low-stock partial index exists');
select has_index('quotes', 'quotes_business_status_created_idx', 'quotes status/date index exists');

-- Verify customer_balances, total_dues, owner_dashboard_stats parity & warehouse denial.
insert into businesses (id, name) values
  ('61000000-0000-4000-8000-000000000001', 'PerfBiz 61');

insert into auth.users (id, email, aud, role) values
  ('61000000-0000-4000-8000-000000000011', 'owner61@test.invalid', 'authenticated', 'authenticated'),
  ('61000000-0000-4000-8000-000000000013', 'wh61@test.invalid', 'authenticated', 'authenticated'),
  ('61000000-0000-4000-8000-000000000014', 'cust61@test.invalid', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('61100000-0000-4000-8000-000000000011', '61000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000011', 'owner', 'Owner61', true),
  ('61100000-0000-4000-8000-000000000013', '61000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000013', 'warehouse', 'WH61', true),
  ('61100000-0000-4000-8000-000000000014', '61000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000014', 'customer', 'Cust61', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('61200000-0000-4000-8000-000000000014', '61000000-0000-4000-8000-000000000001', '61100000-0000-4000-8000-000000000014', 'Shop 61', 2500);

insert into bills (id, business_id, customer_id, items_total, discount, grand_total, status, created_by, bill_no) values
  ('61400000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000001', '61200000-0000-4000-8000-000000000014', 5000, 0, 5000, 'due', '61100000-0000-4000-8000-000000000011', 'BS-6101');

create function pg_temp.set_auth(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select pg_temp.set_auth('61000000-0000-4000-8000-000000000011');
select is(total_dues(), 7500::bigint, 'owner total_dues reflects projection accurately');
select is((owner_dashboard_stats()->>'total_dues')::bigint, 7500::bigint, 'owner_dashboard_stats total_dues matches');
select is((select balance_due::bigint from customer_balances where customer_id = '61200000-0000-4000-8000-000000000014'), 7500::bigint, 'customer_balances view matches projection');

-- Warehouse sees 0 dues in total_dues and owner_dashboard_stats.
select pg_temp.set_auth('61000000-0000-4000-8000-000000000013');
select is(total_dues(), 0::bigint, 'warehouse gets 0 from total_dues');
select is((owner_dashboard_stats()->>'total_dues')::bigint, 0::bigint, 'warehouse gets 0 total_dues from owner_dashboard_stats');
select is_empty($$select * from customer_balances$$, 'warehouse cannot read customer_balances');

-- Customer sees own balance in customer_balances and customer_ledger_entries.
select pg_temp.set_auth('61000000-0000-4000-8000-000000000014');
select is((select balance_due::bigint from customer_balances), 7500::bigint, 'customer reads own balance_due');
select is((select count(*)::int from customer_ledger_entries), 2, 'customer reads own ledger entries');

select * from finish();
rollback;
