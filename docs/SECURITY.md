# Security Review — BusinessSajilo

## Row Level Security (RLS)

- All tenant tables use `FORCE ROW LEVEL SECURITY` with `current_business_id()` and `current_role_name()` helpers.
- pgTAP suite in `supabase/tests/` (including v1.2 QoL in `rls_phase33_qol_v12_test.sql`, list filters in `rls_phase36_qol_filters_test.sql`, and gated balance projections in `rls_phase37_balance_projection_test.sql`).
- Run locally: `supabase test db`

## Storage

- `product-images` uses tenant-folder and role-gated policies; owner upload/update/delete is allowed and warehouse upload is denied.
- Order chat, `messages`, and the `order-chat-images` bucket were removed by migration 43. Do not restore them through old deployment checklists.

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
- `notify` — service role / webhook triggered. `pushed_at` is set only after all FCM sends succeed; invalid tokens are deleted. Repeat invocation is idempotent.

All five functions **fail closed** if `ALLOWED_ORIGIN` is unset at boot (see `supabase/README.md`).

## Passwords & account recovery

- Minimum password length 8 (`config.toml` + client validators).
- Owner self-service reset via email (`resetPasswordForEmail`).
- Phone-login accounts use synthetic emails (`*@phone.businesssajilo.app`) with no inbox — the login UI blocks forgot-password for phone identifiers and directs users to ask the owner.
- Owner-initiated member resets force a password change on next login
  (router blocks the app until `must_change_password` clears via the
  `clear_must_change_password` RPC).

## Billing / payment write path

- Direct client `INSERT` on `bills`, `bill_items`, and `payments` is denied by RLS (migration 16 removes their insert policies; migration 49 grants baseline table privileges).
- Clients must use `create_bill` / `record_payment` SECURITY DEFINER RPCs (migration 16).
- Warehouse may create/read bills but cannot read raw `customers` rows, opening balances, payments, balance views, ledgers, or `audit_log`. Migration 50 exposes billing identity fields through the read-only `customer_directory` security-barrier view, with explicit active-membership, tenant, role, and customer-own filters. This view intentionally uses definer privileges to avoid granting warehouse access to underlying financial columns. Bill embeds use the directory; do not restore warehouse SELECT on `customers`.
- `search_bills` is staff-wide plus a customer own-bill path (migration 58). It must not return another customer's bills or staff catalog data.
- Warehouse order prefill uses `billing_draft_from_order` (migration 58): accepted-quote or order-item lines plus directory identity. It does not grant warehouse SELECT on orders, quotes, quote history, or customer finance.
- Offline sync pushes payments via `record_payment`; legacy `bill_items` queue entries are rejected. Financial acknowledgements validate identity before marking local work synced; malformed responses remain retryable.
- `place_order` atomically validates and inserts customer orders; `respond_quote` validates quote response ownership, state, expiry, and immutable terms. These are online-only RPCs.
- Oldest-first payment allocation locks candidate bills before recomputing net debt from payments and credit notes. Excess remains account credit; explicit single-bill allocation retains its existing whole-amount semantics.
- Billing recovery only resolves existing same-business customers by ID or unambiguous identity. It must not provision Auth/member/customer rows; owner credential creation remains in `create-member`.
- Child tenant columns and composite parent foreign keys are enforced by migration 57. Review its backfill/locking deployment requirements in `handoff.md`; local application is not hosted deployment approval.
- Migration 58 is additive (search/draft RPC + audit SELECT narrowing) and does not rewrite applied history.
- Edge Function shared validators (`supabase/functions/_shared/validation.ts`) have Deno unit tests — run via `scripts/local_hardening_gate.ps1` or `deno test supabase/functions/_shared/validation_test.ts`.

## Observability

- Production crash reporting uses `sentry_flutter` when `SENTRY_DSN` is passed via `--dart-define` (wired in `.github/workflows/release.yml`). Set the GitHub Actions secret before a production tag.
- Performance tracing is sampled at `SENTRY_TRACES_SAMPLE_RATE` (default **0.1**). Auth session load, sync, `create_bill` / dashboard RPCs, and route changes emit spans. Sync completion logs `failedCount` without customer PII.
- Local diagnosis uses `AppLog` (debug + Sentry breadcrumbs when DSN is set).

## Push (web)

- Mobile FCM works when Firebase dart-defines are configured (also passed in `release.yml`).
- Web uses `web/firebase-messaging-sw.js` plus `web/firebase-config.js`. Copy `web/firebase-config.example.js` and fill the Firebase web app keys before treating web push as production-ready.

## Production checklist

- [ ] Rotate Supabase anon/service keys; use `--dart-define` in CI only via secrets
- [ ] Enable leaked password protection and email confirmation in prod Auth settings
- [ ] Enable captcha (Turnstile) on prod Auth — see commented `[auth.captcha]` in `config.toml`; local stays captcha-free for tests
- [ ] Set `ALLOWED_ORIGIN` env on all Edge Functions in prod (required at boot; unset fails closed — see `supabase/README.md`)
- [ ] Configure prod SMTP so password-reset emails deliver (site_url + redirect URLs)
- [ ] Review storage bucket policies after any migration
- [ ] Run full `supabase test db` before each release
- [ ] Replace `web/firebase-config.js` placeholders with the generated Firebase web app config when enabling web push

## Local data

- Staff offline cache (Drift) is not encrypted at rest. Treat the device as
  staff-trusted; full-disk encryption on the phone is the current mitigation.
  SQLCipher / Drift encryption is a post-launch follow-up if stolen-device
  risk shows up in pilots.
