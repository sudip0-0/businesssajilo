begin;
select no_plan();
insert into businesses(id,name) values ('52000000-0000-0000-0000-000000000001','Workflow'),('52000000-0000-0000-0000-000000000002','Other');
insert into auth.users(id,email,aud,role)
select ('52000000-0000-0000-0000-00000000001'||n)::uuid,'workflow52-'||n||'@test.com','authenticated','authenticated' from generate_series(1,6) n;
insert into members(id,business_id,auth_user_id,role,display_name)
select ('52000000-0000-0000-0000-00000000002'||n)::uuid,
('52000000-0000-0000-0000-00000000000'||case when n=6 then 2 else 1 end)::uuid,
('52000000-0000-0000-0000-00000000001'||n)::uuid,
(case n when 1 then 'owner' when 2 then 'sales' when 3 then 'warehouse' else 'customer' end)::member_role,'Workflow'
from generate_series(1,6) n;
insert into customers(id,business_id,member_id,shop_name)
select ('52000000-0000-0000-0000-00000000003'||n)::uuid,
('52000000-0000-0000-0000-00000000000'||case when n=6 then 2 else 1 end)::uuid,
('52000000-0000-0000-0000-00000000002'||n)::uuid,'Shop' from generate_series(4,6) n;
insert into products(id,business_id,name,unit,is_active) values
('52000000-0000-0000-0000-000000000041','52000000-0000-0000-0000-000000000001','Rice','bag',true),
('52000000-0000-0000-0000-000000000042','52000000-0000-0000-0000-000000000001','Inactive','bag',false),
('52000000-0000-0000-0000-000000000043','52000000-0000-0000-0000-000000000002','Other','bag',true);
create function pg_temp.auth(n int) returns void language plpgsql as $$ begin
perform set_config('request.jwt.claim.sub','52000000-0000-0000-0000-00000000001'||n,true);
set local role authenticated; end $$;
create function pg_temp.payload() returns jsonb language sql as $$ select '{"id":"52000000-0000-0000-0000-000000000051","customer_id":"52000000-0000-0000-0000-000000000034","items":[{"product_id":"52000000-0000-0000-0000-000000000041","qty":2}]}'::jsonb $$;
select pg_temp.auth(1);
select throws_ok($$select place_order(pg_temp.payload())$$,'P0001','forbidden','owner cannot place order');
select pg_temp.auth(2);
select throws_ok($$select place_order(pg_temp.payload())$$,'P0001','forbidden','sales cannot place order');
select pg_temp.auth(3);
select throws_ok($$select place_order(pg_temp.payload())$$,'P0001','forbidden','warehouse cannot place order');
select pg_temp.auth(5);
select throws_ok($$select place_order(pg_temp.payload())$$,'P0001','forbidden','customer cannot impersonate same tenant customer');
select pg_temp.auth(6);
select throws_ok($$select place_order(pg_temp.payload())$$,'P0001','forbidden','customer cannot impersonate cross tenant customer');
select pg_temp.auth(4);
select throws_ok($$select place_order(pg_temp.payload()||'{"items":[]}'::jsonb)$$,'P0001','order must have at least one item','empty order rejected');
select throws_ok($$select place_order(jsonb_set(pg_temp.payload(),'{items,0,qty}','0'))$$,'P0001','item qty must be positive','zero qty rejected');
select throws_ok($$select place_order(jsonb_set(pg_temp.payload(),'{items,0,product_id}','"52000000-0000-0000-0000-000000000042"'))$$,'P0001','active product not found','inactive product rejected');
select throws_ok($$select place_order(jsonb_set(pg_temp.payload(),'{items,0,product_id}','"52000000-0000-0000-0000-000000000043"'))$$,'P0001','active product not found','cross tenant product rejected');
select is((select count(*)::int from orders),0,'failed placement leaves no empty header');
select throws_ok($$insert into orders(customer_id) values('52000000-0000-0000-0000-000000000034')$$,'42501',null,'direct header insertion denied');
select is(place_order(pg_temp.payload())->>'created','true','customer atomically places own order');
select is(place_order(pg_temp.payload())->>'created','false','same UUID replay succeeds');
select is((select count(*)::int from orders),1,'replay creates no second header');
select is((select count(*)::int from order_items),1,'replay creates no second item');
select throws_ok($$select place_order(jsonb_set(pg_temp.payload(),'{items,0,qty}','3'))$$,'P0001','order retry payload does not match','changed replay is rejected');
select pg_temp.auth(1);
create function pg_temp.send() returns jsonb language sql as $$ select send_quote('52000000-0000-0000-0000-000000000051','[{"product_id":"52000000-0000-0000-0000-000000000041","qty":3,"rate":1255,"discount":25}]') $$;
select is(pg_temp.send()->>'version','1','owner sends first quote');
select is(pg_temp.send()->>'version','2','requote increments version');
create function pg_temp.qid(v int) returns uuid language sql security definer as $$ select id from quotes where order_id='52000000-0000-0000-0000-000000000051' and version=v $$;
select pg_temp.auth(4);
select throws_ok($$select respond_quote(pg_temp.qid(1),'accepted')$$,'P0001','quote is no longer awaiting a response','superseded version cannot be accepted');
select throws_ok($$update quotes set total=1,status='accepted' where id=pg_temp.qid(2)$$,'P0001','quote response cannot change quote terms','customer cannot alter quote total');
select throws_ok($$update quotes set expires_at=now()+interval '90 days',status='accepted' where id=pg_temp.qid(2)$$,'P0001','quote response cannot change quote terms','customer cannot extend expiry');
select throws_ok($$select respond_quote(pg_temp.qid(2),'rejected',' ')$$,'P0001','rejection comment is required','reject requires comment');
select pg_temp.auth(5);
select throws_ok($$select respond_quote(pg_temp.qid(2),'accepted')$$,'P0001','forbidden','other customer cannot respond');
select pg_temp.auth(6);
select throws_ok($$select respond_quote(pg_temp.qid(2),'accepted')$$,'P0001','forbidden','cross tenant cannot respond');
select pg_temp.auth(1);
select throws_ok($$select respond_quote(pg_temp.qid(2),'accepted')$$,'P0001','forbidden','staff cannot accept');
update quotes set expires_at=now()-interval '1 second' where id=pg_temp.qid(2);
select pg_temp.auth(4);
select throws_ok($$select respond_quote(pg_temp.qid(2),'accepted')$$,'P0001','quote has expired','expired acceptance rejected by server');
select pg_temp.auth(1);
update quotes set expires_at=now()+interval '1 day' where id=pg_temp.qid(2);
select pg_temp.auth(4);
select is(respond_quote(pg_temp.qid(2),'accepted')->>'status','accepted','customer accepts active version');
select is(respond_quote(pg_temp.qid(2),'accepted')->>'status','accepted','response retry is idempotent');
select throws_ok($$select respond_quote(pg_temp.qid(2),'rejected','changed mind')$$,'P0001','quote is no longer awaiting a response','accepted response cannot be changed');
create function pg_temp.bill(customer text) returns jsonb language sql as $$ select jsonb_build_object('order_id','52000000-0000-0000-0000-000000000051','customer_id',customer,'items','[{"name_snapshot":"Rice","qty":3,"rate":1255,"discount":25}]'::jsonb) $$;
select pg_temp.auth(1);
select throws_ok($$select create_bill(pg_temp.bill('52000000-0000-0000-0000-000000000035'))$$,'P0001','bill customer must match order customer','mismatched bill customer rejected');
select is((select count(*)::int from bills),0,'mismatch rolls back bill');
select is((select status::text from orders where id='52000000-0000-0000-0000-000000000051'),'placed','mismatch leaves order unbilled');
select is(pg_temp.send()->>'version','3','requote after acceptance remains supported');
select pg_temp.auth(2);
select throws_ok($$select create_bill(pg_temp.bill('52000000-0000-0000-0000-000000000035'))$$,'P0001','bill customer must match order customer','sales cannot mismatch bill customer');
select pg_temp.auth(3);
select throws_ok($$select create_bill(pg_temp.bill('52000000-0000-0000-0000-000000000035'))$$,'P0001','bill customer must match order customer','warehouse cannot mismatch bill customer');
select pg_temp.auth(1);
select is(create_bill(pg_temp.bill(null))->'bill'->>'customer_id','52000000-0000-0000-0000-000000000034','omitted customer inherits order customer');
select is((select grand_total from bills where order_id='52000000-0000-0000-0000-000000000051'),3740::bigint,'bill remains editable and preserves paisa');
select pg_temp.auth(4);
select throws_ok($$select respond_quote(pg_temp.qid(3),'accepted')$$,'P0001','order can no longer receive a quote response','billed order cannot accept outstanding quote');
select * from finish();
rollback;
