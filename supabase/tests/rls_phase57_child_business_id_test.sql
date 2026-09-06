begin;
select no_plan();
create function pg_temp.u(n int) returns uuid language sql immutable as $$select ('57000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid$$;
select is((select count(*)::int from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r' and c.relname<>'businesses' and not exists(select 1 from pg_attribute a where a.attrelid=c.oid and a.attname='business_id' and a.attnotnull and not a.attisdropped)),0,'every tenant table has explicit nonnull business_id');
select ok(c.relrowsecurity and c.relforcerowsecurity,c.relname||' retains FORCE RLS') from pg_class c where c.oid in ('bill_items'::regclass,'order_items'::regclass,'quotes'::regclass,'quote_items'::regclass,'credit_note_items'::regclass,'device_tokens'::regclass);
select is(cardinality(conkey),2,conname||' is composite') from pg_constraint where conname in ('bill_items_bill_id_fkey','order_items_order_id_fkey','quotes_order_id_fkey','quote_items_quote_id_fkey','credit_note_items_credit_note_id_fkey','device_tokens_member_id_fkey');
select is(confdeltype::text,'c',conname||' preserves cascade') from pg_constraint where conname in ('bill_items_bill_id_fkey','order_items_order_id_fkey','quotes_order_id_fkey','quote_items_quote_id_fkey','credit_note_items_credit_note_id_fkey','device_tokens_member_id_fkey');
select is((select count(*)::int from pg_constraint other where other.contype='f' and other.conrelid=c.conrelid and other.confrelid=c.confrelid),1,c.conname||' is the sole parent relationship') from pg_constraint c where c.conname in ('bill_items_bill_id_fkey','order_items_order_id_fkey','quotes_order_id_fkey','quote_items_quote_id_fkey','credit_note_items_credit_note_id_fkey','device_tokens_member_id_fkey');
insert into businesses(id,name) values(pg_temp.u(1),'Child integrity'),(pg_temp.u(101),'Foreign child integrity');
insert into auth.users(id,email) select pg_temp.u(n),'child57-'||n||'@test.invalid' from unnest(array[2,3,4,5,102,105])n;
insert into members(id,business_id,auth_user_id,role,display_name)
select pg_temp.u(n),pg_temp.u(case when n>100 then 101 else 1 end),pg_temp.u(n),(case n when 2 then 'owner' when 3 then 'sales' when 4 then 'warehouse' when 102 then 'owner' else 'customer' end)::member_role,'Child tester' from unnest(array[2,3,4,5,102,105])n;
insert into customers(id,business_id,member_id,shop_name) values(pg_temp.u(5),pg_temp.u(1),pg_temp.u(5),'Child shop'),(pg_temp.u(105),pg_temp.u(101),pg_temp.u(105),'Foreign child shop');
insert into products(id,business_id,name,unit) values(pg_temp.u(12),pg_temp.u(1),'Child product','piece'),(pg_temp.u(112),pg_temp.u(101),'Foreign child product','piece');
insert into bills(id,business_id,customer_id,created_by,items_total,grand_total,status) values(pg_temp.u(11),pg_temp.u(1),pg_temp.u(5),pg_temp.u(2),10000,10000,'due'),(pg_temp.u(111),pg_temp.u(101),pg_temp.u(105),pg_temp.u(102),10000,10000,'due');
insert into orders(id,business_id,customer_id) values(pg_temp.u(13),pg_temp.u(1),pg_temp.u(5)),(pg_temp.u(113),pg_temp.u(101),pg_temp.u(105));
insert into quotes(id,order_id,version,created_by) values(pg_temp.u(14),pg_temp.u(13),1,pg_temp.u(2)),(pg_temp.u(114),pg_temp.u(113),1,pg_temp.u(102));
insert into bill_items(id,bill_id,product_id,name_snapshot,qty,rate,line_total) values(pg_temp.u(15),pg_temp.u(11),pg_temp.u(12),'Immutable snapshot',10,1000,10000),(pg_temp.u(115),pg_temp.u(111),pg_temp.u(112),'Foreign snapshot',10,1000,10000);
insert into credit_notes(id,business_id,bill_id,customer_id,created_by,items_total,grand_total,restock) values(pg_temp.u(18),pg_temp.u(1),pg_temp.u(11),pg_temp.u(5),pg_temp.u(2),1000,1000,false),(pg_temp.u(118),pg_temp.u(101),pg_temp.u(111),pg_temp.u(105),pg_temp.u(102),1000,1000,false);
create temporary table child_cases(table_name text,parent_column text,parent_id uuid,foreign_parent uuid,payload jsonb);
insert into child_cases values
('bill_items','bill_id',pg_temp.u(11),pg_temp.u(111),jsonb_build_object('bill_id',pg_temp.u(11),'name_snapshot','Saved bill snapshot','qty',1,'rate',100,'line_total',100)),
('order_items','order_id',pg_temp.u(13),pg_temp.u(113),jsonb_build_object('order_id',pg_temp.u(13),'product_id',pg_temp.u(12),'qty',1)),
('quotes','order_id',pg_temp.u(13),pg_temp.u(113),jsonb_build_object('order_id',pg_temp.u(13),'version',2,'created_by',pg_temp.u(2))),
('quote_items','quote_id',pg_temp.u(14),pg_temp.u(114),jsonb_build_object('quote_id',pg_temp.u(14),'product_id',pg_temp.u(12),'qty',1,'rate',100,'line_total',100)),
('credit_note_items','credit_note_id',pg_temp.u(18),pg_temp.u(118),jsonb_build_object('credit_note_id',pg_temp.u(18),'bill_item_id',pg_temp.u(15),'product_id',pg_temp.u(12),'name_snapshot','Saved return snapshot','qty_returned',1,'rate',100,'line_total',100)),
('device_tokens','member_id',pg_temp.u(2),pg_temp.u(102),jsonb_build_object('member_id',pg_temp.u(2),'token','child57-token','platform','web'));
create function pg_temp.insert_child(t text,p jsonb) returns void language plpgsql as $$
declare cols text; vals text;
begin
  select string_agg(quote_ident(key),','),string_agg(quote_nullable(value),',') into cols,vals from jsonb_each_text(p);
  execute format('insert into %I (%s) values (%s)',t,cols,vals);
end;
$$;
create function pg_temp.check_children() returns setof text language plpgsql as $$
declare c record; p jsonb; saved jsonb; current_row jsonb; child_id uuid; count_before bigint; payments_before bigint;
begin
  for c in select * from child_cases loop
    child_id := gen_random_uuid();
    p := c.payload||jsonb_build_object('id',child_id);
    return next lives_ok(format('select pg_temp.insert_child(%L,%L)',c.table_name,p),c.table_name||' accepts legacy payload without business_id');
    execute format('select to_jsonb(t) from %I t where id=$1',c.table_name) into saved using child_id;
    return next is(saved->>'business_id',pg_temp.u(1)::text,c.table_name||' stamps parent business');
    select count(*) into count_before from stock_movements;
    select count(*) into payments_before from payments;
    return next lives_ok(format('update %I set business_id=business_id where id=%L',c.table_name,child_id),c.table_name||' accepts metadata-only update');
    execute format('select to_jsonb(t) from %I t where id=$1',c.table_name) into current_row using child_id;
    return next is(current_row,saved,c.table_name||' metadata update preserves snapshots');
    return next is((select count(*) from stock_movements),count_before,c.table_name||' metadata update never writes stock');
    return next is((select count(*) from payments),payments_before,c.table_name||' metadata update never writes payments');
    return next throws_ok(format('select pg_temp.insert_child(%L,%L)',c.table_name,p||jsonb_build_object('id',gen_random_uuid(),'business_id',pg_temp.u(101))),'23514','child business mismatch',c.table_name||' rejects explicit wrong business');
    return next throws_ok(format('select pg_temp.insert_child(%L,%L)',c.table_name,p||jsonb_build_object('id',gen_random_uuid(),c.parent_column,c.foreign_parent,'business_id',pg_temp.u(1))),'23514','child business mismatch',c.table_name||' rejects foreign parent with local business');
    return next throws_ok(format('update %I set business_id=%L where id=%L',c.table_name,pg_temp.u(101),child_id),'23514','child business mismatch',c.table_name||' rejects business reassignment');
    return next throws_ok(format('update %I set %I=%L,business_id=%L where id=%L',c.table_name,c.parent_column,c.foreign_parent,pg_temp.u(101),child_id),'23514','child business mismatch',c.table_name||' rejects simultaneous parent and business reassignment');
  end loop;
end;
$$;
select * from pg_temp.check_children();
create function pg_temp.check_child_roles() returns setof text language plpgsql as $$
declare n int; t text; found_count int; expected int; label text;
begin
  for n in 2..5 loop
    label:=case n when 2 then 'owner' when 3 then 'sales' when 4 then 'warehouse' else 'customer' end;
    perform set_config('request.jwt.claim.sub',pg_temp.u(n)::text,true);
    set local role authenticated;
    foreach t in array array['bill_items','order_items','quotes','quote_items','credit_note_items'] loop
      execute format('select count(*)::int from %I where business_id=$1',t) into found_count using pg_temp.u(1);
      expected:=case when n=4 and t in ('order_items','quotes','quote_items','credit_note_items') then 0 when t in ('bill_items','quotes') then 2 else 1 end;
      return next is(found_count,expected,label||' keeps existing '||t||' read scope');
      execute format('select count(*)::int from %I where business_id=$1',t) into found_count using pg_temp.u(101);
      return next is(found_count,0,label||' cannot read foreign '||t);
    end loop;
    return next lives_ok(format('insert into device_tokens(member_id,token,platform) values(%L,%L,''web'')',pg_temp.u(n),'role57-'||n),label||' can register own token without business_id');
    return next throws_ok(format('insert into device_tokens(member_id,token,platform) values(%L,%L,''web'')',pg_temp.u(102),'foreign57-'||n),'23514','child business mismatch',label||' cannot stamp foreign member token');
    return next throws_ok(format('insert into device_tokens(member_id,token,platform) values(%L,%L,''web'')',pg_temp.u(case when n=2 then 3 else 2 end),'other57-'||n),'42501','new row violates row-level security policy for table "device_tokens"',label||' cannot register another local member token');
    reset role;
  end loop;
end;
$$;
select * from pg_temp.check_child_roles();
insert into auth.users(id,email) values(pg_temp.u(7),'child57-other@test.invalid');
insert into members(id,business_id,auth_user_id,role,display_name) values(pg_temp.u(7),pg_temp.u(1),pg_temp.u(7),'customer','Other local customer');
insert into customers(id,business_id,member_id,shop_name) values(pg_temp.u(7),pg_temp.u(1),pg_temp.u(7),'Other local shop');
insert into bills(id,business_id,customer_id,created_by,items_total,grand_total,status) values(pg_temp.u(21),pg_temp.u(1),pg_temp.u(7),pg_temp.u(2),1000,1000,'due');
insert into orders(id,business_id,customer_id) values(pg_temp.u(23),pg_temp.u(1),pg_temp.u(7));
insert into quotes(id,order_id,version,created_by) values(pg_temp.u(24),pg_temp.u(23),1,pg_temp.u(2));
insert into bill_items(id,bill_id,product_id,name_snapshot,qty,rate,line_total) values(pg_temp.u(25),pg_temp.u(21),pg_temp.u(12),'Other local snapshot',1,1000,1000);
insert into order_items(id,order_id,product_id,qty) values(pg_temp.u(26),pg_temp.u(23),pg_temp.u(12),1);
insert into quote_items(id,quote_id,product_id,qty,rate,line_total) values(pg_temp.u(27),pg_temp.u(24),pg_temp.u(12),1,1000,1000);
insert into credit_notes(id,business_id,bill_id,customer_id,created_by,items_total,grand_total,restock) values(pg_temp.u(28),pg_temp.u(1),pg_temp.u(21),pg_temp.u(7),pg_temp.u(2),1000,1000,false);
insert into credit_note_items(id,credit_note_id,bill_item_id,product_id,name_snapshot,qty_returned,rate,line_total) values(pg_temp.u(29),pg_temp.u(28),pg_temp.u(25),pg_temp.u(12),'Other local snapshot',1,1000,1000);
create function pg_temp.check_customer_ownership() returns setof text language plpgsql as $$
declare t text; n int; found_count int;
begin
  foreach n in array array[5,7] loop
    perform set_config('request.jwt.claim.sub',pg_temp.u(n)::text,true);
    set local role authenticated;
    foreach t in array array['bill_items','order_items','quotes','quote_items','credit_note_items'] loop
      execute format('select count(*)::int from %I where id=any($1)',t) into found_count using array[pg_temp.u(24),pg_temp.u(25),pg_temp.u(26),pg_temp.u(27),pg_temp.u(29)];
      return next is(found_count,case when n=7 then 1 else 0 end,t||' keeps customer ownership within the same business for customer '||n);
    end loop;
    reset role;
  end loop;
end;
$$;
select * from pg_temp.check_customer_ownership();
select * from finish();
rollback;
