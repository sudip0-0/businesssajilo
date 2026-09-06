# BusinessSajilo hardening handoff

Updated: 2026-09-06. Repository: `C:\Users\sudip\Desktop\Projects\businesssajilo`.

## Read this first

Work is **uncommitted** and spans multiple hardening batches. Preserve the complete working tree and unsaved IDE buffers. No commit, push, hosted deployment, database reset, or deletion of user data was performed. Local integration tests created retained E2E accounts/documents; do not reset or remove those fixtures without approval.

**Not an all-finished or production-ready declaration.** Most core fixes are implemented and substantial verification passed, but the editor/filesystem mismatch below and several integration/automation gaps remain.

The user's latest request was to promote the existing SQLite dependency, replace unsafe legacy-file copying with read-only recovery, then create this handoff describing completed work, remaining work, and issues.

## 1. Immediate blocker: editor buffers differ from tested files

**Resolved on disk (2026-09-06 follow-up).** The intended `_pushPayment` bootstrap cursor reset (`syncMetaBootstrapOffset` → `0` when `syncMetaBootstrapTable == 'payments'`) and the additional bootstrap / request-identity / nullable split-receipt tests are now in the filesystem copies of `lib/data/sync/sync_pusher.dart` and `test/sync_push_cycle_test.dart`. Unsaved editor buffers were not readable from this session; if an IDE still holds an older or newer buffer, save/compare before discarding. Do not overwrite a newer unsaved buffer with an older disk copy.

## 2. Completed implementation

### Warehouse financial privacy

- Removed warehouse access to raw `customers` rows, including `opening_balance`.
- Read-only `customer_directory` uses explicit active-member, tenant, role and customer-own filtering; it exposes identity fields only.
- Remote bill embeds and bill search use that directory, preserving customer names.
- Customer pickers/copy-bill/invoice-address lookups use identity-only reads where appropriate.
- Warehouse sync loads directory data and skips payment pulls; cached identity reads mask financial values and ignore financial filters.
- EN/NP narrow bill-header overflow fixed.

Key areas: migrations 50/51, `supabase_bills_repository.dart`, `cached_customers_repository.dart`, sync pull strategies, mobile/web billing, warehouse privacy tests.

### Orders, quotes and billing

- `place_order` atomically validates/inserts nonempty customer orders with active same-tenant products and replay-safe UUIDs. Changed replay payloads are rejected.
- Direct client order/header insertion policies were removed; current clients use the RPC.
- Bill insertion rejects a customer that differs from its linked order.
- `respond_quote` validates response ownership, immutable terms, expiry and status; identical-response replay is supported.
- Accepted quote lines, quantities, rates and discounts are preserved in shared bill-draft mapping.
- Failed quote/product lookups produce errors/retry rather than silently substituting reference prices or dropping lines.
- Staff-mobile `createFromOrder` delegates online, caches confirmed results and does not enqueue an offline order bill or duplicate local payment/stock movements.
- The named UI integration stub now pumps actual cart/quote/version/acceptance/payment/bill screens with deterministic repositories. Live repository integration separately exercises real Supabase quote versions, acceptance and billing.

Remaining warehouse order-prefill caveat is listed below; do not infer that all warehouse order navigation is complete.

### Sync, account isolation and legacy recovery

- Validate financial RPC acknowledgements before marking local entities/queues synced. Unknown queue types fail rather than silently succeed.
- Queue ties are deterministic; dependency rounds retry dependents after prerequisites in the same pass.
- Pending/failed local payments and queue evidence are protected from pull overwrite.
- Scoped cache names include business/member/role. Session-generation checks prevent stale bootstrap publication and late pull writes.
- Network-await deadlines bound stalled requests; disposal waits for active database work.
- Failed sign-out/deletion preserves session/sync and attempts push re-registration for the same session without masking the original error.
- `wipeAllLocalData` clears sync metadata. Production startup does not blindly wipe or claim populated unverified caches.
- Legacy/former-role recovery verifies entity business, actor, payload, role permission and dependencies, and uses durable import receipts to prevent duplicate replay. Unverifiable work remains retained with localized notices/retry guidance.

**Latest requested SQLite change is complete:**

- `sqlite3: 3.5.1` promoted from transitive to direct dependency, at exactly the existing locked version; no upgrade.
- `legacy_cache_files_io.dart` opens the source with `OpenMode.readOnly`, sets `query_only` and a 1000 ms busy timeout, begins a read transaction, pins a snapshot with an initial schema read, then rolls back/closes reliably.
- Source reads use a query-only adapter during destination transactions. The old whole-main/WAL-file copying into system temp was removed.
- No source attachment, migration, whole-database temporary duplication, or machine-existing cache access occurred during tools. Tests used disposable fixtures.
- SQLite read-only WAL access still uses ordinary shared-memory/locking coordination; main/WAL contents are preserved, not guaranteed immutable SHM metadata.

