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

## Phase 5 — Orders, Quotes & Chat (customer app)
- ✅ DB: `orders`, `order_items`, `quotes`, `quote_items`, `messages` + RLS
- ✅ Customer catalog (no prices), cart, place order with note
- ✅ Staff order queue; quote builder (rates, discounts) + send
- ✅ Customer quote view: accept/reject with comment; quote versioning on re-quote
- ✅ Order status pipeline: confirmed → packed → dispatched (warehouse actions; auto stock deduction on dispatch)
- ✅ Generate bill from dispatched order (prefilled from accepted quote)
- ✅ Order chat thread (text + image) via Supabase Realtime
- ✅ Customer "My Dues" + own bill history

## Phase 6 — Notifications
- ✅ FCM setup (Android/iOS/Web), token registration
- ✅ Edge Function `notify` + DB webhooks for order/quote/chat/low-stock/payment events
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
- ✅ Empty states, error states, skeleton loaders everywhere
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
- ✅ T-101 Password reset: forgot-password email flow (login screens) + `reset-member-password` Edge Function (owner resets any member from staff list / customer detail; sessions revoked; forced change on next login via `/change-password` router guard); pgTAP tests in `rls_phase12_launch_hardening_test.sql`
- ✅ T-102 Phone-number login: login accepts email or phone (`core/utils/login_identifier.dart` ↔ synthetic email in `create-member`); email now optional on member/customer creation; phone normalized to `+977…` and globally unique (`members_phone_unique_idx`)
- ✅ T-103 Account deletion (store compliance): `delete-account` Edge Function — customer/staff self-delete (anonymize, financial snapshots retained) + owner business purge (`purge_business` incl. storage cleanup, type-DELETE-to-confirm); account menu in customer shell, settings tiles for owner; privacy policy updated
- ✅ T-104 Reorder from past order: one-tap cart prefill from order detail, inactive products skipped with notice
- ✅ T-105 Shareable customer statement: 30/90-day/all-time ledger statement (BS+AD dates, opening/closing balance) as PDF/image via share sheet; totals invariant covered by `statement_document_test.dart`
- ✅ T-108 Registration hardening: min password length 8 (config + all validators); prod captcha/CORS/leaked-password steps documented in `docs/SECURITY.md` checklist (dashboard-side, do before launch)

## Backlog (post-launch, see product.md roadmap)
- Bill-level payment allocation (oldest-first auto-allocation; accurate aging) · quote expiry + stale-order nudges · dues reminders (push) · last-quoted-rate memory per customer
- Server-side report aggregation (Postgres RPCs) · client image compression before upload
- Thermal printing · price tiers · supplier purchases · multi-warehouse · unit conversions · batch/expiry
- Payment gateways (eSewa/Khalti) · SMS reminders · subscriptions/feature gating · VAT mode
