-- Storage policy tests for product-images bucket.
begin;
select plan(4);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', 'wh@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'warehouse', 'WH', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Seed storage object as service role, then test reads as tenant roles.
set local role service_role;

insert into storage.objects (bucket_id, name, owner, metadata)
values (
  'product-images',
  '11111111-1111-1111-1111-111111111111/test.jpg',
  '22222222-2222-2222-2222-222222222222',
  '{}'::jsonb
);

-- Owner can read tenant product image objects.
select test_set_auth('22222222-2222-2222-2222-222222222222');

select is(
  (select count(*)::int from storage.objects where bucket_id = 'product-images'),
  1,
  'owner reads product-images in tenant folder'
);

-- Warehouse cannot upload to product-images.
select test_set_auth('44444444-4444-4444-4444-444444444444');

select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner, metadata)
    values ('product-images', '11111111-1111-1111-1111-111111111111/wh.jpg', '44444444-4444-4444-4444-444444444444', '{}'::jsonb)$$,
  '42501',
  null,
  'warehouse cannot upload product images'
);

-- Customer cannot read product-images.
select test_set_auth('55555555-5555-5555-5555-555555555555');

select is(
  (select count(*)::int from storage.objects where bucket_id = 'product-images'),
  0,
  'customer cannot read product images'
);

-- Cross-bucket access denied.
select is(
  (select count(*)::int from storage.objects where bucket_id = 'order-chat-images'),
  0,
  'customer cannot read other buckets'
);

select * from finish();
rollback;
