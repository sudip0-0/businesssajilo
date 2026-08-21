# BusinessSajilo — Task Breakdown

Phases are sequential; tasks within a phase can be parallelized. ✅ = done, ⬜ = todo.

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
- ✅ Role-aware routing: 4 role home shells with bottom nav (warehouse has no billing)
- ✅ Staff management screen (owner: list, add, deactivate members)
- ✅ RLS test suite (`supabase test db` — full suite in `supabase/tests/`: phases 1–8, 10–13, cross-tenant, storage)

## Phase 2 — Products & Inventory
- ✅ DB: `categories`, `products`, `stock_movements`, `notifications` + stock_cached trigger + RLS + storage bucket
- ✅ Product CRUD (owner) with image upload (Supabase Storage), EN/NP names
- ✅ Category management
- ✅ Stock-in entry, manual adjustment (reason required) — owner/warehouse
- ✅ Stock list with levels + low-stock badges; movement history per product
- ✅ Low-stock threshold alerts (DB trigger → notification records)

## Phase 3 — Customers & Ledger
- ✅ DB: `payments` + `customer_balances` / `customer_ledger_entries` views + extended RLS
- ✅ Customer CRUD (owner) incl. credential creation, opening balance
- ✅ Customer list with dues summary; customer detail with ledger statement
- ✅ Record payment flow (cash/cheque/wallet/bank ref), account-level allocation

## Phase 4 — Billing (online first)
- ✅ DB: `bills`, `bill_items`, `bill_sequences` + per-business BS-0001 numbering + RLS (warehouse blocked)
- ✅ Billing screen: product search, qty steppers, discounts, running total
- ✅ Payment sheet on save: Paid / Partial / Due → ledger entries
- ✅ Walk-in (no-customer) bills
- ✅ Bill list + bill detail (immutable snapshot view)

## Phase 5 — Orders & Quotes (customer app)
- ✅ DB: `orders`, `order_items`, `quotes`, `quote_items`, `messages` + RLS
- ✅ Customer catalog (no prices), cart, place order with note
- ✅ Staff order queue; quote builder (rates, discounts) + send
- ✅ Customer quote view: accept/reject with comment; quote versioning on re-quote
- ✅ Order status pipeline: confirmed → packed → dispatched (warehouse actions; auto stock deduction on dispatch)
- ✅ Generate bill from dispatched order (prefilled from accepted quote)
- ✅ Order chat thread shipped in Phase 5; **removed post-launch** (migration 43 drops `messages`, trigger, and `order-chat-images` bucket)
- ✅ Customer "My Dues" + own bill history

## Phase 6 — Notifications
- ✅ FCM setup (Android/iOS/Web), token registration
- ✅ Edge Function `notify` + DB webhooks for order/quote/low-stock/payment events
- ✅ In-app notification center with read states

## Phase 7 — Offline Sync (staff mobile)
- ✅ Drift schema mirroring core tables; repository swap (local-first on mobile staff)
- ✅ Sync queue: ordered push of bills/payments/stock movements with idempotent UUID upserts
- ✅ Delta pull sync (`updated_at` watermark) + initial bootstrap
- ✅ Provisional bill numbering (device prefix) + server-side final assignment
- ✅ Sync status UI (badge, pending-items screen, retry)
- ✅ Conflict handling: LWW for mutable rows + audit_log; offline e2e tests

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
- ✅ Repository integration order→bill reclassified; UI integration stub with `HARDENING_GATE` skip/fail semantics
- ✅ Deno unit tests for Edge Function `validation.ts`
- ✅ `scripts/local_hardening_gate.ps1` + `docs/LOCAL_TESTING.md`
- ✅ Repair compile errors in `dashboard_scoped_queries_test.dart` and `offline_query_scale_test.dart`
- ⚠️ Full UI pump through quote builder → bill form (stub only today)

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

## Backlog (post-launch, see product.md roadmap)
- Customer self-edit of own profile (PRD matrix deferred from v1)
- Thermal printing · price tiers · supplier purchases ledger · multi-warehouse · unit conversions · batch/expiry
- Payment gateways (eSewa/Khalti) · SMS reminders · subscriptions/feature gating · VAT mode
- Production crash reporting: code path shipped (`SENTRY_DSN`); set the GitHub secret before treating it as live
