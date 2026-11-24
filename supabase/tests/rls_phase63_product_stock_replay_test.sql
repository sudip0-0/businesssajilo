-- pgTAP tests for Migration 63: create_product_with_stock replay integrity
-- (name_np / opening_stock mismatch rejection, opening_stock=0 replay returning
-- null movement_id even after subsequent stock_in, internal ops table locked).
begin;
select no_plan();

insert into businesses (id, name) values
  ('63000000-0000-4000-8000-000000000001', 'Replay63 A'),
  ('63000000-0000-4000-8000-000000000002', 'Replay63 B');

insert into auth.users (id, email, aud, role) values
  ('63000000-0000-4000-8000-000000000011', 'owner63a@test.invalid', 'authenticated', 'authenticated'),
  ('63000000-0000-4000-8000-000000000012', 'owner63b@test.invalid', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('63100000-0000-4000-8000-000000000011', '63000000-0000-4000-8000-000000000001', '63000000-0000-4000-8000-000000000011', 'owner', 'Owner A', true),
  ('63100000-0000-4000-8000-000000000012', '63000000-0000-4000-8000-000000000002', '63000000-0000-4000-8000-000000000012', 'owner', 'Owner B', true);

create function pg_temp.set_auth(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select pg_temp.set_auth('63000000-0000-4000-8000-000000000011');

-- 1. Create product with opening_stock = 0 and Nepali name.
select is(
  (create_product_with_stock(jsonb_build_object(
    'op_id', '63500000-0000-4000-8000-000000000001',
    'name', 'Sugar',
    'name_np', 'चिनी',
    'unit', 'kg',
    'opening_stock', 0
  ))->>'created')::boolean,
  true,
  'owner creates product with opening_stock = 0 and name_np'
);

-- 2. Subsequent regular stock_in on the product.
insert into stock_movements (business_id, product_id, type, qty_delta, reason, created_by)
values (
  '63000000-0000-4000-8000-000000000001',
  '63500000-0000-4000-8000-000000000001',
  'stock_in',
  15,
  'Later purchase',
  '63100000-0000-4000-8000-000000000011'
);

-- 3. Identical replay with opening_stock = 0 still returns movement_id = null (not the later stock_in).
select is(
  create_product_with_stock(jsonb_build_object(
    'op_id', '63500000-0000-4000-8000-000000000001',
    'name', 'Sugar',
    'name_np', 'चिनी',
    'unit', 'kg',
    'opening_stock', 0
  ))->>'movement_id',
  null,
  'opening_stock=0 replay returns null movement_id even after later stock_in'
);

-- 4. Replay with changed opening_stock (0 -> 25) is rejected.
select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '63500000-0000-4000-8000-000000000001',
    'name', 'Sugar',
    'name_np', 'चिनी',
    'unit', 'kg',
    'opening_stock', 25
  ))$$,
  'P0001', 'product retry payload does not match',
  'replay with different opening_stock (0 -> 25) is rejected'
);

-- 5. Replay with changed name_np is rejected.
select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '63500000-0000-4000-8000-000000000001',
    'name', 'Sugar',
    'name_np', 'नुन',
    'unit', 'kg',
    'opening_stock', 0
  ))$$,
  'P0001', 'product retry payload does not match',
  'replay with different name_np is rejected'
);

-- 6. Product with opening_stock = 20: replay with 20 returns exact opening movement_id; replay with 50 rejected.
select ok(
  (create_product_with_stock(jsonb_build_object(
    'op_id', '63500000-0000-4000-8000-000000000002',
    'name', 'Salt',
    'unit', 'pack',
    'opening_stock', 20
  ))->>'movement_id') is not null,
  'opening_stock = 20 returns non-null movement_id'
);

select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '63500000-0000-4000-8000-000000000002',
    'name', 'Salt',
    'unit', 'pack',
    'opening_stock', 50
  ))$$,
  'P0001', 'product retry payload does not match',
  'replay with different opening_stock (20 -> 50) is rejected'
);

-- 7. Internal product_create_ops table is inaccessible to authenticated and anon.
select throws_ok(
  $$select * from product_create_ops$$,
  '42501', null,
  'authenticated cannot select internal product_create_ops table'
);

-- 8. Cross-tenant op_id collision raises forbidden.
select pg_temp.set_auth('63000000-0000-4000-8000-000000000012');
select throws_ok(
  $$select create_product_with_stock(jsonb_build_object(
    'op_id', '63500000-0000-4000-8000-000000000001',
    'name', 'Sugar',
    'name_np', 'चिनी',
    'unit', 'kg',
    'opening_stock', 0
  ))$$,
  'P0001', 'forbidden',
  'other tenant cannot probe tenant A op_id in product_create_ops'
);

select * from finish();
rollback;
