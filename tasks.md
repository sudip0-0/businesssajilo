# BusinessSajilo — Task Breakdown

Phases 0–13 are the historical implementation log; later migrations supersede earlier behavior. Checked implementation items do not prove production configuration or platform sign-off. Current hardening results, limitations, and the next actions are tracked in the audit sections and `handoff.md`. ✅ = implemented, ⬜ = todo.

## Phase 0 — Project Setup
- ✅ Create Flutter project (Android, iOS, Web enabled); env via `--dart-define` (`Env`)
- ✅ Add core deps: supabase_flutter, riverpod (no codegen — analyzer conflict with drift_dev), go_router, drift, freezed, intl, nepali_utils (firebase_messaging deferred to Phase 6)
- ✅ Migrations folder + initial migration (enums, businesses, members, RLS helpers); Supabase project link pending (see supabase/README.md)
- ✅ CI: GitHub Actions analyze/test + web build artifact
- ✅ Theme, l10n scaffolding (EN/NP ARB files), BS date utils, money formatter (`Paisa` int type) + tests
- ✅ Design-system widgets (`core/ui/`): MoneyText, StatusChip, QtyStepper, SyncBadge, EmptyState

## Phase 1 — Tenancy, Auth & Roles
- ✅ DB: `businesses`, `members`, `customers`, `device_tokens` + FORCE RLS + auth claims trigger
- ✅ Business registration flow (`register-business` Edge Function + register screen)
- ✅ Edge Function `create-member` (owner creates sales/warehouse/customer logins)
- ✅ Login (email + password), session persistence, role in JWT app_metadata via trigger
- ✅ Role-aware routing: 4 role home shells with bottom nav (warehouse billing enabled later; no ledger/payments)
- ✅ Staff management screen (owner: list, add, deactivate members)
- ✅ RLS test suite (`supabase test db` — full suite in `supabase/tests/`: phases 1–8, 10–13, cross-tenant, storage)

## Phase 2 — Products & Inventory
- ✅ DB: `categories`, `products`, `stock_movements`, `notifications` + stock_cached trigger + RLS + storage bucket
- ✅ Product CRUD (owner) with image upload (Supabase Storage), EN/NP names
- ✅ Category management was implemented historically; removed by migration 25 and no longer part of the product
- ✅ Stock-in entry, manual adjustment (reason required) — owner/warehouse
- ✅ Stock list with levels + low-stock badges; movement history per product
- ✅ Low-stock threshold alerts (DB trigger → notification records)

## Phase 3 — Customers & Ledger
- ✅ DB: `payments` + `customer_balances` / `customer_ledger_entries` views + extended RLS
- ✅ Customer CRUD (owner) incl. credential creation, opening balance
- ✅ Customer list with dues summary; customer detail with ledger statement
- ✅ Record payment flow (cash/cheque/wallet/bank ref), account-level allocation

## Phase 4 — Billing (online first)
- ✅ DB: `bills`, `bill_items`, `bill_sequences` + per-business BS-0001 numbering + RLS (warehouse billing enabled later; payments remain blocked)
- ✅ Billing screen: product search, qty steppers, discounts, running total
- ✅ Payment sheet on save: Paid / Partial / Due → ledger entries
- ✅ Walk-in (no-customer) bills
- ✅ Bill list + bill detail (immutable snapshot view)

## Phase 5 — Orders & Quotes (customer app)
- ✅ DB: `orders`, `order_items`, `quotes`, `quote_items`, `messages` + RLS
- ✅ Customer catalog (no prices), cart, place order with note
- ✅ Staff order queue; quote builder (rates, discounts) + send
- ✅ Customer quote view: accept/reject with comment; quote versioning on re-quote
- ✅ Current order pipeline: placed → received → billed; only `create_bill` applies the billed transition and creates stock deductions (migration 27)
- ✅ Owner/sales order billing uses accepted quote quantities, rates, and discounts when present; it remains online-only
- ✅ Order chat thread shipped in Phase 5; **removed post-launch** (migration 43 drops `messages`, trigger, and `order-chat-images` bucket)
- ✅ Customer "My Dues" + own bill history

## Phase 6 — Notifications
- ✅ FCM client/service-worker and token-registration code; Android/iOS/Web configuration and actual push delivery require separate operational verification
- ✅ Edge Function `notify` + DB webhooks for order/quote/low-stock/payment events
- ✅ In-app notification center with read states

## Phase 7 — Offline Sync (staff mobile)
- ✅ Drift schema mirroring core tables; repository swap (local-first on mobile staff)
- ✅ Sync queue: ordered push of bills/payments/stock movements with idempotent UUID upserts
- ✅ Delta pull sync (`updated_at` watermark) + initial bootstrap
- ✅ Provisional bill numbering (device prefix) + server-side final assignment
- ✅ Sync status UI (badge, pending-items screen, retry)
- ✅ Append-only replay and offline tests; product/customer mutations are online-only, and the unused product LWW RPC was removed by migration 20

