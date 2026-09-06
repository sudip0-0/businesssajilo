begin;
select no_plan();
insert into businesses(id,name) values ('59000000-0000-0000-0000-000000000001','Guard59'),('59000000-0000-0000-0000-000000000002','Other59');
insert into auth.users(id,email,aud,role)
select ('59000000-0000-0000-0000-00000000001'||n)::uuid,'guard59-'||n||'@test.invalid','authenticated','authenticated' from generate_series(1,6) n;
insert into members(id,business_id,auth_user_id,role,display_name)
select ('59000000-0000-0000-0000-00000000002'||n)::uuid,
('59000000-0000-0000-0000-00000000000'||case when n=6 then 2 else 1 end)::uuid,
('59000000-0000-0000-0000-00000000001'||n)::uuid,
(case n when 1 then 'owner' when 2 then 'sales' when 3 then 'warehouse' else 'customer' end)::member_role,'Guard59'
from generate_series(1,6) n;
insert into customers(id,business_id,member_id,shop_name)
select ('59000000-0000-0000-0000-00000000003'||n)::uuid,
('59000000-0000-0000-0000-00000000000'||case when n=6 then 2 else 1 end)::uuid,
('59000000-0000-0000-0000-00000000002'||n)::uuid,'Shop59' from generate_series(4,6) n;
insert into products(id,business_id,name,unit,is_active,reference_price) values
('59000000-0000-0000-0000-000000000041','59000000-0000-0000-0000-000000000001','Rice','bag',true,2500);
create function pg_temp.auth(n int) returns void language plpgsql as $$ begin
perform set_config('request.jwt.claim.sub','59000000-0000-0000-0000-00000000001'||n,true);
set local role authenticated; end $$;
create function pg_temp.oid(n int) returns uuid language sql immutable as $$select ('59000000-0000-0000-0000-0000000000'||n)::uuid$$;
create function pg_temp.payload(n int) returns jsonb language sql as $$
select jsonb_build_object('id',pg_temp.oid(n),'customer_id','59000000-0000-0000-0000-000000000034','items',jsonb_build_array(jsonb_build_object('product_id','59000000-0000-0000-0000-000000000041','qty',2)))
$$;
create function pg_temp.qitems() returns jsonb language sql as $$select '[{"product_id":"59000000-0000-0000-0000-000000000041","qty":3,"rate":1255,"discount":25}]'::jsonb$$;
create function pg_temp.qid(n int,v int) returns uuid language sql security definer as $$select id from quotes where order_id=('59000000-0000-0000-0000-0000000000'||n)::uuid and version=v$$;
create function pg_temp.bill(n int) returns jsonb language sql as $$select jsonb_build_object('order_id',('59000000-0000-0000-0000-0000000000'||n)::uuid,'items','[{"name_snapshot":"Rice","qty":3,"rate":1255,"discount":25}]'::jsonb)$$;
select pg_temp.auth(4);
select is(place_order(pg_temp.payload(51))->>'created','true','customer places order 051');
select is(place_order(pg_temp.payload(52))->>'created','true','customer places order 052');
select is(place_order(pg_temp.payload(53))->>'created','true','customer places order 053');
select is(place_order(pg_temp.payload(54))->>'created','true','customer places order 054');
select pg_temp.auth(1);
select is(send_quote(pg_temp.oid(51),pg_temp.qitems())->>'version','1','owner sends quote on 051');
select is((select product_name from quote_items where quote_id=pg_temp.qid(51,1)),'Rice','send_quote snapshots same-tenant product name');
select is((select qty from quote_items where quote_id=pg_temp.qid(51,1)),3,'snapshot insert leaves qty unchanged');
select is((select rate from quote_items where quote_id=pg_temp.qid(51,1)),1255::bigint,'snapshot insert leaves rate unchanged');
select pg_temp.auth(4);
select is(respond_quote(pg_temp.qid(51,1),'accepted')->>'status','accepted','customer respond_quote still accepts');
select pg_temp.auth(1);
update products set name='Basmati' where id='59000000-0000-0000-0000-000000000041';
select pg_temp.auth(4);
select is((select count(*)::int from products),0,'customer cannot select raw products');
select is((select product_name from quote_items where quote_id=pg_temp.qid(51,1)),'Rice','quote item snapshot survives product rename');
select pg_temp.auth(1);
select is(billing_draft_from_order(pg_temp.oid(51))->'lines'->0->>'name_snapshot','Rice','billing draft prefers quote item snapshot');
select lives_ok($$update orders set status='received' where id=pg_temp.oid(54)$$,'owner can mark order received');
select set_config('app.create_bill','1',true);
select throws_ok($$update orders set status='billed' where id=pg_temp.oid(54)$$,'P0001','order can only be billed via create_bill','spoofed session flag cannot bill by direct update');
select is((select status::text from orders where id=pg_temp.oid(54)),'received','failed billed bypass leaves order received');
select is(create_bill(pg_temp.bill(54))->>'created','true','create_bill still bills received order');
select is((select status::text from orders where id=pg_temp.oid(54)),'billed','create_bill transitions received to billed');
select is(send_quote(pg_temp.oid(52),pg_temp.qitems())->>'version','1','owner sends quote on 052');
select throws_ok($$update quotes set status='accepted' where id=pg_temp.qid(52,1)$$,'P0001','quote response must use respond_quote','owner cannot accept quote by direct update');
select throws_ok($$update quotes set status='rejected',response_comment='no' where id=pg_temp.qid(52,1)$$,'P0001','quote response must use respond_quote','owner cannot reject quote by direct update');
select throws_ok($$insert into quotes(order_id,version,status,total,created_by) values(pg_temp.oid(52),9,'accepted',1,'59000000-0000-0000-0000-000000000021')$$,'P0001','quote response must use respond_quote','owner cannot insert accepted quote');
select throws_ok($$insert into quotes(order_id,version,status,total,created_by) values(pg_temp.oid(52),10,'rejected',1,'59000000-0000-0000-0000-000000000021')$$,'P0001','quote response must use respond_quote','owner cannot insert rejected quote');
select is((select status::text from quotes where id=pg_temp.qid(52,1)),'sent','owner forged response leaves quote sent');
select pg_temp.auth(2);
select is(send_quote(pg_temp.oid(53),pg_temp.qitems())->>'version','1','sales sends quote on 053');
select throws_ok($$update quotes set status='accepted' where id=pg_temp.qid(53,1)$$,'P0001','quote response must use respond_quote','sales cannot accept quote by direct update');
select throws_ok($$insert into quotes(order_id,version,status,total,created_by) values(pg_temp.oid(53),9,'accepted',1,'59000000-0000-0000-0000-000000000022')$$,'P0001','quote response must use respond_quote','sales cannot insert accepted quote');
select is((select status::text from quotes where id=pg_temp.qid(53,1)),'sent','sales forged response leaves quote sent');
select pg_temp.auth(4);
select is(respond_quote(pg_temp.qid(52,1),'accepted')->>'status','accepted','customer can still accept after staff forge deny');
select pg_temp.auth(1);
select is(send_quote(pg_temp.oid(52),pg_temp.qitems())->>'version','2','requote after acceptance remains supported');
select is((select product_name from quote_items where quote_id=pg_temp.qid(52,2)),'Basmati','requote snapshots current product name');
select * from finish();
rollback;
