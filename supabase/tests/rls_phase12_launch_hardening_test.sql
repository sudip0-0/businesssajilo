-- Phase 12 launch hardening tests: must_change_password flag, phone
-- uniqueness, account deletion helpers.
-- Run: supabase test db

begin;
select plan(13);

-- Seed two tenants (runs as superuser during tests).
insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Biz A'),
  ('99999999-9999-9999-9999-999999999999', 'Biz B');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'sales-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('66666666-6666-6666-6666-666666666666', 'owner-b@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('77777777-7777-7777-7777-777777777777', 'spare-b@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, phone, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner A', '+9779800000001', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'sales', 'Sales A', '+9779800000002', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust A', '+9779800000003', true),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '99999999-9999-9999-9999-999999999999', '66666666-6666-6666-6666-666666666666', 'owner', 'Owner B', '+9779800000004', true);

insert into customers (id, business_id, member_id, shop_name, contact_name, phone) values
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Cust Shop', 'Ram', '+9779800000003');

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- 1. Phone uniqueness across tenants.
select throws_ok(
  $$insert into members (business_id, auth_user_id, role, display_name, phone)
    values ('99999999-9999-9999-9999-999999999999',
            '77777777-7777-7777-7777-777777777777',
            'sales', 'Dup Phone', '+9779800000001')$$,
  '23505',
  null,
  'phone numbers are globally unique across tenants'
);

-- 2. must_change_password defaults to false.
select is(
  (select must_change_password from members where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  false,
  'must_change_password defaults false'
);

-- Service role path sets the flag (simulating reset-member-password).
update members set must_change_password = true
where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

-- 3. Member clears their own flag via RPC.
select test_set_auth('33333333-3333-3333-3333-333333333333');
select lives_ok(
  $$select clear_must_change_password()$$,
  'member can call clear_must_change_password'
);

select is(
  (select must_change_password from members where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  false,
  'flag cleared for own row'
);

-- 4. RPC only clears the caller's row, never another member's.
reset role;
update members set must_change_password = true
where id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
select test_set_auth('33333333-3333-3333-3333-333333333333');
select clear_must_change_password();
reset role;
select is(
  (select must_change_password from members where id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
  true,
  'clear_must_change_password does not touch other members'
);

-- 5. Authenticated users cannot call service-role-only helpers.
select test_set_auth('22222222-2222-2222-2222-222222222222');
select throws_ok(
  $$select revoke_member_sessions('33333333-3333-3333-3333-333333333333')$$,
  '42501',
  null,
  'authenticated cannot revoke sessions directly'
);

select throws_ok(
  $$select anonymize_member_for_deletion('dddddddd-dddd-dddd-dddd-dddddddddddd')$$,
  '42501',
  null,
  'authenticated cannot anonymize members directly'
);

select throws_ok(
  $$select purge_business('11111111-1111-1111-1111-111111111111')$$,
  '42501',
  null,
  'authenticated cannot purge businesses directly'
);

-- 6. Anonymization keeps the customer shop record but scrubs identity.
reset role;
select is(
  (select anonymize_member_for_deletion('dddddddd-dddd-dddd-dddd-dddddddddddd')),
  '55555555-5555-5555-5555-555555555555'::uuid,
  'anonymize returns the auth_user_id'
);

select is(
  (select display_name from members where id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
  'Deleted account',
  'anonymized member display name scrubbed'
);

select is(
  (select contact_name is null and phone is null from customers where id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'),
  true,
  'customer personal contact data scrubbed'
);

-- 7. Business purge removes every tenant row.
select is(
  (select array_length(purge_business('99999999-9999-9999-9999-999999999999'), 1)),
  1,
  'purge returns member auth ids'
);

select is(
  (select count(*)::int
   from (
     select id from businesses where id = '99999999-9999-9999-9999-999999999999'
     union all
     select id from members where business_id = '99999999-9999-9999-9999-999999999999'
   ) leftovers),
  0,
  'purged business leaves no rows'
);

select * from finish();
rollback;
