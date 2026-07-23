# BusinessSajilo — Full Codebase Audit Report

**Date:** 2026-07-10 (scores refreshed 2026-07-23 after Phase 12 local verification)  
**Scope:** Full multi-lens audit (read-only origin). Phase 12 added tests, docs, and local gate script.  
**Prior docs consulted:** `Readme.md`, `Architecture.md`, `Agent.md`, `product.md`, `Design.md`, `tasks.md`, `docs/SECURITY.md`, `docs/LOCAL_TESTING.md`, `AUDIT_ARCHITECTURE.md`, `AUDIT_INVENTORY.md`  
**Method:** Repo orientation + four parallel lens investigations + spot-verification; Phase 12 re-verified test counts and gate script.

---

## Remediation status (2026-07-23 — Phase 12 local verification)

Phases A–F plus **Phase 12** (verification, docs, local audit script) and **Local 95+ hardening** (Phases 1–8):

| Phase | Status | Notes |
|-------|--------|-------|
| A–F | Done | See table below (2026-07-10) |
| Local 95+ / 1–8 | Done | Security contracts, notification deep links, architecture boundaries, error UX, hotspot splits, local system hardening, a11y tokens, verification gate |
| 12 | Done | Remote/auth/sync tests expanded; Deno validation tests; `local_hardening_gate.ps1`; docs refreshed |

**Verification (2026-07-23):** `flutter analyze --fatal-infos` clean; `flutter test` → **221 passed / 9 skipped**. `supabase test db` / Deno — run via `scripts/local_hardening_gate.ps1` when Docker/Deno available.

**Local rubric scores (honest, post–Local 95+ hardening):**

| Lens | Score | Remaining gaps |
|------|-------|----------------|
| Security | **95** | Prod captcha/SMTP/checklist ops-owned; distributed signup rate limit |
| Architecture | **95** | Residual auth SDK exception; intentional online-only domains |
| Coding practices | **95** | PostgREST `dynamic` mappers remain; some web forms still larger than mobile peers |
| System design (local) | **95** | Unpaginated notification feed scale; deployment safety N/A by contract |
| UI/UX | **95** | Light-only v1 (documented); phone reset UX intentional gap |

---

## Remediation status (2026-07-10)

Approved decisions: **1B, 2B, 3A, 4B, 5A, 6C**. Phases A–F implemented in-repo.

| Phase | Status | Notes |
|-------|--------|-------|
| A | Done | Android release dart-defines; `customer_balances.updated_at` restored (migration 16); sync pull order + offline balance debit; web `/notifications` allowed; web sync tile removed |
| B | Done | Direct bill/item/payment INSERT revoked; `record_payment` RPC; legacy `bill_items` queue rejected; chat image resize/sanitize |
| C | Done | Phone forgot-password hint; customer profile deferred in PRD/tasks; AccountAction on sales/warehouse + web non-owners |
| D | Done | Minimal sync/auth cycle break; `SyncState` → `data/sync`; `currentBusinessProvider` → auth providers |
| E | Done | Full web dark `ThemeData`; role label; `BsSuccessButton.loading`; ErrorState live region; notification list cap |
| F | Done | pgTAP phase16 + updated suites (132 pass); seed E2E owner; E2E key required; docs; crash reporting deferred |

**Verification:** `flutter test` → 137 passed / 7 skipped. `supabase test db` → 132/132 PASS.

**Manual follow-up:** Apply migration 16 to any remote Supabase projects (`supabase db push` / migrate). Confirm release secrets include Android dart-defines. Prod Auth checklist in `docs/SECURITY.md` still ops-owned.

---

## Phase 0 — Orientation summary

**BusinessSajilo** is a multi-tenant Flutter SaaS for Nepali dealers/distributors (Android, iOS, Web; Windows runner for desktop-dev only). It covers inventory, quote-first ordering, non-VAT billing, credit (udharo) ledger, and order chat across four roles (owner, sales, warehouse, customer). The client uses Riverpod 3 (hand-written providers), go_router, and Freezed models; staff mobile adds Drift/SQLite offline sync. Backend is Supabase (Postgres + RLS, Auth, Realtime, Storage, five Edge Functions, FCM via `notify`). Layout is layered (`lib/core`, `domain`, `data`, `features`, parallel `lib/web`), with no `application/` use-case layer by design. Tooling: `pubspec.yaml` + npm Playwright helpers, GitHub Actions CI (`format` / `analyze` / `test` / `supabase test db`) and tag-based release (web + Android AAB). Docs claim phases 0–11 complete; residual ops items live in `docs/SECURITY.md`.