Key files: `lib/data/local/legacy_cache_files*.dart`, `legacy_cache_recovery.dart`, `app_database.dart`, `lib/data/sync/*`, auth providers, recovery/sync/auth tests.

### Financial math and import safety

- NPR input uses exact decimal/BigInt-to-paisa parsing; nonfinite, exponent, malformed grouping, excessive precision and unsafe magnitudes are rejected. Devanagari digits and valid grouped amounts are supported.
- Raw invalid billing text is retained separately and blocks save; previews may retain the last valid integer, but invalid input cannot persist through shared validation.
- Payment/product/bill prefills, transaction details, PDFs, CSVs and amount-in-words preserve paisa.
- Oldest-first allocation serializes same-ID requests, locks bills deterministically, then recomputes debt including credit notes. Excess receipts remain account credit.
- Explicit single-bill allocation keeps its existing whole-amount behavior; a blanket overpayment ban was not introduced.
- Import quantity/threshold fields reject fractional values instead of rounding.
- Import and standalone product creation distinguish uncertain creation from acknowledged product/uncertain opening stock, show product identity and reconciliation guidance, and block blind repeated submission within that form/runner session.

Import recovery is **not durable or atomic** across closing/reopening. See remaining work.

### Web accessibility and verification harnesses

- Role/category-aware search and router-compatible destinations; stale results are invalidated when role/query changes.
- Routed-content semantics no longer hide persistent sidebar/top-bar controls. Sidebar buttons have selected state, focus and accessible labels.
- Notification dropdown supports Escape, focus restoration, short/narrow geometry and View All.
- Customer prefill renders watched data directly; browser test fixtures no longer call guarded tester expectations inside asynchronous live frames.
- Approved `Roboto` alias points at bundled Inter-Regular. Named mobile/web themes remain unchanged; the engine no longer needs a default-font CDN request.
- Build-based browser widget harness serves unmodified assets, uses public integration-test results and blocks external requests.
- Actual-app E2E verifies real controls, sidebar routes, forms/Cancel, notification behavior and persisted EN/NE state. It no longer masks failed clicks with URL fallbacks or exits before browser cleanup.
- Local hardening gate defaults to migration-up/list/test, not reset; resets require an explicit switch and exact interactive confirmation. Native subcommand failures are checked individually.

## 3. Database migration state

All versions through **58** are applied to local Supabase and appear in both columns of `supabase migration list --local`. This does not indicate a hosted deployment.

| Migration | Purpose |
|---|---|
| 50 | Warehouse-safe read-only customer directory and raw-customer denial |
| 51 | Bill search uses the safe directory |
| 52 | Atomic/replay-safe order placement and order/customer bill binding |
| 53 | Quote response integrity, expiry and replay safeguards |
| 54 | Serialized credit-note-aware payment allocation |
| 55 | Forward correction of migration54's enum/text role-guard error |
| 56 | Billing resolves existing customers only; no Auth/member/customer provisioning |
| 57 | Explicit child business IDs, parent stamping, composite foreign keys and restrictive RLS |
| 58 | Customer own-bill search, warehouse billing-draft RPC, warehouse audit-log SELECT removed |

Migration57 covers `bill_items`, `order_items`, `quotes`, `quote_items`, `credit_note_items`, and `device_tokens`. `businesses.id` remains the tenant root. Existing parent FK names/cascade behavior are retained so PostgREST relationship hints still work.

Before/after fingerprints for migration57 matched after excluding the new tenant columns: existing bill items, order items, quotes/items, payments and stock movements were not financially altered by the backfill.

**Deployment cautions:**

- Apply 54 and 55 together; 55 fixes an error discovered in 54. Do not deploy only 54.
- Migration57 backfills and validates existing tables and creates indexes, so it requires production-volume and lock-duration planning.
- Its initial `SET LOCAL` emitted a warning outside a transaction in the local CLI; the intended lock timeout was not enforced. Do not rely on that statement for deployment safety. Use an approved, controlled deployment/transaction strategy with writes quiesced as appropriate.
- Old clients doing direct order inserts will be denied after migration52. Coordinate client/backend rollout.
- Do not rewrite applied history, reset databases, or deploy as a shortcut.

## 4. Actual verification results

Latest commands executed against the **filesystem version**:

| Check | Result |
|---|---|
| `flutter analyze --no-pub` | No issues |
| `flutter test --no-pub --reporter compact` | **595 passed, 10 skipped, 0 failed** |
| `supabase test db --local` | **520 assertions, 36 files, passed** |
| `supabase migration list --local` | Through 58 in both columns |
| Read-only legacy recovery/payment-pull focused run | **37 passed** |
| Copy/order-prefill fixture tests after repair | **12 passed** |
| Last live backend integration run | **3 passed**: order/quote/bill, warehouse privacy/billing, payment concurrency with distinct DB sessions |
| Last build-based browser widget run | **29/29 passed**, strict local-only networking |
| Last actual-app E2E run | **17/17 passed**, strict local-only networking and cleanup |
| Latest full format check | **536 files, 0 would change** |
| Git diff whitespace checks | Passed; ordinary LF/CRLF advisories remain |

