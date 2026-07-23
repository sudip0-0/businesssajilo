# Production checklist (BusinessSajilo)

Run through this list before pointing a production Flutter build at a
hosted Supabase project. Local `supabase/config.toml` values are for
dev only — several of them are intentionally loose.

## Edge runtime / CORS

- [ ] `supabase secrets set ALLOWED_ORIGIN=https://your-app.example.com`
  - Local default in `config.toml` is `ALLOWED_ORIGIN = "*"` which must
    never ship to production. Combined with `register-business`
    (`verify_jwt = false`), an open origin enables cross-site signup spam.

## Auth hardening

- [ ] Enable email confirmations (`[auth.email] enable_confirmations = true`)
- [ ] Set password requirements (length + character classes) —
  local `password_requirements = ""` is too weak
- [ ] Enable captcha on signup (hCaptcha / Turnstile) for
  `register-business`
- [ ] Enable MFA for owner accounts
- [ ] Confirm `secure_password_change = true` so password changes require
  recent re-authentication
- [ ] Confirm business deletion requires password re-auth (Phase 19
  `delete-account` edge function)

## Observability

- [ ] Set `SENTRY_DSN` as a GitHub Actions secret and pass it via
  `--dart-define=SENTRY_DSN=...` in the release workflow
- [ ] Verify a test exception appears in the Sentry project after a
  release build

## Secrets

- [ ] Never apply `supabase/seed.sql` (or any seed with `password123`)
  to a shared/staging/production project
- [ ] Rotate any keys that were ever committed or shared in chat

## Storage / RLS

- [ ] Confirm migration `00000000000019_security_hotfix` is applied
  (order-scoped chat image policies + `payments(bill_id)` index)
- [ ] Smoke-test: customer A cannot open customer B's order-chat image
  in the same business

## Deploy

Release tags (`v*`) push migrations and deploy Edge Functions when
`SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`, and
`SUPABASE_DB_PASSWORD` are configured (see `.github/workflows/release.yml`
and the rollback policy in `supabase/README.md`). Manual fallback:

- [ ] `supabase db push` for migrations
- [ ] `supabase functions deploy` for `create-member`,
  `register-business`, `reset-member-password`, `delete-account`,
  `notify`
