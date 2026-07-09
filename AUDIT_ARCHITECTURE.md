# AUDIT_ARCHITECTURE — BusinessSajilo

**Date:** 2026-07-09  
**Companion:** [AUDIT_INVENTORY.md](AUDIT_INVENTORY.md)  
**Scope:** Architecture, design, security, and performance review. No code changes in this document.

---

## 1. Dimension ratings

| # | Dimension | Rating | Summary |
|---|-----------|--------|---------|
| 1 | Separation of concerns | **Needs Work** | Clean `data/` / `domain/` / `features/` folders; screens own validation + orchestration; no use-case layer |
| 2 | Single Responsibility / SOLID | **Needs Work** | `SyncService` god object; large bill/dashboard screens with tangled form + save logic |
| 3 | Coupling & cohesion | **Needs Work** | Sync-enabled repos well abstracted; Orders/Reports concrete-only; `features/` ↔ `web/` cross-imports |
| 4 | Scalability (10x) | **Critical** | Unbounded sync bootstrap; offline N+1; fake pagination (load-all then slice) |
| 5 | Consistency | **Needs Work** | Naming mostly uniform; error handling and repo patterns diverge; heavy web/mobile duplication |
| 6 | State management | **Good** | Riverpod 3 used consistently across auth, lists, streams |
| 7 | Data modeling | **Good** | Postgres schema + indexes + RLS; Drift mirror; paisa integers; report views/RPCs |
| 8 | API design | **Good** | PostgREST + RPC + Edge Functions; structured `{ error }` responses; transactional `create_bill` |
| 9 | Security posture | **Good*** | RLS + pgTAP + tenant cache wipe; Edge CORS defaults `*`; prod checklist incomplete |

\*Good design; deployment defaults need hardening.

---

## 2. Dimension evidence

### 2.1 Separation of concerns — Needs Work

**Good:** Layered folders match documented intent (`Architecture.md`):

```
lib/core/     → theme, l10n, utils, shared UI
lib/data/     → local (Drift), remote (Supabase), repositories, sync
lib/domain/   → Freezed models, enums
lib/features/ → screens + feature providers
lib/web/      → web-specific layouts/pages
```

**Gaps:**

- `Architecture.md` describes an "Application (Riverpod controllers / use-cases)" layer — not present under `lib/`.
- Screens call repositories directly and own form state, validation, and cache invalidation (e.g. bill forms invalidate multiple providers after save).
- Bill validation (discount bounds, line totals) lives in UI despite `lib/core/utils/bill_totals.dart`.
- Role gating passed as widget flags (`canEdit`, `canRecordPayments`) from shells, not a centralized policy service.

### 2.2 SOLID / God objects — Needs Work

| File | ~LOC | Concern |
|------|------|---------|
| `lib/data/sync/sync_service.dart` | ~582 | Connectivity, bootstrap, delta pull, push queue, per-entity upserts |
| `lib/web/features/billing/web_bill_form_content.dart` | ~771 | Form + search + save + layout |
| `lib/features/billing/bill_form_screen.dart` | ~617 | Same as web twin |
| `lib/web/features/dashboard/web_owner_dashboard_page.dart` | ~613 | Dashboard + charts + actions |
| `lib/web/router/web_router.dart` | ~414 | All web routes in one file |

`SyncService` owns the full sync engine end-to-end — hard to unit-test entity adapters in isolation.

### 2.3 Coupling & cohesion — Needs Work

**Good cohesion:** Sync-enabled repos under `data/sync/`; shared utils (`bill_totals.dart`, `ledger_balance.dart`).

**Coupling issues:**

- Abstract + dual impl for bills/products/customers/payments/stock; concrete-only for orders, reports, quotes, messages, members.
- 15+ mobile screens import `lib/web/ui/web_sheet_bridge.dart` (platform layer leak).
- Web pages import `features/` providers and sometimes mobile widgets (e.g. payment sheet).
- `MembersRepository` invoked inside customer create paths (credential provisioning mixed with CRM).

### 2.4 Scalability at 10x — Critical

Will break first on **mobile offline sync and list screens**, then **dashboard / orders** on web.

Evidence:

- `SyncService._bootstrap()` — unbounded `.select()` for categories, products, customers, bills (+ nested items), payments, stock movements (`lib/data/sync/sync_service.dart` ~98–148).
- Row-at-a-time Drift upserts in loops (`~103–147`).
- `SyncingBillsRepository.list()` loads all local bills, sorts in memory, N+1-fetches items (`lib/data/sync/syncing_bills_repository.dart` ~37–48).
- `CachedProductsRepository.list()` / `CachedCustomersRepository.list()` — full table `get()`, then `skip`/`take` in Dart (`cached_products_repository.dart` ~27–35).
- `billListProvider` / `productListProvider` / `customerListProvider` call `.list()` with no limit.
- Orders: nested select with no `.range()` (`orders_repository.dart` ~37–49).

