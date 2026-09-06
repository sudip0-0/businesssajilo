# Production checklist (BusinessSajilo)

This is an operations checklist, not evidence that a hosted service is configured. Local `supabase/config.toml` is development configuration. Do not deploy, reset data, rotate credentials, send notifications, or incur service costs without explicit approval.

## Edge runtime / CORS

- [ ] Set `ALLOWED_ORIGIN` on every deployed Edge Function to the approved application origin.
- [ ] Verify an unset or wildcard origin fails closed. Local configuration uses `http://localhost:3000`; wildcard origins are rejected by the function handlers.
- [ ] Exercise registration and owner-only member creation against the approved staging environment, including rejected non-owner requests.

## Auth and account lifecycle

- [ ] Verify hosted password policy, leaked-password protection, email confirmation, and registration captcha against the actual registration flow. Dashboard settings alone are not proof of enforcement.
- [ ] Configure SMTP, `site_url`, and redirect allowlists; verify a password-reset email is delivered and recovery completes.
- [ ] Verify phone-login staff/customer recovery through owner reset and forced password change; synthetic phone-login emails have no inbox.
- [ ] Verify deactivated accounts cannot read/write tenant data, and failed account deletion leaves a recoverable session.
- [ ] Verify deletion requires recent password re-authentication and that the retention/purge behavior matches the reviewed privacy policy.
- [ ] Evaluate owner MFA in a dedicated authentication pass; do not claim MFA is shipped or enforced merely because the provider supports it.

## Financial and tenant boundaries

- [ ] Run the full pgTAP suite on the approved target's migration set and verify per-role allow/deny and cross-tenant cases.
- [ ] Verify warehouse customer selection and billing while direct opening-balance, payment, ledger, and dues reads are denied.
- [ ] Verify customer catalog data contains no prices or restricted stock fields; customer bills/dues remain own-account only.
- [ ] Verify bill/payment replay, stock movement invariants, quote-to-bill amounts, credit notes, and payment allocation using disposable test fixtures.
- [ ] Keep customer-balance projection reads disabled until parity is zero and the documented benchmark gate passes.

## Storage and notifications

- [ ] Review tenant-folder policies on `product-images`, including owner upload, authorized reads, and warehouse upload denial.
- [ ] Confirm removed chat tables, triggers, and `order-chat-images` storage have not been reintroduced.
- [ ] Configure Firebase client values, web service-worker configuration, VAPID, and the server FCM service account through the approved secret/configuration mechanism.
- [ ] Verify opt-in test push delivery, token cleanup, notification preferences, and safe payloads. In-app notification records do not prove push delivery.

## Observability and recovery

- [ ] Configure `SENTRY_DSN` and verify a sanitized test event from an approved release build; avoid customer financial data and credentials in logs.
- [ ] Confirm the actual backup/PITR availability and retention of the hosted Supabase plan; do not assume backups are enabled.
- [ ] Agree recovery-point and recovery-time objectives with the business owner.
- [ ] Restore an approved backup into an isolated non-production environment and verify tenant isolation, financial totals, storage references, and Auth recovery. Record the result before calling disaster recovery tested.
- [ ] Establish an operational owner and a forward-fix/recovery procedure for failed migrations. A rollback document is not a completed restore drill.

## Secrets, release and platform sign-off

- [ ] Never apply demo/E2E seeds to a shared, staging, or production database. Keep test credentials confined to disposable local fixtures.
- [ ] Review and rotate credentials known to have been exposed; never copy service-role credentials into client builds.
- [ ] Run formatting, generated-code checks where applicable, analyze, Flutter tests, pgTAP, Deno tests, and browser verification. Record skipped/blocked checks separately from passes.
- [ ] Verify Android and Web in EN/NP, including narrow layouts, keyboard/focus and large text. Verify iOS on macOS/device tooling before an iOS release.
- [ ] Resolve outstanding CI/release command or harness failures before tagging. Successful direct-route screenshots do not prove working buttons or transaction workflows.
- [ ] Complete reviewed store listing copy, privacy policy, screenshots, and signing requirements.

Release tags (`v*`) can push migrations and deploy functions when GitHub deployment secrets are configured. This checklist does not authorize tagging or deployment. Follow the forward-fix policy in `supabase/README.md`, review the entire release diff, and obtain explicit deployment approval.
