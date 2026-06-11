-- Cross-tenant isolation: second business cannot read first business data.
begin;
select plan(4);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Biz A'),
  ('22222222-2222-2222-2222-222222222222', 'Biz B');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'owner-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'owner-b@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc01', 'cust-a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'owner', 'Owner A', true),
  ('b1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'owner', 'Owner B', true),
  ('ca111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'cccccccc-cccc-cccc-cccc-cccccccccc01', 'customer', 'Cust A', true);

insert into categories (id, business_id, name) values
  ('c1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Beverages');

insert into products (id, business_id, category_id, name, unit, cost_price, reference_price, stock_cached) values
  ('d1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'Cola', 'piece', 3000, 5000, 10);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'ca111111-1111-1111-1111-111111111111', 'Ram Store', 0);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- Owner B cannot read Biz A products.
select test_set_auth('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

select is(
  (select count(*)::int from products),
  0,
  'owner B cannot read Biz A products'
);

select is(
  (select count(*)::int from customers),
  0,
  'owner B cannot read Biz A customers'
);

-- Owner A creates a bill.
select test_set_auth('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

insert into bills (id, business_id, customer_id, items_total, discount, grand_total, status, created_by)
values ('f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 5000, 0, 5000, 'due', 'a1111111-1111-1111-1111-111111111111');

select is(
  (select count(*)::int from bills),
  1,
  'owner A reads own bills'
);

-- Owner B still cannot read Biz A bills.
select test_set_auth('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

select is(
  (select count(*)::int from bills),
  0,
  'owner B cannot read Biz A bills'
);

select * from finish();
rollback;
