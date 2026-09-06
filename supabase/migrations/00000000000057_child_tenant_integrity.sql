set local lock_timeout = '10s';

alter table bill_items add column business_id uuid;
alter table order_items add column business_id uuid;
alter table quotes add column business_id uuid;
alter table quote_items add column business_id uuid;
alter table credit_note_items add column business_id uuid;
alter table device_tokens add column business_id uuid;

update bill_items c set business_id=p.business_id from bills p where p.id=c.bill_id;
update order_items c set business_id=p.business_id from orders p where p.id=c.order_id;
update quotes c set business_id=p.business_id from orders p where p.id=c.order_id;
update quote_items c set business_id=p.business_id from quotes p where p.id=c.quote_id;
update credit_note_items c set business_id=p.business_id from credit_notes p where p.id=c.credit_note_id;
update device_tokens c set business_id=p.business_id from members p where p.id=c.member_id;

alter table bill_items alter column business_id set not null;
alter table order_items alter column business_id set not null;
alter table quotes alter column business_id set not null;
alter table quote_items alter column business_id set not null;
alter table credit_note_items alter column business_id set not null;
alter table device_tokens alter column business_id set not null;

alter table bills add constraint bills_id_business_id_key unique(id,business_id);
alter table orders add constraint orders_id_business_id_key unique(id,business_id);
alter table quotes add constraint quotes_id_business_id_key unique(id,business_id);
alter table credit_notes add constraint credit_notes_id_business_id_key unique(id,business_id);
alter table members add constraint members_id_business_id_key unique(id,business_id);

alter table bill_items drop constraint bill_items_bill_id_fkey,
  add constraint bill_items_bill_id_fkey foreign key(bill_id,business_id) references bills(id,business_id) on delete cascade;
alter table order_items drop constraint order_items_order_id_fkey,
  add constraint order_items_order_id_fkey foreign key(order_id,business_id) references orders(id,business_id) on delete cascade;
alter table quotes drop constraint quotes_order_id_fkey,
  add constraint quotes_order_id_fkey foreign key(order_id,business_id) references orders(id,business_id) on delete cascade;
alter table quote_items drop constraint quote_items_quote_id_fkey,
  add constraint quote_items_quote_id_fkey foreign key(quote_id,business_id) references quotes(id,business_id) on delete cascade;
alter table credit_note_items drop constraint credit_note_items_credit_note_id_fkey,
  add constraint credit_note_items_credit_note_id_fkey foreign key(credit_note_id,business_id) references credit_notes(id,business_id) on delete cascade;
alter table device_tokens drop constraint device_tokens_member_id_fkey,
  add constraint device_tokens_member_id_fkey foreign key(member_id,business_id) references members(id,business_id) on delete cascade;

create or replace function stamp_child_business_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  parent_business uuid;
  parent_id uuid := (to_jsonb(new)->>tg_argv[1])::uuid;
begin
  execute format('select business_id from public.%I where id=$1',tg_argv[0])
    into parent_business using parent_id;
  if parent_business is null then
    raise exception 'child parent not found' using errcode='23503';
  end if;
  if (new.business_id is not null and new.business_id is distinct from parent_business)
     or (auth.uid() is not null and parent_business is distinct from current_business_id()) then
    raise exception 'child business mismatch' using errcode='23514';
  end if;
  if tg_op='UPDATE' and old.business_id is distinct from parent_business then
    raise exception 'child business mismatch' using errcode='23514';
  end if;
  new.business_id := parent_business;
  return new;
end;
$$;
revoke all on function stamp_child_business_id() from public,anon,authenticated;

create trigger a_stamp_child_business before insert or update on bill_items
  for each row execute function stamp_child_business_id('bills','bill_id');
create trigger a_stamp_child_business before insert or update on order_items
  for each row execute function stamp_child_business_id('orders','order_id');
create trigger a_stamp_child_business before insert or update on quotes
  for each row execute function stamp_child_business_id('orders','order_id');
create trigger a_stamp_child_business before insert or update on quote_items
  for each row execute function stamp_child_business_id('quotes','quote_id');
create trigger a_stamp_child_business before insert or update on credit_note_items
  for each row execute function stamp_child_business_id('credit_notes','credit_note_id');
create trigger a_stamp_child_business before insert or update on device_tokens
  for each row execute function stamp_child_business_id('members','member_id');

create policy child_business_scope on bill_items as restrictive to authenticated
  using(business_id=(select current_business_id())) with check(business_id=(select current_business_id()));
create policy child_business_scope on order_items as restrictive to authenticated
  using(business_id=(select current_business_id())) with check(business_id=(select current_business_id()));
create policy child_business_scope on quotes as restrictive to authenticated
  using(business_id=(select current_business_id())) with check(business_id=(select current_business_id()));
create policy child_business_scope on quote_items as restrictive to authenticated
  using(business_id=(select current_business_id())) with check(business_id=(select current_business_id()));
create policy child_business_scope on credit_note_items as restrictive to authenticated
  using(business_id=(select current_business_id())) with check(business_id=(select current_business_id()));
create policy child_business_scope on device_tokens as restrictive to authenticated
  using(business_id=(select current_business_id())) with check(business_id=(select current_business_id()));

create index bill_items_business_parent_idx on bill_items(business_id,bill_id);
create index order_items_business_parent_idx on order_items(business_id,order_id);
create index quotes_business_parent_idx on quotes(business_id,order_id);
create index quote_items_business_parent_idx on quote_items(business_id,quote_id);
create index credit_note_items_business_parent_idx on credit_note_items(business_id,credit_note_id);
create index device_tokens_business_parent_idx on device_tokens(business_id,member_id);

notify pgrst, 'reload schema';
