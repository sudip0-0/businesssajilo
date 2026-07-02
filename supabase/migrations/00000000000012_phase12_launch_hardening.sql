-- Phase 12: launch hardening.
-- Forced password change flag, cross-tenant phone uniqueness for logins,
-- session revocation + account deletion helpers (service-role only RPCs).

-- ---------------------------------------------------------------------------
-- 1. members.must_change_password: set by owner-initiated password resets,
--    cleared by the member after choosing a new password.
-- ---------------------------------------------------------------------------

alter table members
  add column must_change_password boolean not null default false;

-- Members clear their own flag via this RPC (they have no UPDATE policy on
-- their own row, and the pin trigger protects identity columns anyway).
create or replace function clear_must_change_password()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update members
  set must_change_password = false
  where auth_user_id = auth.uid()
    and is_active;
end;
$$;

revoke all on function clear_must_change_password() from anon;
grant execute on function clear_must_change_password() to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Phone uniqueness: members.phone is a login identifier (synthetic email
--    is derived from it), so it must be unique across all tenants.
--    Normalized at the edge (digits with +977 prefix).
-- ---------------------------------------------------------------------------

create unique index members_phone_unique_idx
  on members(phone)
  where phone is not null;

-- ---------------------------------------------------------------------------
-- 3. Session revocation (service-role only). Used by reset-member-password
--    so an owner reset kicks out any existing sessions on the member's
--    devices immediately.
-- ---------------------------------------------------------------------------

create or replace function revoke_member_sessions(p_auth_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  update auth.refresh_tokens
  set revoked = true
  where user_id = p_auth_user_id::text
    and revoked = false;
  delete from auth.sessions where user_id = p_auth_user_id;
end;
$$;

revoke all on function revoke_member_sessions(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Account deletion helpers (service-role only; called from the
--    delete-account Edge Function).
--
--    anonymize_member_for_deletion: scrubs personal identity from the member
--    row while retaining financial history (bills/ledger snapshot names and
--    the customer's shop record are the business's own records).
--
--    purge_business: full tenant wipe when the owner deletes the business.
-- ---------------------------------------------------------------------------

create or replace function anonymize_member_for_deletion(p_member_id uuid)
returns uuid  -- returns the auth_user_id so the caller can delete the auth user
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_user_id uuid;
begin
  select auth_user_id into v_auth_user_id from members where id = p_member_id;
  if v_auth_user_id is null then
    raise exception 'member not found';
  end if;

  delete from device_tokens where member_id = p_member_id;
  delete from notifications where recipient_member_id = p_member_id;

  -- Scrub personal contact data from the customer profile but keep the shop
  -- record (dealer's own business data; ledger/bills reference it).
  update customers
  set contact_name = null, phone = null
  where member_id = p_member_id;

  update members
  set display_name = 'Deleted account',
      phone = null,
      is_active = false,
      must_change_password = false
  where id = p_member_id;

  return v_auth_user_id;
end;
$$;

revoke all on function anonymize_member_for_deletion(uuid)
  from public, anon, authenticated;

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
  delete from categories where business_id = p_business_id;

  delete from audit_log where business_id = p_business_id;
  delete from customers where business_id = p_business_id;
  delete from members where business_id = p_business_id;
  delete from businesses where id = p_business_id;

  return v_auth_user_ids;
end;
$$;

revoke all on function purge_business(uuid) from public, anon, authenticated;