Postgres side is better prepared (composite indexes in phase-10 hardening migration).

### 2.5 Consistency — Needs Work

| Area | Observation |
|------|-------------|
| Naming | `*_screen.dart` (mobile), `web_*_page.dart` (web) — predictable |
| Folders | `features/X` mirrors `web/features/X` |
| Repos | Mixed abstract vs concrete |
| Pagination | UI uses `PaginatedListState` (page size 50); offline repos ignore DB-level offset |
| Errors | Auth has `localizeAuthError()`; data layer throws generic `Exception`; UI mixes `ErrorState`, `AsyncValue.when`, SnackBars |
| Sync errors | Queue stores `lastError: 'sync_error'` string, not the real message |

### 2.6 State management — Good

- Framework: `flutter_riverpod: ^3.3.2`.
- Patterns: `NotifierProvider` (auth/locale/theme), `FutureProvider.autoDispose` (lists), `StreamProvider` (sync queue, chat, notifications).
- Concern: providers often fetch unbounded lists — scales poorly even with good Riverpod usage.
- Medium smell: module-level `SyncBundle? _activeBundle` in `sync_providers.dart` (circular-dep workaround).

### 2.7 Data modeling — Good

- Backend: Supabase Postgres; phased migrations; indexes on `(business_id, created_at)`, `(business_id, updated_at)`, etc.
- Offline: Drift mirrors entity families + sync metadata; money as integer paisa; append-only stock movements.
- Reports via views/RPCs; ledger via `customer_ledger_entries` view.
- Gap: local Drift tables lack secondary indexes for search/sort at scale (mostly PKs).

### 2.8 API design — Good

- Not classic REST — PostgREST + RPC + Edge Functions (appropriate for Supabase).
- Edge Functions: CORS preflight, JWT auth, `{ error: string }` + HTTP status.
- Transactional writes via RPC (`create_bill` idempotent push).
- Server-side validation in Edge Functions; client duplicates for UX; RLS is final authz gate.
- No API versioning layer (acceptable while single client ships with backend).

### 2.9 Security — Good (prod gaps)

**Strengths:**

- FORCE RLS on tenant tables; role-based policies; pgTAP suite under `supabase/tests/`.
- Service role only in Edge Functions; client gets anon key via dart-defines (`Env`).
- Tenant cache wipe on business switch (`app_database.prepareForBusiness`); covered by `tenant_cache_isolation_test.dart`.
- Forced password change / session revoke documented in `docs/SECURITY.md`.

**Gaps:**

- Edge Functions default `ALLOWED_ORIGIN` to `"*"` (`create-member`, `register-business`, `reset-member-password`, `delete-account`).
- `notify/index.ts` hardcodes `"Access-Control-Allow-Origin": "*"`.
- Production checklist items in `docs/SECURITY.md` unchecked (captcha, key rotation, SMTP).

---

## 3. Findings ranked by severity

| Rank | Finding | Severity | Effort | Evidence |
|------|---------|----------|--------|----------|
| 1 | Offline sync & list queries do not scale | Critical | L | `sync_service.dart` ~98–148; `syncing_bills_repository.dart` ~37–48; cached repos |
| 2 | Large duplicated web vs mobile UIs | Critical | L | Bill form ~617 vs ~771 LOC; dashboards; customer/product lists |
| 3 | `SyncService` is a god object | High | M | `sync_service.dart` ~582 LOC |
| 4 | Business logic in presentation | High | M | Bill validation duplicated in mobile/web forms; no use-case layer |
| 5 | Incomplete offline coverage | High | M | Orders/quotes/chat always online (`orders_repository.dart` concrete) |
| 6 | Global mutable sync DI | Medium | S | `_activeBundle` in `sync_providers.dart` |
| 7 | Error handling inconsistency | Medium | S–M | Auth structured; sync/data generic; UI mixed |
| 8 | Edge CORS defaults to `*` | Medium | S | `supabase/functions/*/index.ts` |
| 9 | Cross-layer `web_sheet_bridge` imports | Medium | M | Mobile features → `lib/web/ui/` |
| 10 | CI codegen `continue-on-error`; no format gate | Low | S | `.github/workflows/ci.yml` ~19–20 |

---

## 4. Performance Findings

### Critical

#### P-C1 — Sync bootstrap: row-by-row Drift writes

**File:** `lib/data/sync/sync_service.dart` (~103–147)

