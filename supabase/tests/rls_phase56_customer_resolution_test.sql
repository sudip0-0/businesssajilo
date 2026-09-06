begin;
select no_plan();
insert into businesses(id,name) values
('56000000-0000-0000-0000-000000000001','Resolver tests'),
('56000000-0000-0000-0000-000000000009','Foreign resolver tests');
insert into auth.users(id,email) select ('56000000-0000-0000-0000-00000000000'||n)::uuid,'resolver56-'||n||'@test.invalid' from generate_series(2,6)n;
insert into members(id,business_id,auth_user_id,role,display_name)
select id,case when right(id::text,1)='6' then '56000000-0000-0000-0000-000000000009'::uuid else '56000000-0000-0000-0000-000000000001'::uuid end,id,
(case right(id::text,1) when '2' then 'owner' when '3' then 'sales' when '4' then 'warehouse' else 'customer' end)::member_role,'Resolver tester'
from auth.users where email like 'resolver56-%@test.invalid';
insert into customers(id,business_id,member_id,shop_name,phone) values
('56000000-0000-0000-0000-000000000005','56000000-0000-0000-0000-000000000001','56000000-0000-0000-0000-000000000005','Local shop 56','+9779856000005'),
('56000000-0000-0000-0000-000000000006','56000000-0000-0000-0000-000000000009','56000000-0000-0000-0000-000000000006','Foreign shop 56','+9779856000006');
create temporary table counts_before as select (select count(*) from auth.users) users_count,(select count(*) from auth.identities) identities_count,(select count(*) from members) members_count,(select count(*) from customers) customers_count;
create temporary table foreign_before as select to_jsonb(c) snapshot from customers c where id='56000000-0000-0000-0000-000000000006';
create function pg_temp.check_roles() returns setof text language plpgsql as $$
declare
  n int;
  label text;
  expected text;
  payload jsonb;
begin
  for n in 2..5 loop
    label := case n when 2 then 'owner' when 3 then 'sales' when 4 then 'warehouse' else 'customer' end;
    expected := case n when 5 then 'forbidden' else 'customer not found' end;
    perform set_config('request.jwt.claim.sub','56000000-0000-0000-0000-00000000000'||n,true);
    set local role authenticated;
    payload := '{"customer_id":"56000000-0000-0000-0000-000000000099","customer_shop_name":"Missing shop 56","customer_phone":"+9779856000099","items":[{"name_snapshot":"Snapshot","qty":1,"rate":1000,"discount":0}]}';
    return next throws_ok(format('select create_bill(%L::jsonb)',payload),'P0001',expected,label||' cannot create customer from billing identity');
    return next throws_ok(format('select create_bill(%L::jsonb)',payload-'customer_shop_name'-'customer_phone'),'P0001',expected,label||' missing identity fails');
    payload := payload || '{"customer_id":"56000000-0000-0000-0000-000000000006","customer_shop_name":"Foreign shop 56","customer_phone":"+9779856000006"}'::jsonb;
    return next throws_ok(format('select create_bill(%L::jsonb)',payload),'P0001',expected,label||' cannot resolve foreign identity');
    payload := payload || '{"customer_id":"56000000-0000-0000-0000-000000000005"}'::jsonb;
    if n=5 then
      return next throws_ok(format('select create_bill(%L::jsonb)',payload),'P0001','forbidden','customer cannot bill existing customer');
    else
      return next lives_ok(format('select create_bill(%L::jsonb)',payload),label||' can bill existing customer despite stale identity fields');
    end if;
    return next throws_ok('select resolve_billing_customer(''{}'')','42501','permission denied for function resolve_billing_customer',label||' cannot directly invoke internal resolver');
    reset role;
    return next is((select count(*) from auth.users),(select users_count from counts_before),label||' creates no auth users');
    return next is((select count(*) from auth.identities),(select identities_count from counts_before),label||' creates no auth identities');
    return next is((select count(*) from members),(select members_count from counts_before),label||' creates no members');
    return next is((select count(*) from customers),(select customers_count from counts_before),label||' creates no customers');
  end loop;
end;
$$;
select * from pg_temp.check_roles();
select is((select to_jsonb(c) from customers c where id='56000000-0000-0000-0000-000000000006'),(select snapshot from foreign_before),'foreign customer unchanged');
select * from finish();
rollback;
