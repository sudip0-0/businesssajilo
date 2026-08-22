# businesssajilo — Audit Remediation Implementation Plan

> **For Hermes:** Execute task-by-task. Each task is independently verifiable; run the verification commands before marking done. Commit after every task.

**Goal:** Fix all 6 high-severity, 13 medium, and 10 low findings from the 3-part codebase audit without breaking existing behavior.

**Architecture:** Flutter 3.44 app + Drift local DB + Supabase (RLS Postgres, 5 Deno Edge Functions). Fixes are layered: SQL migrations (append-only, never edit old migrations), Edge Function edits, Dart app edits. Every layer has its own test suite — run the relevant one per task and the full suites at the end.

**Tech stack:** Flutter/Dart, Drift, Riverpod, Supabase (Postgres RLS, Deno functions), Playwright e2e.

**Ground rules (apply to every task):**
- New SQL goes in a NEW migration file `supabase/migrations/00000000000046_audit_remediation_*.sql` (numbered sequentially; check `ls supabase/migrations | tail` for the next number before writing).
- Never edit an already-applied migration.
- Run `flutter analyze` after Dart changes; `flutter test` per affected area; `dart format` changed files.
- Edge Functions: run `deno check` / `deno test supabase/functions` if deno is available; otherwise verify by reading + `supabase functions serve` manual smoke.
- Full verification gate at the end: `flutter analyze && flutter test && (cd supabase && supabase db reset && supabase test)`.

---

## Phase 1 — High Severity

### Task 1: Fix stock_movements RLS so sales-role offline sales sync (Audit #1)

**Objective:** Sales users' counter-sale dispatch movements must be accepted by RLS on push, while still preventing sales users from arbitrary stock edits.

**Files:**
- Create: `supabase/migrations/00000000000046_sales_dispatch_rls.sql`
- Ref: `supabase/migrations/00000000000003_phase2_inventory.sql:224` (old policy), `lib/data/sync/syncing_bills_repository.dart:406-420`, `lib/data/sync/sync_pusher.dart:268`
- Test: `supabase/tests/` (follow existing test-file pattern there)

**Step 1: Write the migration**

```sql
-- 46: Allow sales members to push dispatch movements for their own bills.
-- Previously only owner/warehouse could INSERT stock_movements, which made
-- offline counter-sales by sales users fail sync permanently.

drop policy if exists "owner warehouse insert movements" on stock_movements;

create policy "members insert movements" on stock_movements
  for insert with check (
    business_id = current_business_id()
    and created_by = current_member_id()
    and (
      current_role_name() in ('owner', 'warehouse')
      or (
        current_role_name() = 'sales'
        and type = 'dispatch'
        and bill_id is not null
        and exists (
          select 1 from bills b
          where b.id = stock_movements.bill_id
            and b.business_id = stock_movements.business_id
            and b.created_by = current_member_id()
        )
      )
    )
  );
```

> ⚠️ Before finalizing: read the actual m03 policy and the `stock_movements` schema to confirm column names (`created_by`, `bill_id`, `type`) and `current_member_id()` helper name — adjust to match reality. If dispatch movements are not linked to `bill_id`, add that link in the Dart sync payload instead (Step 3).

**Step 2: Write the failing test** (mirror the style of existing `supabase/tests/*` pgTAP or SQL tests): as a `sales` member in business X, insert a `dispatch` movement tied to their own bill → expect success; insert a `stock_in` movement → expect RLS violation.

**Step 3: Verify the Dart payload satisfies the policy** — read `syncing_bills_repository.dart:406-420` and confirm pushed rows carry `bill_id` and `created_by`. If not, add the fields to the payload map in `sync_pusher.dart:268` path.