`_bootstrap()` / `_pullDelta()` fetch from Supabase, then `await` per-row `_upsert*`. Each upsert is read-then-write. Bill items add an inner loop.

| Metric | Before (est.) | After batch/transaction |
|--------|---------------|-------------------------|
| 1,000 products first sync | ~2,000 Drift round-trips, 10–60s | 1–2 batch upserts, ~1–5s |
| 500 bills × 5 items | ~2,500+ sequential inserts | Single transaction + batch |

#### P-C2 — Offline bills list: N+1 on items

**File:** `lib/data/sync/syncing_bills_repository.dart` (~37–48)

```dart
final bills = await _db.select(_db.localBills).get();
// ... sort, slice ...
for (final bill in sliced) {
  final items = await (_db.select(_db.localBillItems)
        ..where((i) => i.billId.equals(bill.id)))
      .get();
}
```

`listTodaysBills()` / `search()` call `list()` with no limit first.

| Page size | Before | After (JOIN / batch IN) |
|-----------|--------|-------------------------|
| 50 bills | 51 queries | 1–2 queries |
| Latency | ~200–800ms | ~20–80ms |

#### P-C3 — Dashboard loads full catalogs for a few activity rows

**Files:** `lib/features/reports/owner_dashboard.dart` (~64–65); `lib/web/features/dashboard/web_owner_dashboard_page.dart`

Watches `productListProvider` and `customerListProvider` (unbounded), then `.take(2–3)` for recent activity.

| Business size | Before | After (targeted queries) |
|---------------|--------|--------------------------|
| 300 products, 150 customers | 2 full fetches | low-stock count + recent customers |
| Extra TTI | +300ms–2s | +50–150ms |

### High

#### P-H1 — Cached repos: fake pagination

**Files:** `cached_products_repository.dart` (~27–35), `cached_customers_repository.dart`

Full table `get()` → sort in Dart → `skip`/`take`. `lowStockCount()` calls `list()` with no limit (~39–46).

#### P-H2 — Dashboard: 8+ parallel queries per paint

Watches today's/yesterday sales, chart range, dues, low stock, pending orders, today's bills, plus full product/customer lists. `salesTrendProvider` chains two sales queries.

| Before | After (dashboard RPC) |
|--------|----------------------|
| 8–10 HTTP round-trips | 1–2 |
| Cold dashboard | ~800ms–3s | ~200–600ms |

#### P-H3 — Orders: unbounded nested selects

**File:** `lib/data/repositories/orders_repository.dart` (~37–49)

No `.limit()` / `.range()`. Nested `order_items(*, products(...))`. Used by staff list, own list, fulfillment queue.

| 200 orders × 8 items | Before | After pagination |
|----------------------|--------|------------------|
| Payload | ~500KB–2MB | ~50–150KB per page |

`pendingCount()` correctly uses `.count()` — good pattern to extend.

#### P-H4 — Local bill/stock create not transactional

**Files:** `syncing_bills_repository.dart` (create path); `syncing_stock_repository.dart`

Separate awaits for header, lines, payment, queue — unlike `SyncingPaymentsRepository.record()` which uses `_db.transaction()`.

**Risk:** App kill mid-create → partial local state + sync retry storms.

#### P-H5 — `syncNow()` silently drops overlapping calls

**File:** `lib/data/sync/sync_service.dart` (~71–72)

```dart
if (_syncing) return;
```

Triggered from connectivity, post-write `unawaited(syncNow())`, and manual retry. Burst offline edits can leave queue undrained until next connectivity event.

### Medium

#### P-M1 — Flutter web cold start

Eager `web_router.dart` imports 30+ pages; no `deferred as`. `main.dart` initializes Push + Supabase before `runApp`. Heavy deps: firebase, pdf, printing, drift, google_fonts.

#### P-M2 — Google Fonts runtime fetch

`lib/web/theme/web_typography.dart` — `GoogleFonts.inter(...)` at theme build → network font + possible layout shift.

#### P-M3 — PDF raster on UI isolate

`lib/core/invoicing/invoice_image_builder.dart` — `Printing.raster(..., dpi: 180)` on main isolate → 200–800ms jank per share.

#### P-M4 — Reports unbounded

`reports_repository.dart` — `duesAging()`, `stockValuation()` full selects; web reports hub watches both at once.

#### P-M5 — Client-side search on paginated pages

Customer/product list screens filter only loaded pages — incomplete search for 500+ records until many "Load more" taps. Online bill search correctly uses server `ilike`.

### Positive notes

- Push/auth subscriptions cancelled on dispose.
- Messages stream capped at 200; signed-URL cache scoped.
- Online bills/products/customers use server `range()` where implemented.
- Per-table sync watermarks prevent data loss on partial pull.
- Idempotent `create_bill` RPC on push.