---

## Executive summary

- **Core architecture is sound:** UI does not call Supabase directly; `features/` does not import `web/`; RLS + pgTAP are the real security backbone; money math has solid Dart + Postgres tests.
- **Offline sync has a real correctness bug:** customer delta pull filters on `customer_balances.updated_at`, but migration 11 recreated that view **without** `updated_at` — delta customer/balance sync is broken after bootstrap.
- **Release pipeline can ship a dead Android build:** `release.yml` builds the AAB without Supabase `--dart-define`s (web build has them).
- **Several web UX flows are broken today:** `/notifications` is registered but blocked by role-path guards; `/owner/settings/sync` is pushed but not routed.
- **Launch-hardening claims overshoot reality:** phone users cannot self-reset password; account delete/change-password UI is missing for sales/warehouse (mobile) and non-owner roles (web); customer “own profile” edit from the PRD is absent.
- **Defense-in-depth gap on billing:** app uses `create_bill` RPC, but RLS still allows direct `bills` / `bill_items` INSERT for owner/sales.
- **Test shape is uneven:** pure logic and RLS are strong; sync orchestration, remote repos, auth session lifecycle, and CI integration/E2E are weak or skipped.
- **Architectural debt is real but not urgent for launch:** `data → features` dependency cycle around sync/auth; large bill-form / dashboard duplication between mobile and web.
- **Ops checklist still open** (captcha, SMTP, email confirmation, prod `ALLOWED_ORIGIN`, web FCM) — documented, not code bugs.
- **No Critical secrets-in-client or service-role leakage found** in the Flutter app; Edge Functions fail closed without `ALLOWED_ORIGIN`.

---

## Findings table

