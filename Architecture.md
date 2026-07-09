# BusinessSajilo — Architecture

## 1. Stack Overview

| Layer | Technology |
|---|---|
| Client (Android/iOS/Web) | Flutter (single codebase), Riverpod state mgmt, go_router |
| Local DB / offline | Drift (SQLite) + custom sync queue (mobile staff app only) |
| Backend | Supabase: Postgres, Auth, Realtime, Storage, Edge Functions |
| Security | Postgres Row Level Security (RLS), role claims in JWT |
| Push | Firebase Cloud Messaging (FCM), triggered from Edge Functions / DB webhooks |
| PDF / printing (v1.1) | Flutter `pdf` package, ESC/POS for thermal |

## 2. High-Level Diagram

```
 Flutter App (Android / iOS / Web)
 ├── Presentation (screens, role-aware routing)
 ├── Application (Riverpod controllers / use-cases)
 ├── Domain (entities, role/permission logic)
 └── Data
     ├── Remote: supabase_flutter (PostgREST, Realtime, Storage, Auth)
     └── Local: Drift (SQLite) + SyncQueue  ← mobile staff only
                     │
                     ▼ background sync (push ops, pull deltas)
            ┌─────────────────────────┐
            │        Supabase         │
            │  Postgres + RLS         │
            │  Auth (JWT + role claim)│
            │  Realtime (chat/orders) │
            │  Storage (images)       │
            │  Edge Functions         │──► FCM push
            └─────────────────────────┘
```

## 3. Multi-Tenancy & Security

- Every business table carries `business_id`. RLS policies enforce `business_id = auth.jwt() ->> 'business_id'`.
- User role stored in `app_metadata` (`owner | sales | warehouse | customer`) and mirrored in a `members` table; RLS policies check role per operation.
- Example hard rules at DB level:
  - `bills`: SELECT/INSERT only for role IN ('owner','sales'); customers can SELECT only their own bills.
  - `stock_movements`: INSERT only for role IN ('owner','warehouse').
  - `customers`: INSERT only owner.
- Client UI also gates by role, but RLS is the source of truth.
- Owner creates staff/customer accounts via an Edge Function (`create-member`) using the service role key (never shipped to clients).

## 4. Data Model (core tables)

```
businesses(id, name, name_np, address, phone, logo_url, subscription_plan, created_at)
members(id, business_id, auth_user_id, role, display_name, phone, is_active)
customers(id, business_id, member_id?, shop_name, contact_name, phone, address, opening_balance)
categories(id, business_id, name, name_np)
products(id, business_id, category_id, name, name_np, sku, unit, cost_price,
         reference_price, image_url, low_stock_threshold, is_active)
stock_movements(id, business_id, product_id, type[in|adjust|dispatch], qty_delta,
                reason, ref_order_id?, created_by, created_at)        -- append-only
orders(id, business_id, customer_id, status, customer_note, created_at, updated_at)
order_items(id, order_id, product_id, qty)
quotes(id, order_id, version, status[sent|accepted|rejected], total, created_by, created_at)
quote_items(id, quote_id, product_id, qty, rate, discount)
bills(id, business_id, customer_id?, order_id?, bill_no, device_prefix, items_total,
      discount, grand_total, status[paid|partial|due], created_by, created_at)
bill_items(id, bill_id, product_id, name_snapshot, qty, rate, discount, line_total)
payments(id, business_id, customer_id, bill_id?, amount, method[cash|cheque|wallet|bank],
         ref_note, received_by, created_at)
ledger_entries(view/derived: bills as debit, payments as credit, running balance)
messages(id, order_id, business_id, sender_member_id, body, image_url?, created_at)
notifications(id, business_id, recipient_member_id, type, payload, read_at, created_at)
```

Notes:
- **Stock level = SUM(stock_movements.qty_delta)** per product (materialized via trigger into `products.stock_cached` for fast reads). Append-only movements make offline merging conflict-free.
- `bill_no` is per-business sequential; offline bills get `device_prefix` (e.g. `D2-`) and a final number assigned on sync to guarantee uniqueness.
- Bill items snapshot product name/rate so historical bills are immutable.

## 5. Offline Sync (staff mobile)

