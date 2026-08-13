-- Harden dues-reminder mute: skip inserts (and the whole nudge fan-out)
-- when the type is in members.notification_prefs.muted. Persist prefs as jsonb
-- so the Flutter client can send a JSON array without text[] encoding issues.

create or replace function notification_type_is_muted(
  p_member_id uuid,
  p_type text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select coalesce(m.notification_prefs -> 'muted', '[]'::jsonb)
        @> jsonb_build_array(p_type)
      from members m
      where m.id = p_member_id
    ),
    false
  );
$$;

revoke all on function notification_type_is_muted(uuid, text) from public;

create or replace function insert_notification(
  p_business_id uuid,
  p_recipient_member_id uuid,
  p_type text,
  p_payload jsonb default '{}'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
begin
  if notification_type_is_muted(p_recipient_member_id, p_type) then
    return null;
  end if;

  insert into notifications (business_id, recipient_member_id, type, payload)
  values (
    p_business_id,
    p_recipient_member_id,
    p_type,
    coalesce(p_payload, '{}'::jsonb)
  )
  returning id into new_id;
  return new_id;
end;
$$;

create or replace function process_operational_nudges()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int := 0;
  rec record;
  member_row record;
  v_biz uuid;
begin
  if current_role_name() not in ('owner', 'sales') then
    raise exception 'forbidden';
  end if;
  v_biz := current_business_id();

  for rec in
    select q.id, q.order_id
    from quotes q
    join orders o on o.id = q.order_id
    where o.business_id = v_biz
      and q.status = 'sent'
      and q.expires_at is not null
      and q.expires_at < now()
  loop
    if exists (
      select 1 from notifications n
      where n.business_id = v_biz
        and n.type = 'quote_stale'
        and n.payload->>'quote_id' = rec.id::text
        and n.created_at > now() - interval '24 hours'
    ) then
      continue;
    end if;
    for member_row in
      select id from members
      where business_id = v_biz and is_active and role in ('owner', 'sales')
    loop
      if insert_notification(
        v_biz,
        member_row.id,
        'quote_stale',
        jsonb_build_object('quote_id', rec.id, 'order_id', rec.order_id)
      ) is not null then
        v_count := v_count + 1;
      end if;
    end loop;
  end loop;

  -- Owner/sales mute is a kill switch: do not fan out dues reminders to
  -- anyone (including the customer) while the acting member has them muted.
  if notification_type_is_muted(current_member_id(), 'dues_reminder') then
    return v_count;
  end if;

  for rec in
    select c.id, c.shop_name, c.member_id, cb.balance_due
    from customers c
    join customer_balances cb on cb.customer_id = c.id
    where c.business_id = v_biz
      and cb.balance_due > 0
    order by cb.balance_due desc
    limit 25
  loop
    if exists (
      select 1 from notifications n
      where n.business_id = v_biz
        and n.type = 'dues_reminder'
        and n.payload->>'customer_id' = rec.id::text
        and n.created_at > now() - interval '7 days'
    ) then
      continue;
    end if;
    for member_row in
      select id from members
      where business_id = v_biz
        and is_active
        and (
          role = 'owner'
          or id = rec.member_id
        )
    loop
      if insert_notification(
        v_biz,
        member_row.id,
        'dues_reminder',
        jsonb_build_object(
          'customer_id', rec.id,
          'shop_name', rec.shop_name,
          'balance_due', rec.balance_due
        )
      ) is not null then
        v_count := v_count + 1;
      end if;
    end loop;
  end loop;

  return v_count;
end;
$$;

drop function if exists update_own_notification_prefs(text[]);

create or replace function update_own_notification_prefs(p_muted jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_muted jsonb;
begin
  v_muted := coalesce(p_muted, '[]'::jsonb);
  if jsonb_typeof(v_muted) <> 'array' then
    raise exception 'p_muted must be a json array';
  end if;

  update members
  set notification_prefs = jsonb_build_object('muted', v_muted)
  where id = current_member_id();

  if not found then
    raise exception 'forbidden';
  end if;
end;
$$;

grant execute on function update_own_notification_prefs(jsonb) to authenticated;
grant execute on function process_operational_nudges() to authenticated;