| ID | Severity | Lens | Location | Issue | Suggested fix |
|----|----------|------|----------|-------|---------------|
| C1 | **Critical** | DX / Reliability | `.github/workflows/release.yml` L25–26 | Android release AAB built with **no** `SUPABASE_URL` / `SUPABASE_ANON_KEY` dart-defines (web build L21–24 has them). Released APK/AAB would hit `ConfigErrorApp`. | Mirror web `--dart-define` secrets on `flutter build appbundle`; gate release on CI green. |
| C2 | **Critical** | Performance / Sync | `lib/data/sync/sync_puller.dart` L184–200; `supabase/migrations/00000000000011_credit_notes.sql` L174–192 (view lacks `updated_at`; phase 8 had it at `00000000000008_…` L163–178) | Customer delta sync queries `.gt('updated_at', …)` on `customer_balances`, but the column was dropped when the view was recreated for credit notes. | Restore `c.updated_at` (or a balance watermark) on the view; add sync/pgTAP coverage; verify pull after bills/payments/CNs. |
| H1 | **High** | Performance / Sync | `lib/data/sync/sync_puller.dart` bill/payment upsert batches (~L388–510); `syncing_bills_repository.dart` create path | Pulling bills/payments updates local tables but does not refresh `local_customers.balance_due`; offline due-bill create can leave balances stale. | Recompute or re-pull balances after bill/payment/CN sync; keep payments path (`syncing_payments_repository.dart` L69) consistent. |
| H2 | **High** | Security | `supabase/migrations/00000000000005_phase4_billing.sql` L180–192, L218–233; app uses RPC in `supabase_bills_repository.dart` L211–215 | Direct INSERT on `bills`/`bill_items` still allowed for owner/sales — bypasses `create_bill` validation. | Revoke client INSERT; allow only via `create_bill` SECURITY DEFINER; add pgTAP deny tests. |
| H3 | **High** | UI/UX | `lib/web/router/web_role_routes.dart` L20–26; `web_router.dart` L81–82, L100–103; `web_top_bar.dart` L47–49 | Bell navigates to `/notifications`, but `webPathAllowedForRole` returns false → redirect home. Web notification center is unreachable. | Allow `/notifications` (and `/change-password`) for authenticated roles, or nest under each role prefix. |
| H4 | **High** | UI/UX | `lib/web/features/settings/web_settings_page.dart` L111–115, L204–217; `web_router.dart` L283–286 | Settings pushes `/owner/settings/sync` but no nested route exists → not-found. `WebPendingSyncPage` is dead code. | Register nested `sync` route **or** remove/hide the tile (sync is mobile-only per `sync_config.dart`). |
| H5 | **High** | Features | `lib/features/auth/forgot_password_sheet.dart` L9, L83–91; login accepts phone via `login_identifier.dart`; `tasks.md` L89–91 marks T-101/T-102 done | Forgot-password is email-only and does not map phone → synthetic email. Phone-primary users cannot self-reset. | Accept phone + `loginEmailForIdentifier`, or clearly gate the link to email accounts and rely on owner `reset-member-password`. |
| H6 | **High** | Features | `product.md` L31; customer shells lack profile edit; `CustomerFormScreen` is owner-entry only | PRD grants customers “own profile” edit; no customer-facing UI. | Add customer profile screen scoped to own row + RLS update policy if missing. |
| H7 | **High** | Features | `customer_shell.dart` L74 has `AccountAction`; `sales_shell.dart` / `warehouse_shell.dart` logout-only; web non-owner shells lack account tiles; `tasks.md` L91 claims T-103 done | Change-password / delete-account UI incomplete for staff mobile and non-owner web. | Reuse `AccountSettingsTiles` / `AccountAction` in those shells; keep Edge Function as source of truth. |
| H8 | **High** | Architecture | `lib/data/sync/sync_providers.dart` L10, L29–48; `businesses_repository.dart` L5, L12–17; `auth_provider.dart` L101–114 | Data layer imports feature `authProvider`; global `_activeBundle` + version bump work around Riverpod circularity. | Move session/sync lifecycle to `core/session` (or features); pass IDs downward; eliminate module-global bundle. |
| H9 | **High** | Code quality | `lib/web/features/billing/web_bill_form_content.dart` (~680 LOC); mobile `bill_form_screen.dart` (~524 LOC) | Monolithic bill forms are the main complexity hotspot for a money-critical flow. | Extract line-items / pickers / totals widgets + shared `BillFormController`. |
| H10 | **High** | Testing | `lib/data/sync/sync_puller.dart`, `sync_pusher.dart`, `sync_service.dart` | ~~Sync orchestration untested~~ **Partially closed (Phase 12):** `sync_strategy_test`, `sync_bootstrap_budget_test`, `sync_multi_device_test`, push cycle tests | Extend puller integration with mocked Supabase pages |
| H11 | **High** | Testing / DX | Integration tests | E2E owner seeded; repository order→bill test; UI stub with HARDENING_GATE | Full UI pump; CI integration job still optional |
| H12 | **High** | Testing | Auth + remote repos | **Partially closed (Phase 12):** `auth_repository_test`, `auth_provider_test`, expanded `remote_repo_http_test` | HTTP-mocked `loadSession` deactivated path |
| M1 | **Medium** | Security | `lib/data/sync/sync_pusher.dart` L116–119; payments RLS in phase3 migration | Standalone payments upsert via PostgREST — no `record_payment` RPC validation. | Add SECURITY DEFINER RPC with amount/bill checks; use from sync + online path. |
| M2 | **Medium** | Security | `sync_pusher.dart` L42–44, L108–114 | Legacy `bill_items` queue handler still upserts items directly. | Remove/reject legacy entity type; only `create_bill`. |
| M3 | **Medium** | Security | `supabase/functions/register-business/index.ts` L17–31, L77–80 | Public signup; in-memory IP rate limit (not distributed). | Captcha + distributed rate limit; invite-only option. |
| M4 | **Medium** | Security | `supabase/config.toml` L227–234; register-business auto-confirms email | Local/prod risk: email confirmation off / auto-confirm. | Enable confirmations + leaked-password protection in prod (checklist). |
| M5 | **Medium** | Security | `order_chat_screen.dart` L75–89; `messages_repository.dart` L68–77 | Chat images: no client resize/size cap; raw `fileName` in path. | Mirror product upload constraints; sanitize basename. |
| M6 | **Medium** | Architecture | `lib/core/export/export_actions.dart` L15–16, L24–26 | Core export imports feature providers. | Move orchestration to features/reports or pass data in. |
| M7 | **Medium** | Architecture | `domain/models/session_state.dart` L1, L8–9 | Domain depends on Supabase `User`. | Domain `AuthUser` + map in repository. |
| M8 | **Medium** | Architecture | `sync_providers.dart` L8, L55–64; `core/ui/sync_badge.dart` L6–13 | Data sync status uses UI `SyncState` enum. | Move enum to domain/data. |
| M9 | **Medium** | Code quality | Abstract repos only for offline domains; customers remote inline in `customers_repository.dart`; `CachedCustomersRepository` takes raw `SupabaseClient` | Inconsistent repository / cache patterns. | Document convention; extract remote; inject remote into cache like products. |
| M10 | **Medium** | Code quality | Duplicate owner dashboards + paginated lists (mobile vs web); dual notification navigators | Bug fixes must land twice; already slight drift. | Shared controllers / route resolvers; shells for layout only. |
| M11 | **Medium** | Code quality | `sync_puller.dart` ~560 LOC | Still a complexity hotspot after SyncService split. | Per-entity pull strategies. |
| M12 | **Medium** | Code quality | Bill/customer list search catch → empty list (`bill_list_screen.dart` L87–93; web twin) | Search failures look like “no results.” | Surface error state / snackbar. |
| M13 | **Medium** | Code quality | Pervasive `dynamic` PostgREST row mappers | Schema drift fails at runtime. | Typed DTOs for RPC/rows. |
| M14 | **Medium** | UI/UX | `web_theme.dart` / `web_top_bar.dart` hardcoded `Colors.white`/`Colors.blue`; dark theme partial | Dark mode on web is low-contrast / broken. | Tokenize web chrome **or** lock web to light theme. |
| M15 | **Medium** | UI/UX | `web_top_bar.dart` L93–98 | Always shows “Store Owner” subtitle for every role. | Use `roleLabel(...)`. |
| M16 | **Medium** | UI/UX | `ErrorState` / `EmptyState` lack `Semantics(liveRegion)`; dashboards show `…`/`—` on error without retry | A11y + silent dashboard failures; Phase 9 “everywhere” overstated (`tasks.md` L75). | Live regions; `ErrorState(onRetry)` on dashboards. |
| M17 | **Medium** | UI/UX | `adaptive_scaffold.dart` 900px vs `web_tokens.dart` 768px | Conflicting breakpoints. | Shared breakpoint constants. |
| M18 | **Medium** | UI/UX | `BsSuccessButton` no loading spinner; bill save disables without feedback | Poor feedback on slow saves. | Add `loading` param; use consistently. |
| M19 | **Medium** | UI/UX | `web_top_bar.dart` L60–68; settings sync tile on web | Settings gear no-op for non-owners; sync tile misleading on web (sync disabled). | Hide or route correctly; hide sync on web. |
| M20 | **Medium** | UI/UX | Mobile router: single shell route per role (`mobile_router.dart` L63–66) | No deep links for push/share on mobile. | Nested go_router paths or document limitation. |
| M21 | **Medium** | Performance | `notifications_repository.dart` L18–42 unbounded; `billListProvider` unbounded; catalog RPC unbounded; `lowStockCount` client filter; `totalDues` fetches all balances | Scale risks for active tenants. | Paginate/cap; SQL RPCs for aggregates (pattern already used for owner dashboard). |
| M22 | **Medium** | Performance | `product_image.dart` L20–21 signed URL every rebuild | Extra Storage API calls vs messages cache. | Cache signed URLs like messages. |
| M23 | **Medium** | Performance | `sync_pusher.dart` sequential; `sync_service.dart` pull→push→pull | Slow catch-up / extra network. | Batch independent ops; skip second pull when queue empty. |
| M24 | **Medium** | Features | No Sentry/Crashlytics; only `debugPrint` (`main.dart` L16–18) | Production failures invisible. | Add crash reporting for sync/auth/push. |
| M25 | **Medium** | Testing | CI: no integration/E2E; web build only on `main`; release skips tests; no coverage | Gaps between PR signal and ship risk. | PR web smoke build; integration job; coverage on critical paths. |
| M26 | **Medium** | DX | `analysis_options.yaml` default lints only; Windows-only `run_dev.ps1`; empty seed; E2E anon key default; README omits E2E | Onboarding friction and weaker static analysis. | Strict analyzer; bash/`--dart-define-from-file`; seed E2E user; document scripts. |
| L1 | **Low** | Security | Product MIME from client; `reset-member-password` no UUID format check; E2E hardcoded local anon key | Minor validation / hygiene. | Magic-byte check; UUID validate; require env in scripts. |
| L2 | **Low** | Code quality | Direct repo calls from widgets; inconsistent `_requireClient` exception types; providers outside `providers.dart`; empty catch in quote rate lookup | Consistency / discoverability. | Standardize patterns when touching files. |
| L3 | **Low** | UI/UX | Status chip one-off purple; sync badge `Colors.grey`; settings SegmentedButton overflow risk; `AsyncBody` underused; dues aging uses empty state for errors | Polish. | Tokens + shared async wrappers. |
| L4 | **Low** | Testing | Placeholder `demo_data_seeder_test`; empty iOS `RunnerTests`; skipped PDF image test; format scope excludes `integration_test`; `package.json` stub `test`; lockfile gitignored | Noise / reproducibility. | Tighten as needed. |
| L5 | **Low** | Features | Catalog offline copy generic; staff list unpaginated; locale flash before prefs load; web FCM ops-only | Documented or low impact. | Copy / checklist. |
| N1 | **Nitpick** | Architecture | Intentional web→features imports; no dead modules found; no TODO/FIXME clutter; Riverpod fit is good | Clean / intentional. | None. |

