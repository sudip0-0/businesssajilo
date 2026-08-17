-- Offline bills keep their original created_at when synced later.
begin;
select plan(4);

insert into businesses (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Test Biz');

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
values
  ('22222222-2222-2222-2222-222222222222', 'owner@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated'),
  ('55555555-5555-5555-5555-555555555555', 'cust@test.com', crypt('pass', gen_salt('bf')), now(), '{}', '{}', 'authenticated', 'authenticated');

insert into members (id, business_id, auth_user_id, role, display_name, is_active) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'owner', 'Owner', true),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 'customer', 'Cust', true);

insert into customers (id, business_id, member_id, shop_name, opening_balance) values
  ('e1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Ram Store', 0);

insert into products (id, business_id, name, unit, reference_price) values
  ('b1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Cola', 'piece', 5000);

create or replace function test_set_auth(uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
end;
$$;

select test_set_auth('22222222-2222-2222-2222-222222222222');

select is(
  (create_bill(jsonb_build_object(
    'id', 'f1111111-1111-1111-1111-111111111111',
    'customer_id', 'e1111111-1111-1111-1111-111111111111',
    'discount', 0,
    'created_at', '2026-08-16T10:00:00+05:45',
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', 'b1111111-1111-1111-1111-111111111111',
      'name_snapshot', 'Cola', 'qty', 1, 'rate', 5000, 'discount', 0
    ))
  ))->'bill'->>'created_at')::timestamptz,
  '2026-08-16T10:00:00+05:45'::timestamptz,
  'create_bill keeps client created_at'
);

select is(
  (select coalesce(sum(total_sales), 0) from report_sales_daily
    where sale_date = date '2026-08-16'),
  5000::bigint,
  'delayed sync counts on the original sale date'
);

select is(
  (select coalesce(sum(total_sales), 0) from report_sales_daily
    where sale_date = (timezone('Asia/Kathmandu', now()))::date
      and sale_date is distinct from date '2026-08-16'),
  0::bigint,
  'delayed sync is not counted as today when the bill is older'
);

select is(
  occurred_at_from_payload(jsonb_build_object(
    'created_at', (now() + interval '2 hours')::text
  )) <= now() + interval '1 second',
  true,
  'future created_at is clamped to now'
);

select * from finish();
rollback;
