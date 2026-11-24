-- pgTAP tests for Migration 60: security hardening (allow + deny per role).
begin;
select no_plan();

insert into businesses (id, name, subscription_plan) values
  ('60000000-0000-4000-8000-000000000001', 'SecBiz A', 'free'),
  ('60000000-0000-4000-8000-000000000002', 'SecBiz B', 'free');

insert into auth.users (id, email, aud, role) values
  ('60000000-0000-4000-8000-000000000011', 'owner60a@test.invalid', 'authenticated', 'authenticated'),
  ('60000000-0000-4000-8000-000000000012', 'sales60a@test.invalid', 'authenticated', 'authenticated'),
  ('60000000-0000-4000-8000-000000000013', 'wh60a@test.invalid', 'authenticated', 'authenticated'),
  ('60000000-0000-4000-8000-000000000014', 'cust60a@test.invalid', 'authenticated', 'authenticated'),
  ('60000000-0000-4000-8000-000000000015', 'owner60b@test.invalid', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('60100000-0000-4000-8000-000000000011', '60000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000011', 'owner', 'Owner A', true),
  ('60100000-0000-4000-8000-000000000012', '60000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000012', 'sales', 'Sales A', true),
  ('60100000-0000-4000-8000-000000000013', '60000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000013', 'warehouse', 'WH A', true),
  ('60100000-0000-4000-8000-000000000014', '60000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000014', 'customer', 'Cust A', true),
  ('60100000-0000-4000-8000-000000000015', '60000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000015', 'owner', 'Owner B', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('60200000-0000-4000-8000-000000000014', '60000000-0000-4000-8000-000000000001', '60100000-0000-4000-8000-000000000014', 'Alpha 100% Mart', 0);

insert into products (id, business_id, name, unit, cost_price, reference_price, stock_cached, is_active) values
  ('60300000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', 'Widget 50% Off', 'piece', 500, 1000, 10, true),
  ('60300000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000001', 'Plain Sugar', 'kg', 100, 200, 10, true),
  ('60300000-0000-4000-8000-000000000003', '60000000-0000-4000-8000-000000000002', 'Secret Tenant B Item', 'box', 900, 1500, 99, true);

insert into bills (id, business_id, customer_id, items_total, discount, grand_total, status, created_by, bill_no) values
  ('60400000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', '60200000-0000-4000-8000-000000000014', 2000, 0, 2000, 'due', '60100000-0000-4000-8000-000000000011', 'BS-6001'),
  ('60400000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000002', null, 1500, 0, 1500, 'paid', '60100000-0000-4000-8000-000000000015', 'BS-6002');

insert into bill_items (id, bill_id, product_id, name_snapshot, qty, rate, discount, line_total) values
  ('60410000-0000-4000-8000-000000000001', '60400000-0000-4000-8000-000000000001', '60300000-0000-4000-8000-000000000001', 'Widget 50% Off', 2, 1000, 0, 2000);

insert into notifications (id, business_id, recipient_member_id, type, payload) values
  ('60500000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', '60100000-0000-4000-8000-000000000014', 'order_received', '{"order_id":"1"}'::jsonb);

create function pg_temp.set_auth(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- 1. catalog_products is strictly tenant-scoped and read-only.
select pg_temp.set_auth('60000000-0000-4000-8000-000000000014');
select is(
  (select count(*)::int from catalog_products where business_id = '60000000-0000-4000-8000-000000000002'),
  0,
  'customer cannot see tenant B products via catalog_products'
);
select is(
  (select count(*)::int from catalog_products where business_id = '60000000-0000-4000-8000-000000000001'),
  2,
  'customer sees only own-tenant active products via catalog_products'
);
select throws_ok(
  $$delete from catalog_products where id = '60300000-0000-4000-8000-000000000001'$$,
  '42501', null, 'catalog_products is read-only for authenticated'
);

-- 2. Internal SECURITY DEFINER helpers cannot be called by authenticated or anon.
select throws_ok(
  $$select insert_notification('60000000-0000-4000-8000-000000000002', '60100000-0000-4000-8000-000000000015', 'payment_recorded', '{}'::jsonb)$$,
  '42501', null, 'customer cannot call insert_notification'
);
select throws_ok(
  $$select refresh_bill_status_for('60400000-0000-4000-8000-000000000002')$$,
  '42501', null, 'customer cannot call refresh_bill_status_for'
);

select pg_temp.set_auth('60000000-0000-4000-8000-000000000011');
select throws_ok(
  $$select insert_notification('60000000-0000-4000-8000-000000000001', '60100000-0000-4000-8000-000000000011', 'low_stock', '{}'::jsonb)$$,
  '42501', null, 'owner cannot call insert_notification directly'
);
select throws_ok(
  $$select refresh_bill_status_for('60400000-0000-4000-8000-000000000001')$$,
  '42501', null, 'owner cannot call refresh_bill_status_for directly'
);
select throws_ok(
  $$select insert_audit_log('products', '60300000-0000-4000-8000-000000000001', 'name', 'a', 'b', 'sync_lww')$$,
  '42501', null, 'owner cannot call insert_audit_log directly'
);
select throws_ok(
  $$select * from credit_note_sequences$$,
  '42501', null, 'authenticated cannot read credit_note_sequences'
);

-- 3. Notifications column pinning: recipient may mark read_at, cannot tamper payload/type/pushed_at.
select pg_temp.set_auth('60000000-0000-4000-8000-000000000014');
select lives_ok(
  $$update notifications set read_at = now() where id = '60500000-0000-4000-8000-000000000001'$$,
  'recipient can mark own notification read'
);
select throws_ok(
  $$update notifications set payload = '{"tampered":true}'::jsonb where id = '60500000-0000-4000-8000-000000000001'$$,
  'P0001', 'only read_at can be updated on notifications', 'recipient cannot tamper notification payload'
);
select throws_ok(
  $$update notifications set type = 'payment_recorded' where id = '60500000-0000-4000-8000-000000000001'$$,
  'P0001', 'only read_at can be updated on notifications', 'recipient cannot tamper notification type'
);

-- 4. Businesses column pinning: owner can update name, cannot self-upgrade subscription_plan.
select pg_temp.set_auth('60000000-0000-4000-8000-000000000011');
select lives_ok(
  $$update businesses set address = 'Kathmandu' where id = '60000000-0000-4000-8000-000000000001'$$,
  'owner can update business profile fields'
);
select throws_ok(
  $$update businesses set subscription_plan = 'enterprise' where id = '60000000-0000-4000-8000-000000000001'$$,
  'P0001', 'business identity and subscription plan cannot be changed directly', 'owner cannot self-upgrade subscription_plan'
);

-- 5. Products stock_cached direct-write guard for owner & sales.
select throws_ok(
  $$update products set stock_cached = 9999 where id = '60300000-0000-4000-8000-000000000001'$$,
  'P0001', 'stock_cached is managed by stock_movements', 'owner cannot tamper stock_cached directly'
);
select throws_ok(
  $$insert into products (business_id, name, unit, stock_cached) values ('60000000-0000-4000-8000-000000000001', 'DirectStock', 'piece', 50)$$,
  'P0001', 'stock_cached is managed by stock_movements', 'owner cannot insert product with non-zero stock_cached directly'
);
select lives_ok(
  $$insert into products (business_id, name, unit) values ('60000000-0000-4000-8000-000000000001', 'ZeroStock', 'piece')$$,
  'owner can insert product with default zero stock_cached'
);
select pg_temp.set_auth('60000000-0000-4000-8000-000000000012');
select throws_ok(
  $$update products set stock_cached = 500 where id = '60300000-0000-4000-8000-000000000001'$$,
  'P0001', 'stock_cached is managed by stock_movements', 'sales cannot tamper stock_cached directly'
);

-- 6. Stock movements cross-tenant ref_bill_id guard.
select pg_temp.set_auth('60000000-0000-4000-8000-000000000013');
select throws_ok(
  $$insert into stock_movements (business_id, product_id, type, qty_delta, reason, ref_bill_id, created_by)
    values ('60000000-0000-4000-8000-000000000001', '60300000-0000-4000-8000-000000000001', 'adjust', 1, 'probe', '60400000-0000-4000-8000-000000000002', '60100000-0000-4000-8000-000000000013')$$,
  'P0001', 'bill does not belong to this business', 'warehouse cannot link cross-tenant ref_bill_id in stock_movements'
);

-- 7. Credit note duplicate bill_item_id bypass is blocked.
select pg_temp.set_auth('60000000-0000-4000-8000-000000000011');
select throws_ok(
  $$select create_credit_note(jsonb_build_object(
    'bill_id', '60400000-0000-4000-8000-000000000001',
    'restock', false,
    'items', jsonb_build_array(
      jsonb_build_object('bill_item_id', '60410000-0000-4000-8000-000000000001', 'qty_returned', 2),
      jsonb_build_object('bill_item_id', '60410000-0000-4000-8000-000000000001', 'qty_returned', 1)
    )
  ))$$,
  'P0001', 'return qty exceeds remaining', 'duplicate bill_item_id cannot exceed billed qty in create_credit_note'
);

-- 8. LIKE wildcard escaping in list_products_page & search_bills.
select is(
  jsonb_array_length(list_products_page(true, '50%', 'all', 0, 50)),
  1,
  'list_products_page escapes literal percent sign instead of wildcarding all products'
);
select is(
  jsonb_array_length(list_products_page(true, '%', 'all', 0, 50)),
  1,
  'bare % only matches products literally containing %'
);
select is(
  jsonb_array_length(search_bills('100%', null, null, null, 0, 50)),
  1,
  'search_bills escapes literal percent sign cleanly'
);

-- 9. Overflow guard in create_bill and negative payment guard in record_customer_sale.
select throws_ok(
  $$select create_bill(jsonb_build_object(
    'items', jsonb_build_array(jsonb_build_object('name_snapshot', 'Huge', 'qty', 100000000, 'rate', 100000000000))
  ))$$,
  'P0001', 'item total out of range', 'create_bill rejects overflowing item total'
);
select throws_ok(
  $$select record_customer_sale(jsonb_build_object(
    'customer_id', '60200000-0000-4000-8000-000000000014',
    'amount', 1000,
    'payment', jsonb_build_object('amount', -50, 'method', 'cash')
  ))$$,
  'P0001', 'payment amount out of range', 'record_customer_sale rejects negative embedded payment'
);

-- 10. Storage path traversal rejected for owner upload.
select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner, metadata)
    values ('product-images', '60000000-0000-4000-8000-000000000001/../60000000-0000-4000-8000-000000000002/evil.jpg', '60000000-0000-4000-8000-000000000011', '{}'::jsonb)$$,
  '42501', null, 'storage policy rejects .. path traversal'
);

-- 11. Anon role cannot execute authenticated RPCs or read views.
reset role;
select set_config('request.jwt.claim.sub', '', true);
set local role anon;
select throws_ok($$select * from catalog_products$$, '42501', null, 'anon cannot read catalog_products');
select throws_ok($$select owner_dashboard_stats()$$, '42501', null, 'anon cannot call owner_dashboard_stats');
select throws_ok($$select create_bill('{}'::jsonb)$$, '42501', null, 'anon cannot call create_bill');

select * from finish();
rollback;
