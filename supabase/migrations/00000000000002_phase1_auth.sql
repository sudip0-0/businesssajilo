-- Phase 1: customers, device_tokens, auth claims sync, extended RLS.

create table customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  member_id uuid not null unique references members(id),
  shop_name text not null,
  contact_name text,
  phone text,
  address text,
  opening_balance bigint not null default 0,
  created_at timestamptz not null default now()
);

create index customers_business_idx on customers(business_id);

create table device_tokens (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references members(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  unique (member_id, token)
);

-- Sync business_id + role into auth.users app_metadata (JWT claims).
create or replace function sync_auth_claims()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  claims jsonb;
begin
  if TG_OP = 'DELETE' then
    return OLD;
  end if;

  if NEW.is_active then
    claims := jsonb_build_object(
      'business_id', NEW.business_id::text,
      'role', NEW.role::text
    );
  else
    claims := jsonb_build_object('deactivated', true);
  end if;

  update auth.users
  set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || claims
  where id = NEW.auth_user_id;

  return NEW;
end;
$$;

create trigger members_sync_auth_claims
  after insert or update of business_id, role, is_active on members
  for each row
  execute function sync_auth_claims();

-- RLS: customers
alter table customers enable row level security;

create policy "owner manages customers" on customers
  for all using (
    business_id = current_business_id()
    and current_role_name() = 'owner'
  )
  with check (
    business_id = current_business_id()
    and current_role_name() = 'owner'
  );

create policy "customer reads own profile" on customers
  for select using (
    member_id = (
      select id from members
      where auth_user_id = auth.uid() and is_active
    )
  );

-- RLS: device_tokens
alter table device_tokens enable row level security;

create policy "member manages own tokens" on device_tokens
  for all using (
    member_id = (
      select id from members
      where auth_user_id = auth.uid() and is_active
    )
  )
  with check (
    member_id = (
      select id from members
      where auth_user_id = auth.uid() and is_active
    )
  );

-- RLS: owner can deactivate co-members (not self).
create policy "owner updates co-members" on members
  for update using (
    business_id = current_business_id()
    and current_role_name() = 'owner'
    and auth_user_id != auth.uid()
  )
  with check (business_id = current_business_id());

-- Force RLS even for table owners (required for policy tests and defense in depth).
alter table businesses force row level security;
alter table members force row level security;
alter table customers force row level security;
alter table device_tokens force row level security;

-- Note: bills table (Phase 4) must block warehouse at DB level.
-- Pattern: SELECT/INSERT only for role IN ('owner','sales').
