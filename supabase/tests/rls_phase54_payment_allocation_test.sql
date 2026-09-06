begin;
select plan(15);

insert into businesses(id, name) values ('54000000-0000-0000-0000-000000000001', 'Allocation regression');
insert into auth.users(id, email) select ('54000000-0000-0000-0000-00000000000' || n)::uuid, 'allocation54-' || n || '@test.invalid' from generate_series(2,5) n;
insert into members(id, business_id, auth_user_id, role, display_name)
select id, '54000000-0000-0000-0000-000000000001', id,
(case right(id::text,1) when '2' then 'owner' when '3' then 'sales' when '4' then 'warehouse' else 'customer' end)::member_role, 'Allocation tester'
from auth.users where email like 'allocation54-%@test.invalid';
insert into customers(id,business_id,member_id,shop_name) values
('54000000-0000-0000-0000-000000000006','54000000-0000-0000-0000-000000000001','54000000-0000-0000-0000-000000000005','Allocation customer');
insert into bills(id,business_id,customer_id,created_by,bill_no,items_total,grand_total,status,created_at) values
('54000000-0000-0000-0000-000000000012','54000000-0000-0000-0000-000000000001','54000000-0000-0000-0000-000000000006','54000000-0000-0000-0000-000000000002','TEST54-2',3000,3000,'due','2026-01-01'),
('54000000-0000-0000-0000-000000000011','54000000-0000-0000-0000-000000000001','54000000-0000-0000-0000-000000000006','54000000-0000-0000-0000-000000000002','TEST54-1',4000,4000,'due','2026-01-01');
insert into products(id,business_id,name,unit) values ('54000000-0000-0000-0000-000000000022','54000000-0000-0000-0000-000000000001','Snapshot','piece');
insert into bill_items(id,bill_id,product_id,name_snapshot,qty,rate,line_total) values
('54000000-0000-0000-0000-000000000021','54000000-0000-0000-0000-000000000011','54000000-0000-0000-0000-000000000022','Snapshot',4,1000,4000);
select set_config('request.jwt.claim.sub','54000000-0000-0000-0000-000000000002',true);
set local role authenticated;
select lives_ok($$select create_credit_note('{"bill_id":"54000000-0000-0000-0000-000000000011","restock":false,"items":[{"bill_item_id":"54000000-0000-0000-0000-000000000021","qty_returned":1,"rate":1000,"discount":0}]}')$$,'first return recorded');
select lives_ok($$select create_credit_note('{"bill_id":"54000000-0000-0000-0000-000000000011","restock":false,"items":[{"bill_item_id":"54000000-0000-0000-0000-000000000021","qty_returned":1,"rate":1000,"discount":0}]}')$$,'second return recorded');
select lives_ok($$select record_payment('{"customer_id":"54000000-0000-0000-0000-000000000006","bill_id":"54000000-0000-0000-0000-000000000011","amount":500,"method":"cash"}')$$,'prior partial receipt');
select set_config('request.jwt.claim.sub','54000000-0000-0000-0000-000000000003',true);
select is((record_payment('{"id":"54000000-0000-0000-0000-000000000031","customer_id":"54000000-0000-0000-0000-000000000006","amount":5000,"method":"cash","allocate":"oldest_first"}')->>'created')::boolean,true,'sales allocates receipt');
select is((select amount from payments where id='54000000-0000-0000-0000-000000000031'),1500::bigint,'first chunk subtracts all credit notes and prior payments');
select is((select bill_id from payments where id='54000000-0000-0000-0000-000000000031'),'54000000-0000-0000-0000-000000000011'::uuid,'equal timestamps allocate by ascending bill id');
select is((select sum(amount)::bigint from payments where bill_id='54000000-0000-0000-0000-000000000012'),3000::bigint,'remaining allocation pays next bill');
select is((select sum(amount)::bigint from payments where customer_id='54000000-0000-0000-0000-000000000006' and bill_id is null),500::bigint,'excess retained as account credit');
select is((select count(*)::int from bills where business_id='54000000-0000-0000-0000-000000000001' and status='paid'),2,'both bills paid net of returns');
select is((record_payment('{"id":"54000000-0000-0000-0000-000000000031"}')->>'created')::boolean,false,'same id replay returns original before validating payload');
select is((select sum(amount)::bigint from payments where customer_id='54000000-0000-0000-0000-000000000006'),5500::bigint,'replay never duplicates split receipt');
select lives_ok($$select record_payment('{"customer_id":"54000000-0000-0000-0000-000000000006","bill_id":"54000000-0000-0000-0000-000000000011","amount":9000,"method":"cash"}')$$,'explicit single-bill receipt preserves whole amount even beyond due');
select is((select sum(amount)::bigint from payments where bill_id='54000000-0000-0000-0000-000000000011'),11000::bigint,'explicit overpayment remains bill-linked');
select set_config('request.jwt.claim.sub','54000000-0000-0000-0000-000000000004',true);
select throws_ok($$select record_payment('{"id":"54000000-0000-0000-0000-000000000031"}')$$,'P0001','forbidden','warehouse cannot replay payment');
select set_config('request.jwt.claim.sub','54000000-0000-0000-0000-000000000005',true);
select throws_ok($$select record_payment('{"id":"54000000-0000-0000-0000-000000000031"}')$$,'P0001','forbidden','customer cannot replay payment');
select * from finish();
rollback;
