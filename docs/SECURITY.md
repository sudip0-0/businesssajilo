# Security Review — BusinessSajilo

## Row Level Security (RLS)

- All tenant tables use `FORCE ROW LEVEL SECURITY` with `current_business_id()` and `current_role_name()` helpers.
- pgTAP suite in `supabase/tests/` covers phases 1–8 plus storage and cross-tenant isolation.
- Run locally: `supabase test db`

## Storage

- `product-images` and `order-chat-images` buckets are tenant-scoped by folder name (`business_id`).
- Policies: staff read product images; owner upload/update/delete; warehouse cannot upload product images.

## Auth rate limits

Configured in `supabase/config.toml` under `[auth.rate_limit]` (email sign-up, sign-in, token refresh). Production should monitor abuse and enable captcha if needed.

## Edge Functions

- `register-business` — public; relies on Supabase auth rate limits.
- `create-member` — owner JWT required.
- `notify` — service role / webhook triggered.

## Production checklist

- [ ] Rotate Supabase anon/service keys; use `--dart-define` in CI only via secrets
- [ ] Enable leaked password protection and email confirmation in prod Auth settings
- [ ] Review storage bucket policies after any migration
- [ ] Run full `supabase test db` before each release
- [ ] Restrict Edge Function CORS to known app origins in prod
- [ ] Enable captcha on public registration if sign-up abuse occurs