The full-suite skips include unconfigured live integrations and a printing-platform rasterization test. Live integrations were separately configured/run earlier; skips are not counted as passes. Browser results precede the final read-only SQLite native changes and should be rerun after buffer synchronization for a final combined sign-off.

Focused sync/payment runs also passed malformed-acknowledgement, split-receipt and retry tests, but **not the latest unsaved payment-bootstrap additions** described in section 1.

Deno was unavailable in the local environment; do not mark `npm test` or a strict complete gate passed. Android/iOS device verification was not available. Build output still includes a Cupertino icon-font-family warning; test fixtures produce expected failure-path logs and Drift multiple-database debug warnings.

## 5. Remaining work, in recommended order

### P0/P1 completed in this follow-up

- Payment bootstrap cursor reset and split-receipt/request-identity tests are on disk.
- Customer own-bill `search_bills` path (migration 58) with pgTAP allow/deny.
- Warehouse `billing_draft_from_order` RPC: accepted-quote or order-item lines plus directory identity; warehouse still cannot SELECT orders/quotes/quote history/finance.
- Warehouse `audit_log` SELECT removed; owner/sales retain tenant reads; pgTAP covers financial old/new JSON deny.
- Quote section displays use `showPaisa: true`.
- Quantity×rate and multi-line totals reject values past `maxExactPaisa`.
- CI/release: no `--web-renderer canvaskit`; generated `git diff --exit-code`; browser widget harness; local-resource actual-app E2E before release deploy.
- Local gate forwards Supabase dart-defines into Flutter tests; `pub outdated` is informational.

### P2: recovery and convenience limitations

- Import/product-create uncertainty requires manual inventory/stock-history reconciliation. Closing/reopening loses the session replay guard. Durable automatic import retry requires caller-owned operation IDs and a tested idempotent/transactional backend; do not simply retry uncertain writes.
- Cart placement UUID survives sheet retries, not process restart. Durable draft recovery remains unimplemented.
- Contextual first-bill checklist, saved filters, broad accessibility/text-scaling review, and dedicated stock-count/reconciliation UX were candidates, not completed features.
- No production performance benchmark, startup baseline, first-bill timing study, or projection activation was performed.

### External sign-off

- Android device/emulator and iOS/macOS verification; real printing/share behavior.
- Hosted Auth confirmation/captcha/SMTP, CORS, FCM delivery, Sentry ingestion, store submission/signing.
- Backup/PITR configuration, agreed recovery objectives, and an isolated restore drill.
- None of these should be inferred from integration code or local tests.

Deferred expansions remain excluded: thermal printing without pilot demand, price tiers, supplier accounting, multi-warehouse, unit conversions, batch/expiry, customer self-service, gateways, SMS, subscriptions, VAT.

## 6. Documentation updated

Updated `Agent.md`, `Readme.md`, `product.md`, `Architecture.md`, `tasks.md`, `docs/SECURITY.md`, `docs/LOCAL_TESTING.md`, `docs/PROD_CHECKLIST.md`, `supabase/README.md`, and the removed-chat wording in the draft privacy policy.

Corrections cover warehouse billing/finance separation, current order states and stock deduction, removed chat/categories/LWW RPC, implemented versus configured notifications, actual test layers, non-reset local workflow, child tenant columns, and operations/device gaps. The privacy policy remains a draft requiring review and a real contact address.

## 7. Resume commands and operational boundaries

First read `Agent.md`, the four source-of-truth docs, and this handoff. Save all buffers, then inspect `git status` and `git diff` before editing.

```powershell
flutter analyze --no-pub
flutter test --no-pub
supabase migration list --local
supabase test db --local
dart format --output=none --set-exit-if-changed lib test integration_test
```

For browser widgets:

```powershell
flutter build web --debug --no-web-resources-cdn --no-wasm-dry-run --target=test/support/web_search_test_bootstrap.dart --output=build/web_search_tests
node scripts/run_web_search_tests.mjs
```

See `docs/LOCAL_TESTING.md` for actual-app E2E and configured live integration commands. Use only loopback Supabase and disposable local fixtures. Never log keys, pass service-role credentials to Flutter, relax network/security assertions, or count missing services as passes.

The untracked diagnostic `e2e-error-semantics.txt` was created by an early browser probe. It is not a deliverable; remove that specific artifact with an approved file operation before any commit. No permitted delete tool was available in this session, so it was left intact.

No commit/push/deploy has been requested. Do not perform one automatically after reading this handoff.
