# BusinessSajilo — Architecture

## 1. Stack Overview

| Layer | Technology |
|---|---|
| Client (Android/iOS/Web) | Flutter (single codebase), Riverpod state mgmt, go_router |
| Local DB / offline | Drift (SQLite) + custom sync queue (mobile staff app only) |
| Backend | Supabase: Postgres, Auth, Realtime, Storage, Edge Functions |
| Security | Postgres Row Level Security (RLS), role claims in JWT |
| Push | Firebase Cloud Messaging (FCM), triggered from Edge Functions / DB webhooks |
| PDF / share | Flutter `pdf` + `printing` + `share_plus` (invoice/statement PDF & image). Thermal/ESC/POS is backlog only. |

## 2. High-Level Diagram

```
 Flutter App (Android / iOS / Web; Windows runner for desktop-dev only)
 ├── Presentation (feature screens + role-aware routing; web UI in lib/web/)
 ├── Feature providers (Riverpod Notifier/AsyncNotifier — no separate application/ layer)
 ├── Domain (entities, enums, permission helpers)
 └── Data
     ├── Remote: supabase_flutter (PostgREST, Realtime, Storage, Auth)
     └── Local: Drift (SQLite) + SyncQueue  ← mobile staff only
                     │
                     ▼ background sync (push ops, pull deltas)
            ┌─────────────────────────┐
            │        Supabase         │
            │  Postgres + RLS         │
            │  Auth (JWT + role claim)│
            │  Realtime (notifications)│
            │  Storage (images)       │
            │  Edge Functions         │──► FCM push
            └─────────────────────────┘
```

There is **no** `lib/application/` use-case layer: feature providers and screens orchestrate repositories directly.

## 3. Multi-Tenancy & Security

- `businesses.id` is the tenant root. Tenant-owned tables carry `business_id`; migration 57 adds explicit NOT NULL scope to the six child tables, with parent-derived stamping, composite foreign keys, and restrictive tenant policies. RLS helpers (`current_business_id()`, `current_role_name()`) resolve active membership by querying `members` for `auth.uid()`, not JWT role claims.
- User role lives on the `members` row (`owner | sales | warehouse | customer`). Auth JWT `app_metadata` is synced for convenience, but policies use the SQL helpers above.
- Example hard rules at DB level:
  - `bills`: staff (`owner`, `sales`, `warehouse`) can SELECT and create through `create_bill`; customers can SELECT only their own bills. Direct client inserts are denied by RLS. Warehouse cannot record payments.
  - `stock_movements`: INSERT only for role IN ('owner','warehouse').
  - `customers`: INSERT only owner.
- Client UI also gates by role, but RLS is the source of truth.
- Owner creates staff/customer accounts via an Edge Function (`create-member`) using the service role key (never shipped to clients).

## 4. Data Model (core tables)

```
businesses(id, name, name_np, address, phone, logo_url, subscription_plan, created_at)
members(id, business_id, auth_user_id, role, display_name, phone, is_active)
customers(id, business_id, member_id not null unique, shop_name, contact_name, phone, address, opening_balance)
products(id, business_id, name, name_np, sku, unit, cost_price,
         reference_price, image_url, low_stock_threshold, stock_cached, is_active)
stock_movements(id, business_id, product_id, type[stock_in|adjust|dispatch|return], qty_delta,
                reason, ref_bill_id?, created_by, created_at)        -- append-only
orders(id, business_id, customer_id, status[placed|received|billed], customer_note, created_at, updated_at)
order_items(id, business_id, order_id, product_id, qty, product_name)
quotes(id, business_id, order_id, version, status[sent|accepted|rejected|superseded],
       total, expires_at, response_comment, created_by, created_at)
quote_items(id, business_id, quote_id, product_id, product_name, qty, rate, discount, line_total)
bills(id, business_id, customer_id?, order_id?, bill_no, device_prefix, items_total,
      discount, grand_total, status[paid|partial|due], guest_name, reference_note, created_by, created_at)
bill_items(id, business_id, bill_id, product_id?, name_snapshot, qty, rate, discount, line_total)
payments(id, business_id, customer_id, bill_id?, amount, method[cash|cheque|wallet|bank],
         ref_note, received_by, created_at)
credit_notes(id, business_id, bill_id, customer_id, credit_no, grand_total, created_at)
credit_note_items(id, business_id, credit_note_id, bill_item_id, product_id?, name_snapshot, qty_returned, rate, discount, line_total)
customer_ledger_entries(view: opening/bills debit; payments/credit notes credit; running balance computed by client)
customer_directory(view: role/tenant-filtered identity fields only; no financial columns)
device_tokens(id, business_id, member_id, token, platform)
notifications(id, business_id, recipient_member_id, type, payload, read_at, created_at)
```