## Phase 8 — Reports & Dashboard
- ✅ Owner dashboard: today's sales, dues total, low stock, pending orders
- ✅ Sales summary report (daily/weekly/monthly, top products/customers)
- ✅ Dues aging report (0–30/31–60/60+)
- ✅ Stock valuation report
- ✅ Web responsive layouts (nav rail, two-pane, data tables)

## Phase 9 — Polish & Release
- ✅ Nepali translation pass on all strings; BS date verification
- ✅ Empty states, error states, skeleton loaders on most list screens; dashboards use progress indicators instead of `…` and retry on error
- ✅ Performance pass (web CanvasKit, list virtualization, image caching)
- ✅ Security review: RLS audit, rate limits, storage rules
- ✅ Play Store + App Store listing **copy drafted** (`docs/release/`); store submission / screenshots still manual
- ✅ Release pipeline for web + Android AAB (`release.yml`); prod deploy requires secrets + manual verification
- ✅ Onboarding tour + seed/demo data for new businesses

## Phase 10 — Post-v1 Increments (shipped)
- ✅ Security & integrity hardening (migration 10): bill_sequences lockdown, cross-tenant FK guards, transactional billing/quoting RPCs, bill status lifecycle, composite indexes, NPT report timezones
- ✅ Credit notes / sales returns (migration 11): per-business CN numbering, optional restock (`return` stock movement), ledger & report integration (`lib/features/billing/credit_note_*`)
- ✅ Invoice export & share: PDF + image builders, OS share sheet (`lib/core/invoicing/`)
- ✅ Report CSV export: sales summary, dues aging, stock valuation (`lib/core/export/`)

## Phase 11 — Launch Hardening (pre-release blockers + quick wins)
- ⚠️ T-101 Password reset: email self-service forgot-password + owner `reset-member-password` Edge Function. Phone-login users cannot self-reset by email — UI shows owner-reset hint (intentional; synthetic emails have no inbox).
- ✅ T-102 Phone-number login: login accepts email or phone (`core/utils/login_identifier.dart` ↔ synthetic email in `create-member`); email now optional on member/customer creation; phone normalized to `+977…` and globally unique (`members_phone_unique_idx`)
- ✅ T-103 Account deletion (store compliance): `delete-account` Edge Function; account menu on owner settings, customer/sales/warehouse shells (mobile), and web top-bar for non-owners
- ✅ T-104 Reorder from past order: one-tap cart prefill from order detail, inactive products skipped with notice
- ✅ T-105 Shareable customer statement: 30/90-day/all-time ledger statement (BS+AD dates, opening/closing balance) as PDF/image via share sheet; totals invariant covered by `statement_document_test.dart`
- ✅ T-108 Registration hardening: min password length 8 (config + all validators); prod captcha/CORS/leaked-password steps documented in `docs/SECURITY.md` checklist (dashboard-side, do before launch)

## Phase 12 — Local verification & docs (2026-07-23)
- ✅ Remote repository HTTP contract tests expanded (`record_payment`, dashboard KPIs, low stock, dues aging, entity mapping, idempotent bill replay)
- ✅ Auth repository/provider/router tests for deactivation, forced password change, re-auth, self-delete, role redirects
- ✅ Sync strategy tests: customer-balance watermark, bootstrap resume offsets, bill/payment ordering, queue idempotency / legacy rejection
- ✅ Repository integration was expanded to real quote versions/acceptance/billing; deterministic UI screen integration now replaces the old bootstrap stub
- ✅ Deno unit tests for Edge Function `validation.ts`
- ✅ `scripts/local_hardening_gate.ps1` + `docs/LOCAL_TESTING.md`
- ✅ Repair compile errors in `dashboard_scoped_queries_test.dart` and `offline_query_scale_test.dart`
- ✅ Cart → quote versions → acceptance → bill screen pumps run with deterministic repositories; live backend and device/browser verification remain separate layers

## Phase 13 — v1.2 QoL (2026-08)
- ✅ Bill-level / oldest-first payment allocation (`record_payment` + payment sheet)
- ✅ Last-quoted-rate memory on quote builder
- ✅ Quote expiry (7 days) + stale-quote / dues reminder nudges
- ✅ Business profile editor (name/address/phone on invoices)
- ✅ First-run tour, global search, copy-last-bill, notification mutes
- ✅ Image compression before upload; independent sync push batching
- ✅ Web FCM service worker (fill `web/firebase-config.js` for production)
- ✅ Sentry + Firebase dart-defines on release builds; `scripts/run_dev.sh`
- ⚠️ Remaining client folds are UI totals of RPC rows (not extra round-trips). Drift encryption at rest is deferred (see `docs/SECURITY.md`).

## Audit batch 1A — Warehouse financial privacy (2026-09-05)

Implementation verified below; platform sign-off remains open.

