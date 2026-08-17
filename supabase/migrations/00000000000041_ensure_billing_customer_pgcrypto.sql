-- pgcrypto (crypt / gen_salt) lives in the extensions schema.
create or replace function resolve_billing_customer(p jsonb)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, extensions
set row_security = off
as $$
declare
  v_raw text;
  v_id uuid;
  v_phone text;
  v_shop text;
  v_resolved uuid;
  v_biz uuid;
  v_auth uuid;
  v_member uuid;
  v_email text;
  v_member_phone text;
begin
  v_biz := current_business_id();
  v_raw := nullif(btrim(coalesce(p->>'customer_id', '')), '');
  if v_raw is null then
    return null;
  end if;

  begin
    v_id := v_raw::uuid;
  exception when others then
    raise exception 'customer not found';
  end;

  select c.id into v_resolved
  from customers c
  where c.id = v_id and c.business_id = v_biz;
  if v_resolved is not null then
    return v_resolved;
  end if;

  v_phone := nullif(btrim(coalesce(p->>'customer_phone', '')), '');
  if v_phone is not null then
    select c.id into v_resolved
    from customers c
    where c.business_id = v_biz and c.phone = v_phone
    limit 1;
    if v_resolved is not null then
      return v_resolved;
    end if;
  end if;

  v_shop := nullif(btrim(coalesce(
    p->>'customer_shop_name',
    p->>'guest_name',
    ''
  )), '');
  if v_shop is not null then
    select c.id into v_resolved
    from customers c
    where c.business_id = v_biz and lower(c.shop_name) = lower(v_shop)
    limit 1;
    if v_resolved is not null then
      return v_resolved;
    end if;
  end if;

  if v_shop is null then
    v_shop := 'Customer';
  end if;

  v_auth := gen_random_uuid();
  v_member := gen_random_uuid();
  v_email := replace(v_id::text, '-', '') || '@sync.businesssajilo.invalid';

  if v_phone is not null and exists (
    select 1 from members
    where phone = v_phone and is_active
  ) then
    v_member_phone := null;
  else
    v_member_phone := v_phone;
  end if;

  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, phone_change, phone_change_token
  ) values (
    v_auth,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    v_email,
    crypt(gen_random_uuid()::text, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now(),
    '', '', '', '', '', '', ''
  );

  insert into auth.identities (
    user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_auth,
    jsonb_build_object('sub', v_auth::text, 'email', v_email),
    'email',
    v_auth::text,
    now(),
    now(),
    now()
  );

  insert into members (
    id, business_id, auth_user_id, role, display_name, phone, is_active
  ) values (
    v_member,
    v_biz,
    v_auth,
    'customer',
    v_shop,
    v_member_phone,
    false
  );

  insert into customers (
    id, business_id, member_id, shop_name, phone, opening_balance
  ) values (
    v_id,
    v_biz,
    v_member,
    v_shop,
    v_phone,
    0
  );

  return v_id;
end;
$$;
