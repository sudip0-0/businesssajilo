-- Migration 43: remove chat entirely.
-- The order-thread chat UI was retired; this drops the remaining backend:
-- messages table, its notification trigger, and the order-chat-images bucket.

-- 1. Notification trigger + function (from 00000000000007).
drop trigger if exists messages_notify_chat on messages;
drop function if exists notify_chat_message();

-- 2. Messages table (cascades RLS policies, indexes, realtime publication
--    membership, and the messages_body_max_len constraint from 00000000000022).
drop table if exists messages cascade;

-- 3. Storage: order-chat-images bucket + every policy ever created for it
--    (names from 00000000000005/10/19).
drop policy if exists "chat participants read images" on storage.objects;
drop policy if exists "chat participants upload images" on storage.objects;
drop policy if exists "staff read chat images" on storage.objects;
drop policy if exists "customer read own order chat images" on storage.objects;
drop policy if exists "staff upload chat images" on storage.objects;
drop policy if exists "customer upload own order chat images" on storage.objects;
drop policy if exists "staff delete chat images" on storage.objects;
drop policy if exists "customer delete own order chat images" on storage.objects;

-- Storage blocks direct DELETE via protect_delete triggers; lift them for
-- the purge and restore afterwards.
drop trigger if exists protect_objects_delete on storage.objects;
drop trigger if exists protect_buckets_delete on storage.buckets;

delete from storage.objects where bucket_id = 'order-chat-images';
delete from storage.buckets where id = 'order-chat-images';

create trigger protect_objects_delete
  before delete on storage.objects
  for each statement execute function storage.protect_delete();
create trigger protect_buckets_delete
  before delete on storage.buckets
  for each statement execute function storage.protect_delete();

-- 4. purge_business referenced messages; recreate without that line so
--    owner account/business deletion keeps working after the drop.
create or replace function purge_business(p_business_id uuid)
returns uuid[]  -- returns auth_user_ids of all members for auth cleanup
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_user_ids uuid[];
begin
  select coalesce(array_agg(auth_user_id), '{}') into v_auth_user_ids
  from members where business_id = p_business_id;

  delete from notifications where business_id = p_business_id;
  delete from device_tokens
  where member_id in (select id from members where business_id = p_business_id);

  delete from credit_note_items
  where credit_note_id in
    (select id from credit_notes where business_id = p_business_id);
  delete from credit_notes where business_id = p_business_id;
  delete from credit_note_sequences where business_id = p_business_id;

  delete from payments where business_id = p_business_id;
  delete from bill_items
  where bill_id in (select id from bills where business_id = p_business_id);
  delete from bills where business_id = p_business_id;
  delete from bill_sequences where business_id = p_business_id;

  delete from quote_items
  where quote_id in
    (select q.id from quotes q
     join orders o on o.id = q.order_id
     where o.business_id = p_business_id);
  delete from quotes
  where order_id in (select id from orders where business_id = p_business_id);
  delete from order_items
  where order_id in (select id from orders where business_id = p_business_id);
  delete from orders where business_id = p_business_id;

  delete from stock_movements where business_id = p_business_id;
  delete from products where business_id = p_business_id;

  delete from audit_log where business_id = p_business_id;
  delete from customers where business_id = p_business_id;
  delete from members where business_id = p_business_id;
  delete from businesses where id = p_business_id;

  return v_auth_user_ids;
end;
$$;

revoke all on function purge_business(uuid) from public, anon, authenticated;

-- 5. Strip retired 'chat_message' entries from member mute prefs.
update members
set notification_prefs = jsonb_set(
      notification_prefs,
      '{muted}',
      coalesce(notification_prefs -> 'muted', '[]'::jsonb) - 'chat_message'
    )
where notification_prefs -> 'muted' ? 'chat_message';

comment on column members.notification_prefs is
  'Optional {"muted": ["low_stock","dues_reminder"]}. dues_reminder is muted by default.';