- [x] Migrations 50/51 remove warehouse raw-customer access, preserve identity-only billing directory/search, and prohibit client directory mutations. Applied locally; pgTAP: 259 assertions across 31 files passed, including 37 privacy/role/tenant assertions.
- [x] Remote bill embeds, mobile/web copy and customer lookup, invoice address lookup, and staff-mobile directory sync use non-financial identities. Warehouse skips payment pulls; offline directory reads mask financial values without deleting cached or pending data.
- [x] Customer selection and due-bill submission privacy tests pass in EN/NP at phone and desktop sizes; fixed the narrow web bill header overflow. Live local repository test verifies customer selection, bill creation/reopen/search, and denied financial reads.
- [x] `flutter analyze`: no issues. Full Flutter suite: 433 passed, 10 skipped; the new live warehouse integration was also run separately with required local configuration and passed. Release web build passed with an existing icon-font warning. Changed Dart files pass formatting.
- [ ] Android/iOS device verification; no Android device/emulator or iOS tooling available during this batch.
- [x] The build-based browser harness subsequently passed 29 widget tests and the repaired actual-app runner passed 17 E2E checks, including real navigation, notification Escape/View All, and persisted EN/NE changes. Direct `flutter test --platform chrome` still encounters CanvasKit asset 404s; use the supported build-based harness.
- [ ] Device and hosted-service sign-off remain open. Later on-disk verification is recorded in Audit batch 1C; unsaved IDE buffers cannot be verified from filesystem tests. Earlier counts above are historical checkpoints, not a release-ready claim.

## Audit batch 1B — Core reliability and verification (2026-09-06)

- [x] Migrations 52–57 applied locally and confirmed: atomic/replay-safe orders, quote-response safeguards, order/customer binding, serialized credit-note-aware allocation, existing-customer-only billing recovery, and explicit child-table tenant scope. Latest pgTAP: 496 assertions across 35 files passed.
- [x] Accepted quote terms and fractional paisa are preserved in owner/sales billing; staff-mobile order billing delegates online. The old UI integration stub now exercises actual screens with deterministic repositories; three live backend integration tests passed separately.
- [x] Invalid money text blocks billing; transaction details/PDFs/CSV/words preserve paisa. Import/product-create partial failures retain identity and require reconciliation instead of blind retry; protection is session-local, not durable atomic import.
- [x] Sync acknowledgement, dependency replay, scoped caches, cancellation, and account-failure recovery are hardened. Legacy recovery uses approved sqlite3 3.5.1 read-only transactions, not temporary whole-database copies; pending/failed payment pulls preserve local work.
- [x] Role-aware search, shell semantics, notification Escape/focus, and local bundled-font behavior verified: latest browser checkpoint 29/29 widget tests and 17/17 actual-app E2E checks.
- [x] Follow-up filesystem Flutter suite: 595 passed, 10 skipped. Full analyzer clean. Format check clean (536 files). pgTAP: 520 assertions across 36 files, including migration 58.
- [x] Payment bootstrap cursor reset is on disk in `sync_pusher.dart` with split-receipt/request-identity tests. Unsaved editor buffers were not available; the filesystem version now contains the intended additions.
- [x] Approved CI/release workflow wiring: unsupported `--web-renderer canvaskit` removed, generated-source `git diff --exit-code`, build-based browser widget harness, local-resource actual-app E2E, local-gate dart-defines, informational `pub outdated`.
- [x] Customer own-bill search, warehouse billing-draft RPC, warehouse audit-log deny, quote paisa display, and web safe-integer line/total checks. External/device/hosted sign-off remains in `handoff.md`. No overall release-ready claim is made.

## Audit batch 1C — Independent Grok completion review (2026-09-06)

- [x] Reproduced and fixed order-bill invalid quantities, exact-money overflow, cross-field stale values, and row-deletion state loss; valid corrections preserve accepted quote terms.
- [x] Regular mobile/web bill and quote previews reject unsafe totals without throwing during rendering; submit validation remains authoritative.
- [x] Migration 59 applied locally: direct-client billed/quote-response guards and customer-readable quote product-name snapshots. Renamed products do not replace snapshots in quote mapping or web order-bill prefill. Existing cross-tenant guards retained.
- [x] Fixed localized-time U+202F font fallback using bundled Inter. Fresh actual-app E2E: 17/17, external requests still forbidden.
- [x] Windows Docker/Supabase stderr detection: 20 fixture checks pass. Gate separates unconfigured unit/widget tests from three strict live-repository tests.
- [x] Final on-disk verification: analyzer clean; 620 Flutter passes / 10 skips; three live repository tests pass separately; 584 pgTAP assertions / 37 files pass; 68 browser widget results pass; 537 Dart files pass formatting. Local gate passes available steps with Deno explicitly skipped. Details and migration caveats are in `handoff.md` section 8.
- [ ] Deno, Android/iOS devices, actual printing/share and hosted-service/release sign-off remain unverified. Documented P2 limitations and deferred expansions remain out of this hardening batch.

## Backlog (post-launch, see product.md roadmap)
- Customer self-edit of own profile (PRD matrix deferred from v1)
- Thermal printing · price tiers · supplier purchases ledger · multi-warehouse · unit conversions · batch/expiry
- Payment gateways (eSewa/Khalti) · SMS reminders · subscriptions/feature gating · VAT mode
- Production crash reporting: code path shipped (`SENTRY_DSN`); set the GitHub secret before treating it as live
