-- RLS tests for Phase 7 offline sync.
begin;
select plan(4);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'sales@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'sales', 'Sales', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', 0);

insert into categories (id, business_id, name) values
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Beverages');

insert into products (id, business_id, category_id, name, unit, reference_price) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- customers.updated_at bump
select test_set_auth('22222222-2222-2222-2222-222222222222');

update customers
  set updated_at = '2020-01-01'::timestamptz
  where id = 'e1111111-1111-1111-1111-111111111111';

update customers
  set shop_name = 'Ram Store Updated'
  where id = 'e1111111-1111-1111-1111-111111111111';

select ok(
  (select updated_at > '2020-01-01'::timestamptz
   from customers where id = 'e1111111-1111-1111-1111-111111111111'),
  'customers updated_at bumps on update'
);

-- Staff can read audit log via service-role helper insert + select.
-- insert_audit_log is no longer executable by authenticated clients.
set local role service_role;
select insert_audit_log('products', 'b1111111-1111-1111-1111-111111111111', 'name', 'Cola', 'Cola New', 'sync_lww');
reset role;
select test_set_auth('22222222-2222-2222-2222-222222222222');

select is(
  (select count(*)::int from audit_log where table_name = 'products'),
  1,
  'owner reads audit log in tenant'
);

select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select count(*)::int from audit_log),
  1,
  'sales reads audit log in tenant'
);

-- Customer cannot read audit log.
select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select count(*)::int from audit_log),
  0,
  'customer cannot read audit log'
);

select * from finish();
rollback;
