-- Phase 0 scaffold: core enums + tenancy root tables.
-- Apply with: supabase db push (after `supabase link` / `supabase init`).

create type member_role as enum ('owner', 'sales', 'warehouse', 'customer');

create type order_status as enum (
  'draft', 'placed', 'quoted', 'accepted', 'rejected', 'confirmed',
  'packed', 'dispatched', 'billed', 'closed', 'cancelled'
);

create type quote_status as enum ('sent', 'accepted', 'rejected');
create type bill_status as enum ('paid', 'partial', 'due');
create type payment_method as enum ('cash', 'cheque', 'wallet', 'bank');
create type stock_movement_type as enum ('stock_in', 'adjust', 'dispatch');

create table businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_np text,
  address text,
  phone text,
  logo_url text,
  subscription_plan text not null default 'free',
  created_at timestamptz not null default now()
);

create table members (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  auth_user_id uuid not null unique references auth.users(id),
  role member_role not null,
  display_name text not null,
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index members_business_idx on members(business_id);

-- Helpers used by all RLS policies.
create or replace function current_business_id() returns uuid
language sql stable security definer set search_path = public as $$
  select business_id from members where auth_user_id = auth.uid() and is_active
$$;

create or replace function current_role_name() returns member_role
language sql stable security definer set search_path = public as $$
  select role from members where auth_user_id = auth.uid() and is_active
$$;

alter table businesses enable row level security;
alter table members enable row level security;

create policy "members read own business" on businesses
  for select using (id = current_business_id());

create policy "owner updates business" on businesses
  for update using (id = current_business_id() and current_role_name() = 'owner');

create policy "members read co-members" on members
  for select using (business_id = current_business_id());

-- Inserts into members happen only via the create-member Edge Function
-- (service role), never directly from clients.