---

## Lenses with little to report

| Lens area | Verdict |
|-----------|---------|
| Service-role / secrets in client | Clean — Edge Functions only; `.env*` gitignored; dart-define pattern. |
| Warehouse billing hard rule | Enforced in RLS + `create_bill` role check. |
| XSS in chat | Flutter `Text` rendering — no HTML. |
| features → web imports | None found. |
| Dead Dart modules | Spot-checked modules all have call sites. |
| Money math correctness | Well covered by Dart tests + Postgres business-logic tests. |

---

## Phase 2 — Prioritized remediation plan

### Phase A — Critical correctness & ship blockers *(independently shippable)*
1. **C1** — Fix Android release dart-defines; optionally require CI success before release artifacts.
2. **C2 + H1** — Fix `customer_balances` watermark / balance refresh in sync; add regression tests (ties to H10).
3. **H3 + H4** — Unblock web notifications; fix or remove settings/sync route; hide web-only sync IA (M19).

### Phase B — Security defense-in-depth *(shippable alone)*
1. **H2** — Revoke direct bill/item INSERT; RPC-only creation + pgTAP.
2. **M1 + M2** — Payment RPC + remove legacy `bill_items` sync path.
3. **M3–M5** — Signup rate-limit/captcha direction; chat upload hardening (prod checklist items stay ops).

