-- pgTAP tests for Migration 62: reconcile_stock_count & create_product_with_stock
-- (per-role allow + deny, idempotency, retry mismatch, tenant isolation, warehouse privacy).
begin;
select no_plan();

insert into businesses (id, name) values
  ('62000000-0000-4000-8000-000000000001', 'P2Biz A'),
  ('62000000-0000-4000-8000-000000000002', 'P2Biz B');

insert into auth.users (id, email, aud, role) values
  ('62000000-0000-4000-8000-000000000011', 'owner62a@test.invalid', 'authenticated', 'authenticated'),
  ('62000000-0000-4000-8000-000000000012', 'sales62a@test.invalid', 'authenticated', 'authenticated'),
  ('62000000-0000-4000-8000-000000000013', 'wh62a@test.invalid', 'authenticated', 'authenticated'),
  ('62000000-0000-4000-8000-000000000014', 'cust62a@test.invalid', 'authenticated', 'authenticated'),
  ('62000000-0000-4000-8000-000000000015', 'owner62b@test.invalid', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('62100000-0000-4000-8000-000000000011', '62000000-0000-4000-8000-000000000001', '62000000-0000-4000-8000-000000000011', 'owner', 'Owner A', true),
  ('62100000-0000-4000-8000-000000000012', '62000000-0000-4000-8000-000000000001', '62000000-0000-4000-8000-000000000012', 'sales', 'Sales A', true),
  ('62100000-0000-4000-8000-000000000013', '62000000-0000-4000-8000-000000000001', '62000000-0000-4000-8000-000000000013', 'warehouse', 'WH A', true),
  ('62100000-0000-4000-8000-000000000014', '62000000-0000-4000-8000-000000000001', '62000000-0000-4000-8000-000000000014', 'customer', 'Cust A', true),
  ('62100000-0000-4000-8000-000000000015', '62000000-0000-4000-8000-000000000002', '62000000-0000-4000-8000-000000000015', 'owner', 'Owner B', true);

insert into products (id, business_id, name, unit, cost_price, reference_price, stock_cached, is_active) values
  ('62300000-0000-4000-8000-000000000001', '62000000-0000-4000-8000-000000000001', 'Rice 25kg', 'bag', 180000, 220000, 10, true),
  ('62300000-0000-4000-8000-000000000002', '62000000-0000-4000-8000-000000000001', 'Lentils 1kg', 'pack', 15000, 20000, 5, true),
  ('62300000-0000-4000-8000-000000000003', '62000000-0000-4000-8000-000000000001', 'Archived Oil', 'ltr', 10000, 12000, 3, false),
  ('62300000-0000-4000-8000-000000000004', '62000000-0000-4000-8000-000000000002', 'Other Biz Flour', 'bag', 50000, 60000, 8, true);

create function pg_temp.set_auth(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- ===========================================================================
-- A. reconcile_stock_count: ALLOW + DENY per role, idempotency, privacy
-- ===========================================================================

-- 1. Warehouse can reconcile multi-item stock count atomically.
select pg_temp.set_auth('62000000-0000-4000-8000-000000000013');
select is(
  (reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000001',
    'reason', 'Monthly godown count',
    'items', jsonb_build_array(
      jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 8),
      jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000002', 'counted_qty', 5)
    )
  ))->>'created')::boolean,
  true,
  'warehouse executes multi-item stock count reconciliation'
);
select is((select stock_cached from products where id = '62300000-0000-4000-8000-000000000001'), 8, 'product 1 stock updated to 8 via append-only adjust');
select is((select stock_cached from products where id = '62300000-0000-4000-8000-000000000002'), 5, 'product 2 unchanged at 5');
select is(
  (select count(*)::int from stock_movements where reconciliation_id = '62500000-0000-4000-8000-000000000001' and type = 'adjust'),
  1,
  'only non-zero delta creates an append-only adjust movement'
);