---

## 5. Prioritized fix backlog (Phase 4)

**STOP — await approval before Phase 5 implementation.**

### Quick wins (low effort, high impact)

| # | Issue | Severity | Effort | Risk if unfixed | Proposed fix |
|---|-------|----------|--------|-----------------|--------------|
| Q1 | Dashboard over-fetches full catalogs | High | S | Slow dashboard as data grows | Dedicated providers: recent customers + low-stock sample/count; stop watching unbounded list providers on dashboard |
| Q2 | Offline bill/stock writes not transactional | High | S | Partial local rows on crash | Wrap create paths in Drift `_db.transaction()` (mirror payments) |
| Q3 | `syncNow()` drops overlapping calls | Med | S | Delayed queue drain | Pending-flag / coalesce: run again once after current sync finishes |
| Q4 | Sync queue error detail discarded | Med | S | Ops can't diagnose failures | Persist real error message (truncated) on queue row |
| Q5 | Edge Function CORS `*` | Med | S | CSRF/abuse surface in prod | Require `ALLOWED_ORIGIN` env; fail closed in prod |
| Q6 | CI: `build_runner` continue-on-error; no format | Low | S | Broken codegen ships | Fail CI on codegen; add `dart format --set-exit-if-changed` |

### Structural fixes (refactor, high long-term value)

| # | Issue | Severity | Effort | Risk if unfixed | Proposed fix |
|---|-------|----------|--------|-----------------|--------------|
| S1 | Sync bootstrap row-at-a-time + unbounded pulls | Critical | L | Mobile unusable at 10x data | Batch Drift upserts; paginate Supabase pulls; keep per-table watermarks |
| S2 | Offline bill N+1 + fake pagination | Critical | M | List jank / OOM | SQL LIMIT/OFFSET + batch-load items by `billId IN (...)`; fix `search`/`listTodaysBills` |
| S3 | Cached products/customers load-all | Critical | M | Same as S2 for inventory/CRM | Drift queries with limit/offset/order; SQL low-stock count |
| S4 | Duplicate web/mobile bill form logic | Critical | L | Divergent billing bugs | Extract shared `BillDraft`/`BillFormController` + validation; platforms own layout only |
| S5 | Split `SyncService` | High | M | Untestable sync growth | `SyncPuller` / `SyncPusher` + per-entity adapters |
| S6 | Orders unbounded nested list | High | M | Web/staff order screens stall | `.range()` pagination + lighter select; extend to fulfillment queue |
| S7 | Thin use-case layer for billing | High | M | Rules stay in widgets | Controllers calling repos; unit-test without widgets |
| S8 | Move `web_sheet_bridge` to `core/ui` | Med | M | Platform layer coupling | Shared adaptive sheet API |

### Nice-to-haves

| # | Issue | Severity | Effort | Risk if unfixed | Proposed fix |
|---|-------|----------|--------|-----------------|--------------|
| N1 | Deferred web routes + bundle Inter | Low | M | Slower web cold start | `deferred as` route modules; font assets |
| N2 | PDF raster off main isolate | Low | S | Export jank | `compute()` / isolate |
| N3 | Abstract remaining repos; document offline matrix | Low | M | Uneven testability | Interfaces + Architecture.md offline scope table |
| N4 | Single dashboard stats RPC | Low | M | Many round-trips | One Postgres view/RPC for owner home KPIs |
| N5 | `dart pub outdated` + advisory pass | Low | S | Unknown CVEs | Document results; bump if needed |

**Default recommendation:** Quick wins **Q1–Q6**, then structural **S1–S3** (offline scale). Defer **S4/S5** until after scale fixes unless billing parity bugs are active.

### Phase 5 constraints (when approved)

- Preserve existing functionality — no silent behavior changes.
- Match existing stack; no new frameworks unless current approach is fundamentally broken.
- Incremental, reviewable diffs; add/update tests per change.
- Flag uncertain items rather than guessing.

---

## 6. Remaining tech debt (post-audit, not in backlog above)

- Application layer documented but unimplemented.
- Offline scope incomplete by design for orders/quotes/chat — document explicitly for staff expectations.
- Integration tests not in CI; no coverage gate.
- Firebase web service worker stub — production push on web incomplete.
- Minimal lint rules beyond stock `flutter_lints`.

---

## 7. Bottom line

Solid foundation: documented architecture, RLS-first security, thoughtful offline sync for staff billing, consistent Riverpod. Main debts are **offline scalability**, **duplicated web/mobile presentation**, and a **missing application layer**. Security and Postgres modeling are ahead of the client sync and presentation layers.
