-- Indexes, search_bills, and list_products_page for QoL optimization.
begin;
select plan(6);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz'),
  ('22222222-2222-2222-2222-222222222222', 'Other Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner36@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'other36@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'owner', 'Other', true);

insert into products (id, business_id, name, unit, reference_price, low_stock_threshold, stock_cached, is_active) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000, 5, 2, true),
  ('b2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Water', 'piece', 2000, 0, 20, true),
  ('b3333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 'Other Cola', 'piece', 5000, 5, 1, true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('c1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Ram Traders', 0);

insert into bills (id, business_id, created_by, customer_id, status, items_total, discount, grand_total)
values
  ('d1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'c1111111-1111-1111-1111-111111111111', 'due', 1000, 0, 1000),
  ('d2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'c1111111-1111-1111-1111-111111111111', 'paid', 500, 0, 500);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select has_index(
  'notifications',
  'notifications_unread_recipient_idx',
  'unread notifications have a partial index'
);

select test_set_auth('22222222-2222-2222-2222-222222222222');

select is(
  (select jsonb_array_length(list_products_page(true, null, 'low', 0, 50))),
  1,
  'owner sees only own low-stock products'
);

select is(
  (select jsonb_array_length(search_bills('Ram', null, null, null, 0, 50))),
  2,
  'bill search matches customer shop name'
);

select is(
  (select jsonb_array_length(search_bills(null, 'due', null, null, 0, 50))),
  1,
  'bill search filters by status'
);

select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (select jsonb_array_length(list_products_page(true, null, 'low', 0, 50))),
  1,
  'other tenant cannot see first business products'
);

select is(
  (select jsonb_array_length(search_bills('Ram', null, null, null, 0, 50))),
  0,
  'bill search is tenant-scoped'
);

select * from finish();
rollback;