-- 2. Replay with identical op_id + payload is idempotent (no duplicate movement, zero financial fields).
select is(
  (reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000001',
    'reason', 'Monthly godown count',
    'items', jsonb_build_array(
      jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000002', 'counted_qty', 5),
      jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 8)
    )
  ))->>'created')::boolean,
  false,
  'reconcile_stock_count replay (even reordered items) is idempotent'
);
select is((select stock_cached from products where id = '62300000-0000-4000-8000-000000000001'), 8, 'replay does not double-adjust stock');
select ok(
  not (
    (reconcile_stock_count(jsonb_build_object(
      'op_id', '62500000-0000-4000-8000-000000000001',
      'reason', 'Monthly godown count',
      'items', jsonb_build_array(
        jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 8),
        jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000002', 'counted_qty', 5)
      )
    ))->'items'->0) ?| array['cost_price', 'reference_price', 'valuation', 'balance_due']
  ),
  'reconcile_stock_count exposes zero financial fields'
);

-- 3. Mismatched retry payload with same op_id is rejected.
select throws_ok(
  $$select reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000001',
    'reason', 'Monthly godown count',
    'items', jsonb_build_array(
      jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 99)
    )
  ))$$,
  'P0001', 'reconciliation retry payload does not match', 'mismatched replay rejected'
);

-- 4. Validation: empty reason, negative/fractional qty, duplicate product, inactive product, cross-tenant product.
select throws_ok(
  $$select reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000002',
    'reason', '   ',
    'items', jsonb_build_array(jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 5))
  ))$$,
  'P0001', 'reason is required', 'blank reason rejected'
);
select throws_ok(
  $$select reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000002',
    'reason', 'Count',
    'items', jsonb_build_array(jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 2.5))
  ))$$,
  'P0001', 'counted_qty must be a non-negative integer', 'fractional counted_qty rejected'
);
select throws_ok(
  $$select reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000002',
    'reason', 'Count',
    'items', jsonb_build_array(
      jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 5),
      jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 6)
    )
  ))$$,
  'P0001', 'duplicate product_id in stock count', 'duplicate product_id rejected'
);
select throws_ok(
  $$select reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000002',
    'reason', 'Count',
    'items', jsonb_build_array(jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000003', 'counted_qty', 1))
  ))$$,
  'P0001', 'active product not found', 'inactive product rejected'
);
select throws_ok(
  $$select reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000002',
    'reason', 'Count',
    'items', jsonb_build_array(jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000004', 'counted_qty', 1))
  ))$$,
  'P0001', 'active product not found', 'cross-tenant product rejected'
);

-- 5. Owner can reconcile stock count; direct insert into stock_reconciliations denied.
select pg_temp.set_auth('62000000-0000-4000-8000-000000000011');
select is(
  (reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000003',
    'reason', 'Owner audit',
    'items', jsonb_build_array(jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000002', 'counted_qty', 12))
  ))->>'adjusted_count')::int,
  1,
  'owner executes stock count reconciliation'
);
select is((select stock_cached from products where id = '62300000-0000-4000-8000-000000000002'), 12, 'owner reconciliation updates stock_cached to 12');
select throws_ok(
  $$insert into stock_reconciliations (id, business_id, reason, created_by, total_items, adjusted_count, payload_hash, result)
    values (gen_random_uuid(), '62000000-0000-4000-8000-000000000001', 'direct', '62100000-0000-4000-8000-000000000011', 1, 0, 'x', '{}'::jsonb)$$,
  '42501', null, 'direct insert into stock_reconciliations denied'
);

-- 6. Sales & Customer DENIED reconcile_stock_count; other tenant cannot replay op_id.
select pg_temp.set_auth('62000000-0000-4000-8000-000000000012');
select throws_ok(
  $$select reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000004',
    'reason', 'Sales attempt',
    'items', jsonb_build_array(jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 1))
  ))$$,
  'P0001', 'forbidden', 'sales denied reconcile_stock_count'
);

select pg_temp.set_auth('62000000-0000-4000-8000-000000000014');
select throws_ok(
  $$select reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000004',
    'reason', 'Cust attempt',
    'items', jsonb_build_array(jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000001', 'counted_qty', 1))
  ))$$,
  'P0001', 'forbidden', 'customer denied reconcile_stock_count'
);
select is_empty($$select * from stock_reconciliations$$, 'customer cannot read stock_reconciliations');

select pg_temp.set_auth('62000000-0000-4000-8000-000000000015');
select throws_ok(
  $$select reconcile_stock_count(jsonb_build_object(
    'op_id', '62500000-0000-4000-8000-000000000001',
    'reason', 'Cross tenant hijack',
    'items', jsonb_build_array(jsonb_build_object('product_id', '62300000-0000-4000-8000-000000000004', 'counted_qty', 1))
  ))$$,
  'P0001', 'forbidden', 'other tenant cannot collide/probe tenant A reconciliation op_id'
);
select is_empty($$select * from stock_reconciliations where business_id = '62000000-0000-4000-8000-000000000001'$$, 'other tenant cannot read tenant A reconciliations');

