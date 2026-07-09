# AUDIT_ARCHITECTURE — BusinessSajilo

**Date:** 2026-07-09 (refreshed)  
**Companion:** [AUDIT_INVENTORY.md](AUDIT_INVENTORY.md)  
**Scope:** Current architecture posture after Phase 10–11 hardening. Historical findings that are fixed are listed as closed.

---

## 1. Dimension ratings (current)

| # | Dimension | Rating | Summary |
|---|-----------|--------|---------|
| 1 | Separation of concerns | **Good*** | Clean `data/` / `domain/` / `features/` / `web/`; no `application/` layer by design (providers orchestrate) |
| 2 | Single Responsibility | **Good*** | Sync split into `sync_service` + `sync_puller` + `sync_pusher`; large bill screens remain |
| 3 | Coupling & cohesion | **Good** | `features/` must not import `web/`; side panel lives in `core/ui/` with a thin web-theme wrapper |
| 4 | Scalability (10x) | **Good*** | Sync pull/list paths paged; pickers capped + searchable; `report_dues_aging` RPC |
| 5 | Consistency | **Good** | Dual web/mobile presentation intentional; shared repos/providers |
| 6 | State management | **Good** | Riverpod 3 hand-written Notifiers |
| 7 | Data modeling | **Good** | Postgres + RLS + Drift mirror; paisa integers |
| 8 | API design | **Good** | PostgREST + RPCs + Edge Functions; transactional billing |
| 9 | Security posture | **Good*** | RLS + pgTAP + fail-closed `ALLOWED_ORIGIN`; prod checklist still open |

\*Acceptable for v1; residual items below.

---

## 2. Closed since prior audit

| Former finding | Status |
|----------------|--------|
| Edge CORS default `*` | **Fixed** — all Edge Functions require `ALLOWED_ORIGIN` at boot |
| `SyncService` ~582 LOC god object | **Fixed** — thin orchestrator + `sync_puller` / `sync_pusher` / helpers |
| Unbounded sync bootstrap / fake pagination | **Fixed** — paged pull (`syncPullPageSize`), SQL limit/offset in cached repos |
| Offline N+1 bill items | **Fixed** — batch `isIn` in syncing bills repo |
| Deferred web routes unused | **Fixed** — `deferred as` + `DeferredPage` in `web_router.dart` |
| `google_fonts` runtime fetch | **Fixed** — Inter bundled under `assets/fonts/` |
| CI: no format / soft codegen | **Fixed** — `dart format --set-exit-if-changed` + hard `build_runner` in `ci.yml` |
| `web_sheet_bridge` feature→web leak | **Fixed** — adaptive sheets in `core/ui/` |

---

## 3. Residual gaps (actionable)

### 3.1 Closed in this hardening pass

- Picker providers are family + capped (`kPickerPageSize`) with `query` search on products/customers.
- Customer list search refreshes the pager with server/local `query`.
- `duesAging()` uses `report_dues_aging` RPC (migration 15 + pgTAP).
- Side panel moved to `lib/core/ui/web_side_panel.dart`; web wrapper only applies `WebTheme`.
- Noto Sans Devanagari bundled in `pubspec.yaml` / `assets/fonts/`.

### 3.2 Web FCM stub

- `web/firebase-messaging-sw.js` is an install/activate stub only.
- **Target:** replace when Firebase web secrets are configured; until then document as non-prod (see `docs/SECURITY.md`).

### 3.3 Ops (not in-repo)

- Unchecked items in `docs/SECURITY.md`: captcha, SMTP, key rotation, prod `ALLOWED_ORIGIN`, leaked-password protection.

---

## 4. Intentional non-goals (do not treat as bugs)

- No `lib/application/` use-case layer — feature providers orchestrate.
- Orders / quotes / chat / credit notes / reports remain online-only (no Drift).
- Parallel `lib/web/` presentation layer (accepted duplication for desktop UX).
- Windows runner = desktop-dev / integration only.
- Thermal / ESC/POS printing = backlog.
