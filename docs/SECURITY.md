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

- `register-business` — public; relies on Supabase auth rate limits + in-memory IP rate limit.
- `create-member` — owner JWT required. Derives a synthetic login email
  (`<phone>@phone.businesssajilo.app`) when no email is given; phone numbers
  are normalized to `+9779XXXXXXXXX` and globally unique (`members_phone_unique_idx`).
- `reset-member-password` — owner JWT required; sets a temporary password,
  flags `members.must_change_password`, and revokes the member's sessions.
- `delete-account` — member JWT required. `mode: self` anonymizes the member
  (financial snapshots retained); `mode: business` (owner only) purges the
  whole tenant including storage folders and auth users.
- `notify` — service role / webhook triggered.

## Passwords & account recovery

- Minimum password length 8 (`config.toml` + client validators).
- Owner self-service reset via email (`resetPasswordForEmail`).
- Owner-initiated member resets force a password change on next login
  (router blocks the app until `must_change_password` clears via the
  `clear_must_change_password` RPC).

## Production checklist

- [ ] Rotate Supabase anon/service keys; use `--dart-define` in CI only via secrets
- [ ] Enable leaked password protection and email confirmation in prod Auth settings
- [ ] Enable captcha (Turnstile) on prod Auth — see commented `[auth.captcha]` in `config.toml`; local stays captcha-free for tests
- [ ] Set `ALLOWED_ORIGIN` env on all Edge Functions in prod (restricts CORS to app origins)
- [ ] Configure prod SMTP so password-reset emails deliver (site_url + redirect URLs)
- [ ] Review storage bucket policies after any migration
- [ ] Run full `supabase test db` before each release
