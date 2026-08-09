-- Phase 26: purge_business no longer deletes from categories (table removed
-- in 00000000000025_remove_categories.sql). Recreate the function so owner
-- account/business deletion keeps working after the categories drop.

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

  delete from messages where business_id = p_business_id;
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