-- ===========================================================================
-- B. create_product_with_stock: ALLOW + DENY per role, idempotency
-- ===========================================================================

-- 7. Owner creates product + opening stock atomically, and replay is idempotent.
select pg_temp.set_auth('62000000-0000-4000-8000-000000000011');
select is(
  (create_product_with_stock(jsonb_build_object(
    'op_id', '62600000-0000-4000-8000-000000000001',
    'name', 'Mustard Oil 1L',
    'unit', 'bottle',
    'cost_price', 22000,
    'reference_price', 26000,
    'low_stock_threshold', 5,
    'opening_stock', 25
  ))->'product'->>'stock_cached')::int,
  25,
  'owner atomically creates product with opening_stock = 25'
);
select is(
  (create_product_with_stock(jsonb_build_object(
    'op_id', '62600000-0000-4000-8000-000000000001',
    'name', 'Mustard Oil 1L',
    'unit', 'bottle',
    'cost_price', 22000,
    'reference_price', 26000,
    'low_stock_threshold', 5,
    'opening_stock', 25
  ))->>'created')::boolean,
  false,
  'create_product_with_stock replay with same op_id returns created=false'
);
select is(
  (select stock_cached from products where id = '62600000-0000-4000-8000-000000000001'),
  25,
  'replay does not double-add opening stock'
);
select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '62600000-0000-4000-8000-000000000001',
    'name', 'Different Product Name',
    'unit', 'bottle'
  ))$$,
  'P0001', 'product retry payload does not match', 'mismatched product replay rejected'
);
select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '62600000-0000-4000-8000-000000000002',
    'name', 'Bad Fractional',
    'unit', 'kg',
    'opening_stock', 1.5
  ))$$,
  'P0001', 'opening_stock must be a non-negative integer', 'fractional opening_stock rejected'
);

-- 8. Sales can create product with opening_stock = 0, DENIED opening_stock > 0 (product.md §4).
select pg_temp.set_auth('62000000-0000-4000-8000-000000000012');
select is(
  (create_product_with_stock(jsonb_build_object(
    'op_id', '62600000-0000-4000-8000-000000000003',
    'name', 'Sales Added Tea',
    'unit', 'pack',
    'reference_price', 15000,
    'opening_stock', 0
  ))->>'created')::boolean,
  true,
  'sales creates product with opening_stock = 0'
);
select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '62600000-0000-4000-8000-000000000004',
    'name', 'Sales Opening Stock',
    'unit', 'pack',
    'opening_stock', 10
  ))$$,
  'P0001', 'only owner can record opening stock', 'sales cannot record opening stock > 0'
);

-- 9. Warehouse & Customer DENIED create_product_with_stock.
select pg_temp.set_auth('62000000-0000-4000-8000-000000000013');
select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '62600000-0000-4000-8000-000000000005',
    'name', 'WH Product',
    'unit', 'piece'
  ))$$,
  'P0001', 'forbidden', 'warehouse denied create_product_with_stock'
);

select pg_temp.set_auth('62000000-0000-4000-8000-000000000014');
select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '62600000-0000-4000-8000-000000000006',
    'name', 'Cust Product',
    'unit', 'piece'
  ))$$,
  'P0001', 'forbidden', 'customer denied create_product_with_stock'
);

-- 10. Other tenant cannot replay tenant A op_id; anon cannot call either RPC.
select pg_temp.set_auth('62000000-0000-4000-8000-000000000015');
select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '62600000-0000-4000-8000-000000000001',
    'name', 'Mustard Oil 1L',
    'unit', 'bottle'
  ))$$,
  'P0001', 'forbidden', 'other tenant cannot probe tenant A product op_id'
);

reset role;
select set_config('request.jwt.claim.sub', '', true);
set local role anon;
select throws_ok($$select reconcile_stock_count('{}'::jsonb)$$, '42501', null, 'anon cannot call reconcile_stock_count');
select throws_ok($$select create_product_with_stock('{}'::jsonb)$$, '42501', null, 'anon cannot call create_product_with_stock');

select * from finish();
rollback;