Notes:
- **Stock level = SUM(stock_movements.qty_delta)** per product (materialized via trigger into `products.stock_cached` for fast reads). Append-only movements make offline merging conflict-free.
- `bill_no` is per-business sequential; offline bills get `device_prefix` (e.g. `D2-`) and a final number assigned on sync to guarantee uniqueness.
- Bill items snapshot product name/rate so historical bills are immutable.
- Migration 59 snapshots quote-item product names on insert so customers do not need raw-product access. Accepted-quote billing and quote mapping prefer that snapshot over a renamed product. Existing quotes were backfilled from current product names; earlier names cannot be reconstructed.
- Direct authenticated order updates cannot set `billed`, and staff cannot directly insert/update accepted or rejected quote responses. Security-invoker guards distinguish client SQL from the existing trusted RPC execution context; no client-set bypass flag is used.

## 5. Offline Sync (staff mobile)

- **Local writes first**: bills, payments, stock movements written to Drift with `pending` flag and client-generated UUIDs.
- **Push**: ordered, dependency-aware replay uses `create_bill` / `record_customer_sale` / `record_payment` RPCs and insert-if-absent stock movement upserts. RPC acknowledgements are validated before local success; retries use exponential backoff and bounded network awaits.
- **Pull**: entity-specific server watermarks (`updated_at` or `created_at`), resumable bootstrap, and session-cancellation checks. Warehouse reads customer identities and does not pull payments.
- **Conflicts**: product/customer writes are online-only; the unused product LWW RPC was removed in migration 20. Append-only writes remain subject to permissions, referential validation, and retry identity checks; append-only does not mean validation cannot fail.
- **Cache ownership**: staff caches are scoped by business, member, and role. Recovery only imports verifiably owned and permitted pending work; unknown or forbidden legacy work is retained with localized recovery guidance. Source preservation is not permission to replay another member's transactions.
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
| Credit notes / quotes | N | N | N (intentionally online-only) |

**Intentionally online-only:** credit notes, quotes, orders, and reports (no Drift queue / cache). Owner dashboard KPIs use the `owner_dashboard_stats` RPC via `ownerDashboardStatsProvider`; if that call fails on staff mobile (offline / RPC unavailable), the provider falls back to existing local-capable methods (`todaysSales` / `yesterdaysSales` / `totalDues` / `lowStockCount`) plus online `pendingCount` when reachable — section lists (`todaysBillsProvider`, `lowStockAlertsProvider`, `recentCustomersProvider`, `salesDailyProvider`) stay separate loads.

## 6. Realtime

Supabase Realtime client streams are used for the
**notification feed** only (filtered by recipient). Order status
and quote changes are pull/refresh based. Falls back to pull-to-refresh when
offline.

## 7. Push Notifications

DB webhooks/triggers → Edge Function `notify` → FCM. Tokens stored per member/device in `device_tokens`. Notification fan-out rules derived from role + event type (see product.md §8).

The web FCM service worker is implemented in `web/firebase-messaging-sw.js`, but its Firebase configuration must be supplied separately. Mobile Firebase dart-defines, web configuration/VAPID, server FCM credentials, and actual delivery all require operational verification. In-app notifications work independently of push delivery.

## 8. Flutter Project Structure

