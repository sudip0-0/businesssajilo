-- RLS tests for Phase 6 notifications.
begin;
select plan(7);

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

-- Customer places order -> staff notifications.
select test_set_auth('55555555-5555-5555-5555-555555555555');

insert into orders (id, business_id, customer_id, status)
values ('01111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 'placed');

select test_set_auth('22222222-2222-2222-2222-222222222222');

select is(
  (select count(*)::int from notifications where type = 'order_placed'),
  1,
  'owner sees own order_placed notification'
);

select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select count(*)::int from notifications where type = 'order_placed'),
  1,
  'sales sees own order_placed notification'
);

-- Sales sends quote -> customer notification.
select test_set_auth('33333333-3333-3333-3333-333333333333');

insert into quotes (id, order_id, version, status, total, created_by)
values ('03111111-1111-1111-1111-111111111111', '01111111-1111-1111-1111-111111111111', 1, 'sent', 25000, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select count(*)::int from notifications where type = 'quote_received'),
  1,
  'customer receives quote_received notification'
);

-- Customer accepts quote -> sales notification.
update quotes set status = 'accepted' where id = '03111111-1111-1111-1111-111111111111';

select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select count(*)::int from notifications where type = 'quote_accepted' and recipient_member_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  1,
  'sales receives quote_accepted notification'
);

-- Recipient can mark read.
update notifications
set read_at = now()
where recipient_member_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  and type = 'quote_accepted'
  and read_at is null;

select isnt(
  (select read_at from notifications where type = 'quote_accepted' and recipient_member_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' limit 1),
  null,
  'recipient can mark notification read'
);

-- Client cannot insert notifications directly.
select test_set_auth('33333333-3333-3333-3333-333333333333');

select throws_ok(
  $$insert into notifications (business_id, recipient_member_id, type)
    values ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'order_placed')$$,
  '42501',
  null,
  'client cannot insert notifications'
);

-- Cannot read another member notifications.
select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select count(*)::int from notifications where recipient_member_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  0,
  'customer cannot read staff notifications'
);

select * from finish();
rollback;
