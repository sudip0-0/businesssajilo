# Security Review — BusinessSajilo

## Row Level Security (RLS)

- All tenant tables use `FORCE ROW LEVEL SECURITY` with `current_business_id()` and `current_role_name()` helpers.
- pgTAP suite in `supabase/tests/` (15 files): phases 1–8, phase 10 hardening, phase 11 credit notes, phase 12 launch hardening, phase 13 business logic, phase 15 dues-aging RPC, plus `rls_cross_tenant_test.sql` and `rls_storage_test.sql`.
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

All five functions **fail closed** if `ALLOWED_ORIGIN` is unset at boot (see `supabase/README.md`).

## Passwords & account recovery

- Minimum password length 8 (`config.toml` + client validators).
- Owner self-service reset via email (`resetPasswordForEmail`).
- Phone-login accounts use synthetic emails (`*@phone.businesssajilo.app`) with no inbox — the login UI blocks forgot-password for phone identifiers and directs users to ask the owner.
- Owner-initiated member resets force a password change on next login
  (router blocks the app until `must_change_password` clears via the
  `clear_must_change_password` RPC).

## Billing / payment write path

- Direct `INSERT` on `bills`, `bill_items`, and `payments` is revoked for `authenticated`.
- Clients must use `create_bill` / `record_payment` SECURITY DEFINER RPCs (migration 16).
- Offline sync pushes payments via `record_payment`; legacy `bill_items` queue entries are rejected.
- Edge Function shared validators (`supabase/functions/_shared/validation.ts`) have Deno unit tests — run via `scripts/local_hardening_gate.ps1` or `deno test supabase/functions/_shared/validation_test.ts`.

## Observability

- Production crash reporting (Sentry / Crashlytics) is **deferred** — see backlog in `tasks.md`.
- Local diagnosis uses `debugPrint` for sync/auth/push failures.

## Push (web)

- Mobile FCM works when Firebase dart-defines are configured.
- Web uses stub `web/firebase-messaging-sw.js` until a real Firebase web config is deployed; do not treat web push as production-ready until that stub is replaced.

## Production checklist

- [ ] Rotate Supabase anon/service keys; use `--dart-define` in CI only via secrets
- [ ] Enable leaked password protection and email confirmation in prod Auth settings
- [ ] Enable captcha (Turnstile) on prod Auth — see commented `[auth.captcha]` in `config.toml`; local stays captcha-free for tests
- [ ] Set `ALLOWED_ORIGIN` env on all Edge Functions in prod (required at boot; unset fails closed — see `supabase/README.md`)
- [ ] Configure prod SMTP so password-reset emails deliver (site_url + redirect URLs)
- [ ] Review storage bucket policies after any migration
- [ ] Run full `supabase test db` before each release
- [ ] Replace web FCM stub with generated Firebase messaging service worker when enabling web push
