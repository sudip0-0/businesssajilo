-- RLS tests for Phase 1 tenancy and roles.
-- Run: supabase test db

begin;
select plan(8);

-- Seed tenant data (runs as superuser during tests).
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

insert into customers (id, business_id, member_id, shop_name) values
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Cust Shop');

-- Helper: impersonate authenticated user.
create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Owner can read all co-members.
select test_set_auth('22222222-2222-2222-2222-222222222222');

select is(
  (select count(*)::int from members where business_id = '11111111-1111-1111-1111-111111111111'),
  4,
  'owner reads all co-members'
);

select is(
  (select current_role_name()::text),
  'owner',
  'owner role helper works'
);

-- Sales can read co-members.
select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select count(*)::int from members),
  4,
  'sales reads co-members'
);

-- Sales cannot update business (RLS filters rows — 0 updated).
update businesses set name = 'Hacked' where id = '11111111-1111-1111-1111-111111111111';
select is(
  (select name from businesses where id = '11111111-1111-1111-1111-111111111111'),
  'Test Biz',
  'sales cannot update business'
);

-- Warehouse cannot insert customers.
select test_set_auth('44444444-4444-4444-4444-444444444444');

select throws_ok(
  $$insert into customers (business_id, member_id, shop_name)
    values ('11111111-1111-1111-1111-111111111111', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'X')$$,
  '42501',
  null,
  'warehouse cannot insert customers'
);

-- Customer reads own customer row.
select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select shop_name from customers where member_id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
  'Cust Shop',
  'customer reads own profile'
);

-- Deactivated member loses business context.
select test_set_auth('22222222-2222-2222-2222-222222222222');
update members set is_active = false where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  current_business_id(),
  null,
  'deactivated member has null business_id'
);

-- Owner can deactivate co-member.
select test_set_auth('22222222-2222-2222-2222-222222222222');

update members set is_active = false where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
select is(
  (select is_active from members where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  false,
  'owner can deactivate co-member'
);

select * from finish();
rollback;
