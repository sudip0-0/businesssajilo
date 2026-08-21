-- Phase 19 security hotfix: received_by attribution, negative stock.
-- (Order-scoped chat storage tests removed with the chat feature.)
begin;
select plan(3);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'sales@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust_a@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'sales', 'Sales', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'CustA', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Shop A', 0);

insert into products (id, business_id, name, unit, reference_price, stock_cached) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000, 1);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

-- payments(bill_id) index exists.
select ok(
  exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and tablename = 'payments'
      and indexname = 'payments_bill_id_idx'
  ),
  'payments_bill_id_idx exists'
);

-- record_payment ignores spoofed received_by (sales tries to attribute to owner).
select test_set_auth('33333333-3333-3333-3333-333333333333');

select is(
  (record_payment(jsonb_build_object(
    'id', '91111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'amount', 1000,
    'method', 'cash',
    'received_by', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  ))->'payment'->>'received_by'),
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'record_payment attributes received_by to calling member, not spoofed id'
);

-- Negative stock crossing emits owner notification.
set local role service_role;

insert into stock_movements (
  business_id, product_id, type, qty_delta, reason, created_by
) values (
  '11111111-1111-1111-1111-111111111111',
  'b1111111-1111-1111-1111-111111111111',
  'dispatch',
  -2,
  'oversell test',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
);

select ok(
  exists (
    select 1 from notifications
    where type = 'negative_stock'
      and recipient_member_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
      and (payload->>'product_id') = 'b1111111-1111-1111-1111-111111111111'
  ),
  'negative stock crossing notifies owner'
);

select * from finish();
rollback;
