-- report_dues_aging RPC aggregates customer_dues_aging server-side.
begin;
select plan(4);

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

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select test_set_auth('22222222-2222-2222-2222-222222222222');

insert into bills (id, business_id, customer_id, items_total, discount, grand_total, status, created_by)
values (
  'f1111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111',
  'e1111111-1111-1111-1111-111111111111',
  5000, 0, 5000, 'due',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
);

-- Owner can call RPC and see bucket totals.
select is(
  (select (report_dues_aging()->>'bucket_0_30')::bigint),
  5000::bigint,
  'owner sees dues in 0_30 bucket'
);

select is(
  (select jsonb_array_length(report_dues_aging()->'customers')),
  1,
  'owner sees one aging customer row'
);

-- Warehouse cannot see dues (empty / zero via invoker RLS on view).
select test_set_auth('44444444-4444-4444-4444-444444444444');
select is(
  (select (report_dues_aging()->>'bucket_0_30')::bigint),
  0::bigint,
  'warehouse sees zero dues aging'
);

-- Customer cannot see other customers' dues.
select test_set_auth('55555555-5555-5555-5555-555555555555');
select is(
  (select (report_dues_aging()->>'bucket_0_30')::bigint),
  0::bigint,
  'customer sees zero dues aging'
);

select * from finish();
rollback;
