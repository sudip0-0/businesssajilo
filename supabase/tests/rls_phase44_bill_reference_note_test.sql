begin;
select plan(6);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner44@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('33333333-3333-3333-3333-333333333333', 'warehouse44@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('44444444-4444-4444-4444-444444444444', 'customer44@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'warehouse', 'Warehouse', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'customer', 'Customer', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Ram Store', 0);

insert into products (id, business_id, name, unit, reference_price) values
  ('d1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select test_set_auth('22222222-2222-2222-2222-222222222222');

select lives_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'reference_note', 'Deliver Friday',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'd1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    ))
  ))$$,
  'due bill accepts a reference note'
);

select is(
  (select reference_note from bills where id = 'f1111111-1111-1111-1111-111111111111'),
  'Deliver Friday',
  'due bill stores its reference note'
);

select lives_ok(
  $$select create_bill(jsonb_build_object(
    'id', 'f2222222-2222-2222-2222-222222222222',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'reference_note', 'Cheque 123',
    'discount', 0,
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'd1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    )),
    'payment', jsonb_build_object(
      'amount', 5000, 'method', 'cheque', 'ref_note', 'Cheque 123'
    )
  ))$$,
  'paid bill accepts a payment reference note'
);

select is(
  (select reference_note from bills where id = 'f2222222-2222-2222-2222-222222222222'),
  null,
  'payment reference is not copied onto the bill row'
);

select test_set_auth('44444444-4444-4444-4444-444444444444');
select is(
  (select reference_note from bills where id = 'f1111111-1111-1111-1111-111111111111'),
  'Deliver Friday',
  'customer can read the reference note on their own due bill'
);

select test_set_auth('33333333-3333-3333-3333-333333333333');
select is(
  (select count(*)::int from payments where bill_id = 'f2222222-2222-2222-2222-222222222222'),
  0,
  'warehouse cannot read the payment reference row'
);

select * from finish();
rollback;