- **Local writes first**: bills, payments, stock movements written to Drift with `pending` flag and client-generated UUIDs.
- **Push**: background worker drains the sync queue (ordered) to Supabase via PostgREST upserts; retries with exponential backoff.
- **Pull**: delta sync using `updated_at > last_sync` per table.
- **Conflicts**: append-only tables (movements, payments, messages) never conflict; mutable rows (product edits) use last-write-wins + `audit_log`.
- Customer app and web skip the sync layer entirely (direct online repo implementations behind the same repository interfaces).

### Offline matrix

`syncEnabledFor(role)` (`lib/data/sync/sync_config.dart`) is true only for staff roles on non-web builds (not customer, not web). When a sync bundle is active, providers inject `Syncing*` / `Cached*` repos; otherwise they use direct Supabase implementations behind the same abstracts.

| Repository | Web | Customer mobile | Staff mobile (sync) |
| --- | --- | --- | --- |
| BillsRepository | N (Supabase) | N | Y (`SyncingBillsRepository`) |
| PaymentsRepository | N (Supabase) | N | Y (`SyncingPaymentsRepository`) |
| StockRepository | N (Supabase) | N | Y (`SyncingStockRepository`) |
| ProductsRepository | N (Supabase) | N | Y (`CachedProductsRepository`) |
| CustomersRepository | N (Supabase) | N | Y (`CachedCustomersRepository`) |
| OrdersRepository | N | N | N (online-only) |
| ReportsRepository | N | N | N (online-only) |
| Credit notes / quotes / chat | N | N | N (intentionally online-only) |

**Intentionally online-only:** credit notes, quotes, chat, orders, and reports (no Drift queue / cache). Owner dashboard KPIs use the `owner_dashboard_stats` RPC via `ownerDashboardStatsProvider`; if that call fails on staff mobile (offline / RPC unavailable), the provider falls back to existing local-capable methods (`todaysSales` / `yesterdaysSales` / `totalDues` / `lowStockCount`) plus online `pendingCount` when reachable — section lists (`todaysBillsProvider`, `lowStockAlertsProvider`, `recentCustomersProvider`, `salesDailyProvider`) stay separate loads.

## 6. Realtime

Supabase Realtime channels (filtered by `business_id` / `order_id`) for: order status changes, new quotes, chat messages, notification feed. Falls back to pull-to-refresh when offline.

## 7. Push Notifications

DB webhooks/triggers → Edge Function `notify` → FCM. Tokens stored per member/device in `device_tokens`. Notification fan-out rules derived from role + event type (see product.md §8).

## 8. Flutter Project Structure

```
lib/
 ├── core/            # theme, l10n (EN/NP), BS date utils, formatters, error handling
 ├── data/
 │   ├── local/       # drift db, daos, sync queue
 │   ├── remote/      # supabase data sources
 │   └── repositories/
 ├── domain/          # entities, enums (Role, OrderStatus), permission policy
 ├── features/
 │   ├── auth/  onboarding/  dashboard/
 │   ├── products/  inventory/
 │   ├── orders/  quotes/  chat/
 │   ├── billing/  payments/  ledger/
 │   ├── customers/  staff/
 │   └── reports/  notifications/  settings/
 └── app.dart, main.dart
```

- Role-aware shell: after login, `go_router` redirects to role-specific home (owner dashboard, sales home, warehouse home, customer catalog).
- Same codebase, conditional features by role + platform (e.g. sync layer only on mobile staff builds via repository injection).
- Shared adaptive sheets live in `lib/core/ui/adaptive_sheet.dart`. Feature modules under `lib/features/` must not import `lib/web/` (web UI stays in `lib/web/`).

## 9. Environments & CI/CD

- Supabase projects: `dev` and `prod`. Migrations in repo (`supabase/migrations`), applied via Supabase CLI.
- Flutter flavors: `dev`, `prod` (API URLs/keys via `--dart-define`).
- CI (GitHub Actions): analyze + test on PR; build Android AAB, iOS IPA (Codemagic or macOS runner), and deploy web to Firebase Hosting/Vercel on tag.

## 10. Key Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Offline bill number collisions | Device-prefixed provisional numbers, server assigns final sequence |
| RLS policy mistakes leaking tenant data | Policy unit tests (pgTAP) + integration tests per role |
| Flutter web perf for big tables | Paginated queries, CanvasKit renderer, virtualized lists |
| Sync data loss | Append-only design, queue persisted in SQLite, idempotent upserts (client UUID PKs) |
| Nepali font/date correctness | `nepali_utils` package for BS dates, Noto Sans Devanagari bundled |