**Step 4: Verify:** `cd supabase && supabase db reset && supabase test` (or the repo's documented test command in supabase/README.md).

**Step 5:** `git add -A && git commit -m "fix(rls): allow sales dispatch movements for own bills"`

### Task 2: Customer portal accounts default to inactive (Audit #2)

**Objective:** `create-member` must not hand out live portal logins by default.

**Files:**
- Modify: `supabase/functions/create-member/index.ts:175`
- Test: add case to existing function tests if present; otherwise verify by reading.

**Step 1: Change the default**

```ts
// Before:
const isActive = body.isActive === false ? false : true;
// After (customers default inactive; staff roles may default active):
const isActive = body.role === 'customer' ? body.isActive === true : body.isActive !== false;
```

Update the comment at :173-175 to match the new behavior.

**Step 2:** Grep the Flutter caller(s) (`grep -rn "create-member" lib`) — if any UI flow relied on the implicit active default for customers, pass `isActive: true` explicitly there (only if that flow is a deliberate owner action).

**Step 3: Verify:** `deno check supabase/functions/create-member/index.ts`; read the full function once for consistency.

**Step 4:** `git commit -m "fix(security): customer portal accounts default inactive"`

### Task 3: Remove PII from FCM push payloads (Audit #3)

**Objective:** No shop names or amounts in FCM titles; render them app-side.

**Files:**
- Modify: `supabase/functions/notify/index.ts:100-114` (`titleFor()`), and the push body assembly at :154-168
- Modify: `lib/core/notifications/push_service.dart` / notification rendering (wherever the title is displayed — `lib/features/notifications/`)

**Step 1:** Replace title/body with neutral text, e.g. `title: 'Payment reminder'`, `body: 'You have an outstanding balance. Open the app for details.'` Keep the routing identifiers (`billId`, `businessId`, `kind`) in the `data` payload only.

**Step 2:** In the Flutter notification tap handler / notification list, if the UI displayed the FCM title directly, fetch the display strings from the notifications table (they're already pulled there) instead.

**Step 3:** Update `push_policy_test.ts` expectations if they assert on title contents.

**Step 4: Verify:** `deno test supabase/functions/` ; `flutter analyze`.

**Step 5:** `git commit -m "fix(privacy): remove PII from FCM push payloads"`

### Task 4: Lock bill status recompute in record_payment (Audit #4)

**Objective:** Eliminate concurrent-payment stale-status race by delegating to the existing locking helper.

**Files:**
- Create: `supabase/migrations/00000000000047_record_payment_lock.sql`
- Ref: final `record_payment` in `00000000000033_qol_v12.sql:~285-300`, helper `refresh_bill_status_for()` from m13

**Step 1:** Copy the full final `record_payment` definition into the new migration; replace every inline `select sum(...)... update bills set status...` block with `perform refresh_bill_status_for(open_bill.id);`. Keep everything else byte-identical. Use `create or replace function` matching the existing signature exactly.

**Step 2:** Test: in `supabase/tests`, add a test recording two payments concurrently (two sessions) and assert final status is `paid` when sums reach the total.

**Step 3: Verify:** `supabase db reset && supabase test`.

**Step 4:** `git commit -m "fix(db): lock bill row during payment status recompute"`

### Task 5: Move session cache to secure storage (Audit #5)

**Objective:** Member session JSON must not sit in plain-text SharedPreferences.

**Files:**
- Modify: `lib/core/utils/session_cache.dart`
- Modify: `pubspec.yaml` (add `flutter_secure_storage`)
- Modify: `lib/core/router/router_provider.dart` (treat cached role as untrusted — see Step 3)

**Step 1:** `flutter pub add flutter_secure_storage`.

**Step 2:** Rewrite `SessionCache` to use `FlutterSecureStorage` with the same public API (read/write/clear of the member JSON). Add a one-time migration: on first read, if the old SharedPreferences key exists, move it into secure storage and delete the old key.

**Step 3:** In the router bootstrap, keep using the cached session for instant paint but mark it `provisional: true`; clear the flag once the first server session reload completes. (Locate the reload point in `auth_provider.dart`.)

**Step 4:** Run existing auth tests; add one for the migration path (write legacy pref → read → assert secure-storage value and pref deleted).

**Step 5: Verify:** `flutter analyze && flutter test test/core/ test/features/auth/`.

**Step 6:** `git commit -m "fix(security): store session cache in secure storage with legacy migration"`

### Task 6: Server-time sync watermarks (Audit #6)

**Objective:** Delta watermarks must come from the server, not the device clock.

**Files:**
- Modify: `lib/data/sync/sync_puller.dart:27,43`
- Modify: `lib/data/sync/pull/sync_pull_entities.dart:64,119,226`
- Test: `test/data/sync/` (find existing sync tests with `grep -rn "watermark" test lib`)

**Step 1:** After each successful pull page, set the watermark to `max(updated_at)` of the rows just fetched (fallback: keep previous watermark). Remove `DateTime.now().toUtc()` watermark writes.

**Step 2:** On bootstrap completion, seed the watermark from the max `updated_at` returned by the server (add a lightweight `select now()` RPC only if no fetched rows provide it — prefer the row-max approach to avoid a new RPC).

**Step 3:** Update/add unit tests: fake server rows with `updated_at` in the past relative to device clock; assert next pull uses row-max watermark, not wall clock.

**Step 4: Verify:** `flutter test test/data/sync/ && flutter analyze`.

**Step 5:** `git commit -m "fix(sync): derive pull watermarks from server row timestamps"`

---

## Phase 2 — Medium Severity

### Task 7: Await bill totals before payment sheet (Audit #7)
- **Files:** `lib/features/billing/bill_detail_screen.dart:180-186`, `lib/features/billing/providers.dart:61`
- In `_payBill`, replace sync `ref.read(billReceivedTotalProvider(...))` with `final received = await ref.read(billReceivedTotalProvider(...).future);` before computing the pre-fill amount (guard with `if (!context.mounted) return;` after the await).
- Verify: `flutter test test/features/billing/` (add a widget test if one exists for the sheet pre-fill).
- Commit: `fix(billing): prefill payment sheet with awaited received total`

### Task 8: Close phone-enumeration oracle in create-member (Audit #8)
- **Files:** `supabase/functions/create-member/index.ts:126-136`
- Delete the all-businesses pre-check; wrap the insert and map unique-violation (Postgres error code `23505`) to the same generic 409 text.
- Verify: `deno check`; commit: `fix(security): remove cross-tenant phone existence oracle`

### Task 9: Harden register-business rate limiter + captcha flag (Audit #9)
- **Files:** `supabase/functions/register-business/index.ts:17-31`, `supabase/config.toml` (captcha section)
- Cap the attempts Map (evict entries older than the window on each call; hard-cap size 10k). Enable the captcha provider in config.toml and enforce the token in the function if the project has Turnstile keys; otherwise leave a TODO gated by env presence.
- Verify: `deno check`; commit: `fix(security): bound register-business rate limiter, wire captcha`

### Task 10: Restrict CORS origin default (Audit #10)
- **Files:** `supabase/config.toml:396-397`, `supabase/functions/_shared/` (CORS helper if any)
- Change `ALLOWED_ORIGIN` default to `http://localhost:3000` (dev) and add a module-load guard in `_shared` that throws on `*` in production (`SUPABASE_URL` not localhost).
- Verify: `deno check` all functions; commit: `fix(security): no wildcard CORS default`

### Task 11: Await auth before notification-tap routing (Audit #11)
- **Files:** `lib/app.dart:44-52`
- In `pushNavigationBootstrapProvider`, replace `authProvider.value?.member?.role` with `final auth = await ref.read(authProvider.future);` then compute role (wrap handler body in try/catch; check `mounted` before navigating).
- Verify: `flutter analyze` + existing app bootstrap tests; commit: `fix(nav): await auth state before routing notification taps`

### Task 12: Deterministic bill bootstrap pagination (Audit #12)
- **Files:** `lib/data/sync/pull/sync_pull_entities.dart:151-176`
- Change `.order('created_at', ascending: false)` to a two-key order `created_at desc, id desc` (Supabase: chain two `.order()` calls) so pages are stable across inserts.
- Verify: `flutter test test/data/sync/`; commit: `fix(sync): stable ordering for bill bootstrap pagination`

### Task 13: InitPlan-wrap RLS helpers (Audit #13)
- **Files:** Create `supabase/migrations/00000000000048_rls_initplan.sql`
- For the policies named in m05:169-215 and the customers/orders/quotes equivalents: `drop policy` + `create policy` with `(SELECT current_business_id())` / `(SELECT current_role_name())` and scalar-subquery customer-id sets. Script this: extract all policies with `grep -n "create policy" supabase/migrations/*.sql`, rewrite the ones using bare helper calls.
- Verify: `supabase db reset && supabase test`; spot-check `explain` on a representative query shows InitPlan. Commit: `perf(rls): wrap policy helpers for initplan caching`

### Task 14: Deduplicate CSV export logic (Audit #14)
- **Files:** `lib/features/reports/report_export_actions.dart`, `lib/core/export/export_actions.dart`
- Keep `core/export/export_actions.dart` as the single implementation; parameterize by data source (row-builder callback). Delete the diverging report-local copies; re-point call sites.
- Verify: `flutter analyze && flutter test test/features/reports/ test/core/export/`; commit: `refactor(export): single CSV export implementation`

### Task 15: Correct HTTP status codes in edge functions (Audit #15)
- **Files:** catch-alls in `create-member/index.ts:225`, `delete-account/index.ts:174`, `register-business/index.ts:138`, `reset-member-password/index.ts:133`, `notify/index.ts:41,148-151`
- Catch-alls → 500 (keep 400 only for validated-input rejection); wrap `notify`'s `req.json()` in its own try/catch returning 400.
- Verify: `deno check` + `deno test supabase/functions`; commit: `fix(functions): accurate HTTP status codes`

### Task 16: Use shared validation module everywhere (Audit #16)
- **Files:** `create-member/index.ts:15-16,137-139`, `register-business/index.ts:14-15,68-70`, `supabase/functions/_shared/validation.ts`
- Hoist `EMAIL_RE` and `normalizePhone` into `_shared/validation.ts`; import `str`, `MAX_FIELD_LEN`, `validatePassword` in both functions; delete local duplicates.
- Verify: `deno test supabase/functions`; commit: `refactor(functions): consolidate validation in _shared`

### Task 17: Batch Excel import (Audit #17)
- **Files:** `lib/features/inventory/product_excel_import.dart:~350-370`
- Replace per-row `create`+`stockIn` awaits with chunked batch (e.g. 50 rows per `batch(...)` / repository batch method); report progress per chunk.
- Verify: `flutter analyze` + manual import of a small sheet; commit: `perf(inventory): batch product excel import`

### Task 18: Eliminate silent empty catches (Audit #18)
- **Files:** `grep -rn "catch (_)" lib --include="*.dart"` (~10 sites: `bill_form_screen.dart:82`, `copy_last_bill.dart:29`, `create_bill_from_order.dart:110,120`, `owner_dashboard.dart:50`, `invoice_export_actions.dart:205`, `currentBusinessProvider` at `auth_provider.dart:28-34`)
- Replace with `} catch (e, s) { AppLog.warn('context', e, s); }`. For `currentBusinessProvider` return the error (`AsyncError`) instead of null so callers can retry.
- Verify: `flutter analyze && flutter test`; commit: `fix(app): log swallowed errors, surface business-load failures`

### Task 19: Explicit drop/create/grant for redefined functions (Audit #19)
- **Files:** Create `supabase/migrations/00000000000049_explicit_grants.sql`
- For `create_bill` and `record_payment`: `drop function if exists ...; create function ...; grant execute ... to authenticated;` matching the final m44/m33 signatures.
- Verify: `supabase db reset && supabase test`; commit: `chore(db): explicit grants on redefined RPCs`

---

## Phase 3 — Low / Hardening

### Task 20: NPT-consistent export filenames (Audit L1)
- **Files:** `lib/core/export/export_actions.dart:27`, `lib/features/reports/report_export_actions.dart:52…`
- Replace `DateTime.now()` filename stamps with the `nowNpt()` helper from `lib/features/reports/report_range.dart` (move it to `lib/core/utils/` if importing features→core is wrong direction).
- Verify: `flutter analyze`; commit: `fix(export): Nepali-time export filenames`

### Task 21: Atomic push idempotency (Audit L2)
- **Files:** `supabase/functions/notify/index.ts:62-69,135-140`
- Claim with `.update({ pushed_at: now }).eq('id', id).eq('pushed_at', null).select()`; proceed only if a row returned. Stamp whenever `sent > 0`.
- Verify: `deno test`; commit: `fix(notify): atomic push claim, stamp on partial success`

### Task 22: Fix delete-account folder pagination (Audit L3)
- **Files:** `supabase/functions/delete-account/index.ts:184-204`
- Loop `list(folder, { offset: 0 })` until empty (objects are removed each pass); add depth cap (e.g. 10) to recursion.
- Verify: `deno check`; commit: `fix(delete-account): stable storage listing pagination`

### Task 23: Locale race guard (Audit L4)
- **Files:** `lib/app.dart:66-77`
- Add `_loaded` flag; ignore `_loadSaved()` result if `setLocale` was already called manually.
- Verify: `flutter test` (add a LocaleNotifier unit test if the notifier is extractable); commit: `fix(l10n): locale load race`

### Task 24: Add bills allocation index (Audit L5)
- **Files:** Create `supabase/migrations/00000000000050_bills_allocation_index.sql`
- `create index if not exists bills_customer_status_created_idx on bills (customer_id, status, created_at);`
- Verify: `supabase db reset`; `explain` the `record_payment` allocation query uses it. Commit: `perf(db): index for payment allocation scan`

### Task 25: Isolate large CSV generation (Audit L6)
- **Files:** `lib/core/export/report_csv_export.dart`
- Wrap row-building in `Isolate.run` when rows exceed a threshold (e.g. 2,000).
- Verify: `flutter analyze`; commit: `perf(export): offload large CSV generation`

### Task 26: Generic config-error screen (Audit L7)
- **Files:** `lib/main.dart:46-56` (`ConfigErrorApp`)
- Show "Configuration error — contact support"; move details to `AppLog` / debug-mode only.
- Verify: `flutter analyze`; commit: `fix(app): generic release config error message`

### Task 27: Lock down auto-expose (Audit L8)
- **Files:** `supabase/config.toml:18-21`
- Set `auto_expose_new_tables = false`; verify the app still runs after `supabase db reset` (all used tables already have explicit grants).
- Commit: `chore(db): disable auto-expose of new tables`

### Task 28: Cache FCM access token (Audit L9)
- **Files:** `supabase/functions/notify/index.ts:95-96,197-253`
- Module-scope `let cachedToken: {token, expiresAt} | null`; reuse until 5 min before expiry; parse service account once.
- Verify: `deno test supabase/functions`; commit: `perf(notify): cache FCM OAuth token`

### Task 29: Dart enum for movement types (Audit L10)
- **Files:** `lib/domain/enums.dart` (add `StockMovementType`), `lib/data/sync/syncing_bills_repository.dart:411`, `lib/data/local/app_database.dart`
- Use the enum when constructing payloads so typos are compile errors.
- Verify: `flutter analyze && flutter test test/data/`; commit: `refactor(sync): typed stock movement types`

### Task 30: E2E credential hygiene (Audit #2 follow-up)
- **Files:** `scripts/e2e_web.mjs:12`
- Fail when `E2E_PASSWORD` unset against non-local URL; keep `password123` only for explicit localhost.
- Verify: `node scripts/e2e_web.mjs --help` / dry run; commit: `chore(e2e): require env credentials off localhost`

---

## Final Verification Gate (all tasks done)

1. `flutter analyze` — zero new warnings.
2. `flutter test` — full suite passes.
3. `cd supabase && supabase db reset && supabase test` — all migration + pgTAP tests pass on a fresh DB.
4. `deno test supabase/functions` (if deno available).
5. Manual smoke: run the app (`flutter run -d chrome` or windows), log in with seed user, create a bill + payment, verify status transitions and a CSV export.
6. `git log --oneline` — one commit per task, all messages match the plan.

## Risks & Notes
- **Task 1** depends on the actual `stock_movements` schema — verify column names before writing the migration.
- **Task 13** touches ~dozens of policies; do it in one migration but test with the full `supabase test` suite, and diff policy counts before/after (`select schemaname, tablename, count(*) from pg_policies group by 1,2`).
- **Task 5**: `flutter_secure_storage` on web uses IndexedDB with encryption — acceptable; note it in the PR.
- **Task 6**: watermark semantics change means the first pull after deploy re-pulls a small window — harmless.
- **Task 2**: confirm no existing customers rely on auto-active behavior in production before deploying.
