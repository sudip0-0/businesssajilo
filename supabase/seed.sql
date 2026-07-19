-- Local / E2E seed (applied on `supabase db reset`).
-- Password for seeded auth user: password123
-- Used by test/integration bootstrap and Playwright e2e defaults.

-- Token columns must be '' not NULL — GoTrue scans them as Go strings.
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new,
  email_change, email_change_token_current, phone_change, phone_change_token
) values (
  'e2e00000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'e2e-owner@test.com',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now(),
  '', '', '', '', '', '', ''
) on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) values (
  'e2e00000-0000-4000-8000-000000000001',
  'e2e00000-0000-4000-8000-000000000001',
  jsonb_build_object('sub', 'e2e00000-0000-4000-8000-000000000001', 'email', 'e2e-owner@test.com'),
  'email',
  'e2e00000-0000-4000-8000-000000000001',
  now(),
  now(),
  now()
) on conflict do nothing;

insert into businesses (id, name, name_np)
values (
  'e2e00000-0000-4000-8000-000000000010',
  'E2E Demo Traders',
  'ई२ई डेमो'
) on conflict (id) do nothing;

insert into members (id, business_id, auth_user_id, role, display_name, phone, is_active)
values (
  'e2e00000-0000-4000-8000-000000000020',
  'e2e00000-0000-4000-8000-000000000010',
  'e2e00000-0000-4000-8000-000000000001',
  'owner',
  'E2E Owner',
  '+9779800000001',
  true
) on conflict (id) do nothing;