```
lib/
 ├── core/            # theme, l10n (EN/NP), BS date utils, formatters, invoicing, export
 ├── data/
 │   ├── local/       # drift db, daos, sync queue
 │   ├── remote/      # supabase data sources
 │   ├── repositories/
 │   └── sync/        # sync_service, sync_puller, sync_pusher, cached/syncing wrappers
 ├── domain/          # entities, enums (Role, OrderStatus), permission helpers
 ├── features/        # mobile/native feature screens + Riverpod providers
 ├── web/             # parallel web admin UI (router, shell, feature screens)
 └── app.dart, main.dart
```

- Role-aware shell: after login, `go_router` redirects to role-specific home (owner dashboard, sales home, warehouse home, customer catalog).
- Same codebase, conditional features by role + platform (e.g. sync layer only on mobile staff builds via repository injection).
- Shared adaptive sheets live in `lib/core/ui/adaptive_sheet.dart` (uses `core/ui/web_side_panel.dart`). Feature modules under `lib/features/` must not import `lib/web/` (web UI stays in `lib/web/`).
- Windows desktop runner exists for local/integration testing only — not a shipped product platform.

## 9. Environments & CI/CD

- Local Supabase is managed through the CLI; hosted dev/prod projects and their configuration require separate operational verification. Migrations live in `supabase/migrations`.
- Build-time environment values, including the flavor label and public API configuration, are passed through `--dart-define`; this is not a claim that native platform flavors or production services are configured.
- CI (GitHub Actions `ci.yml`): `dart format`, generated-source cleanliness after `gen-l10n`/`build_runner`, `flutter analyze`, `flutter test`, `supabase test db`, build-based browser widget harness, local-resource actual-app E2E; web build artifact on `main` without the removed `--web-renderer` flag.
- Release (`release.yml` on `v*` tags): quality job includes the same generated-source, browser-widget, and actual-app E2E checks, then Android AAB + local-resource web build with prod dart-defines; optional Vercel deploy when secrets are set. iOS IPA is not in CI yet (manual / future Codemagic or macOS runner).
- **Local hardening gate:** `scripts/local_hardening_gate.ps1` checks the unit/widget suite without backend dart-defines, then runs the three live repository tests in a separate configured pass. It also runs local migrations, pgTAP, and Deno tests when available. Windows native stderr warnings do not imply service failure; missing prerequisites remain explicit skips/failures. See `docs/LOCAL_TESTING.md`.

### Verification layers

- **Dart:** unit/widget tests, mocked HTTP repository contracts, auth lifecycle, exact money/export math, and sync/recovery tests. Dated execution results and unresolved checks are recorded in `tasks.md` and `handoff.md`; test presence is not a pass.
- **Postgres:** pgTAP suites in `supabase/tests/`, including warehouse privacy, atomic order/quote responses, allocation, and child-table tenancy.
- **Edge Functions:** Deno tests for shared validation and notification push policy. Missing Deno is a blocked/skipped check, not success.
- **UI flow:** `test/integration/ui_order_to_bill_flow_test.dart` pumps real cart/quote/acceptance/billing screens against deterministic test repositories. It is no longer bootstrap-only, but is not a live multi-device test.
- **Live backend:** repository integration tests separately exercise local order/quote/bill, warehouse privacy, and concurrent payment allocation through real Supabase requests. They require local fixtures/configuration and reject non-local targets where they create data.
- **Browser:** the supported build-based widget harness is `test/support/web_search_test_bootstrap.dart` + `scripts/run_web_search_tests.mjs`; actual-app navigation/locale checks are in `scripts/e2e_web.mjs`. Direct `flutter test --platform chrome` encountered missing CanvasKit assets on this machine, so do not confuse that runner with the verified build-based harness.

## 10. Key Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Offline bill number collisions | Device-prefixed provisional numbers, server assigns final sequence |
| RLS policy mistakes leaking tenant data | Policy unit tests (pgTAP in `supabase/tests/`) + integration tests per role |
| Flutter web perf for big tables | Paginated queries, CanvasKit renderer, virtualized lists |
| Sync data loss | Append-only design, queue persisted in SQLite, idempotent upserts (client UUID PKs) |
| Nepali font/date correctness | `nepali_utils` for BS dates; Inter + Noto Sans Devanagari bundled under `assets/fonts/` |
