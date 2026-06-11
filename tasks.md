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
- ✅ RLS test suite (`supabase test db` — 8 tests in `supabase/tests/rls_phase1_test.sql`)

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
- ⬜ Drift schema mirroring core tables; repository swap (local-first on mobile staff)
- ⬜ Sync queue: ordered push of bills/payments/stock movements with idempotent UUID upserts
- ⬜ Delta pull sync (`updated_at` watermark) + initial bootstrap
- ⬜ Provisional bill numbering (device prefix) + server-side final assignment
- ⬜ Sync status UI (badge, pending-items screen, retry)
- ⬜ Conflict handling: LWW for mutable rows + audit_log; offline e2e tests

## Phase 8 — Reports & Dashboard
- ⬜ Owner dashboard: today's sales, dues total, low stock, pending orders
- ⬜ Sales summary report (daily/weekly/monthly, top products/customers)
- ⬜ Dues aging report (0–30/31–60/60+)
- ⬜ Stock valuation report
- ⬜ Web responsive layouts (nav rail, two-pane, data tables)

## Phase 9 — Polish & Release
- ⬜ Nepali translation pass on all strings; BS date verification
- ⬜ Empty states, error states, skeleton loaders everywhere
- ⬜ Performance pass (web CanvasKit, list virtualization, image caching)
- ⬜ Security review: RLS audit, rate limits, storage rules
- ⬜ Play Store + App Store listings, web deploy to prod
- ⬜ Onboarding tour + seed/demo data for new businesses

## Backlog (post-v1, see product.md roadmap)
- PDF invoices + thermal printing · sales returns · Excel export
- Price tiers · supplier purchases · multi-warehouse · unit conversions · batch/expiry
- Payment gateways (eSewa/Khalti) · SMS reminders · subscriptions/feature gating · VAT mode