### Phase C — Launch-hardening honesty *(product/compliance)*
1. **H5** — Phone-aware forgot-password **or** explicit UX that phone users must ask owner.
2. **H6** — Customer own-profile edit (needs product confirmation if deferred).
3. **H7** — Account change-password / delete UI for remaining roles/platforms.
4. Update `tasks.md` checkmarks to match reality (T-101/T-103/Phase 9 polish).

### Phase D — Architecture & maintainability *(no user-facing urgency)*
1. **H8** — Break `data ↔ features` sync/auth cycle; relocate `SyncState`.
2. **H9 + M10** — Split bill forms; share dashboard/list controllers where ROI is clear.
3. **M6–M9, M11–M13** — Layering/consistency cleanups opportunistically.

### Phase E — UX polish & scale *(bounded impact)*
1. **M14–M20, M18** — Web tokens/dark mode decision, role label, loading buttons, a11y live regions, dashboard errors.
2. **M21–M23** — Pagination/RPC for notifications, catalog, dues, low-stock; signed URL cache.

### Phase F — Testing, observability & DX
1. **H10–H12, M25** — Sync/auth/remote tests; CI integration job that fails on skip; seed E2E user.
2. **M24** — Crash reporting.
3. **M26** — Analyzer strictness, cross-platform run script, README E2E section.

---

## Decisions needed from you (before Phase 4)

Flagged where multiple valid approaches exist:

1. **H5 Forgot password for phone users**  
   - **A)** Map phone → synthetic email and send reset mail to that address (may not reach a real inbox), **or**  
   - **B)** Keep email-only self-reset; hide/disable forgot-password for phone identifiers; rely on owner `reset-member-password`.

2. **H6 Customer profile edit**  
   - Implement now (PRD), **or** defer to backlog and amend `product.md` / permissions matrix.

3. **H4 / M19 Web pending-sync settings**  
   - Wire the route anyway (always empty on web), **or** remove the tile (recommended).

4. **M14 Web dark theme**  
   - Fully tokenize dark web UI, **or** force light theme on web and disable the control.

5. **H8 Sync lifecycle refactor**  
   - Extract `core/session` module now (larger diff), **or** minimal fix (move providers only) and leave deeper cleanup for later.

6. **Crash reporting (M24)**  
   - Sentry, Firebase Crashlytics, or defer until post-launch?

7. **Remediation pacing**  
   - Pause for review after each phase (A → B → …), **or** run approved phases back-to-back?

---

## STOP — awaiting approval

No code has been changed. Phase 4 remediation will not start until you explicitly approve.

**Please reply with:**
1. Which remediation phases to proceed with (e.g. `A only`, `A+B+C`, `all`).
2. Answers to the decision items above (at least for the phases you approve).
3. Whether to **pause between phases** or **run approved phases automatically**.
