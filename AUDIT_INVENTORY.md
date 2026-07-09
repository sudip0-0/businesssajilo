# AUDIT_INVENTORY — BusinessSajilo

**Date:** 2026-07-09 (refreshed)  
**Project:** BusinessSajilo  
**Stack:** Flutter (Android / iOS / Web; Windows desktop-dev) + Riverpod 3 + Drift/SQLite + Supabase + FCM  
**Repo:** `c:\Users\sudip\Desktop\Projects\businesssajilo`

---

## 1. Project structure

| Path | Purpose |
|------|---------|
| `lib/` | Dart application code (~497 `.dart` files) |
| `lib/core/` | Theme, l10n, router, shared UI, invoicing, export, config |
| `lib/domain/` | Freezed models + enums (no use-case services) |
| `lib/data/local/` | Drift SQLite schema + mappers |
| `lib/data/remote/` | Supabase repository implementations |
| `lib/data/repositories/` | Abstract interfaces + Riverpod wiring (~17 repos) |
| `lib/data/sync/` | Offline queue, puller/pusher, cached/syncing decorators |
| `lib/features/` | Mobile screens + feature providers |
| `lib/web/` | Web-only pages, layout, theme, router |
| `supabase/` | 15 migrations, seed, 15 pgTAP suites, 5 Edge Functions |
| `android/`, `ios/`, `web/`, `windows/` | Platform shells |
| `test/` | Unit/widget tests (~42 Dart files) |
| `integration_test/` | Device/web integration tests (manual / local scripts) |
| `scripts/` | `run_dev.ps1`, integration/e2e helpers |
| `docs/` | Security, dependencies, release copy |
| `.github/workflows/` | `ci.yml` + `release.yml` |

**Not present:** `linux/`, `macos/`, `melos`, `Makefile`, dedicated `backend/` (backend is `supabase/`).

---

## 2. Entry points

| Entry | Path | Role |
|-------|------|------|
| Bootstrap | `lib/main.dart` | Binding, env check, PushService, Supabase init, `ProviderScope` |
| Root widget | `lib/app.dart` | `MaterialApp.router`, theme/locale, push handlers |
| Router switch | `lib/core/router/router_provider.dart` | Web if `kIsWeb \|\| Env.forceWebUi`, else mobile |
| Mobile routes | `lib/core/router/mobile_router.dart`, `role_routes.dart` | Role-aware routes + shells |
| Web routes | `lib/web/router/web_router.dart`, `web_role_routes.dart` | Nested URL routes + deferred pages |
| Web HTML | `web/index.html` | Loads `flutter_bootstrap.js` |
| Web FCM SW | `web/firebase-messaging-sw.js` | Stub until prod Firebase web config |

---

## 3. Config & build tooling

| File | Purpose |
|------|---------|
| `pubspec.yaml` / `pubspec.lock` | SDK `^3.11.5`; Inter fonts bundled; see `docs/DEPENDENCIES.md` |
| `analysis_options.yaml` | `package:flutter_lints/flutter.yaml` |
| `l10n.yaml` | ARB → `lib/core/l10n/` |
| `build.yaml` | `json_serializable`: snake_case, `explicit_to_json` |
| `.env.example`, `.env.prod.example` | dart-define templates |
| `lib/core/config/env.dart` | Secrets via `fromEnvironment` |
| `vercel.json` | SPA rewrite → `index.html` |
| `supabase/config.toml` | Local Supabase stack |
| `.github/workflows/ci.yml` | format + gen-l10n + build_runner + analyze + test + `supabase test db`; web build on `main` |
| `.github/workflows/release.yml` | Tag: web + Android AAB; optional Vercel |

**Build commands:** `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web/appbundle`, `dart run build_runner build`, `flutter gen-l10n`, `supabase start` / `db reset` / `test db`.

---

## 4. Architecture pattern

**Hybrid: layered folders + feature modules + parallel web presentation.**

- Repository abstraction with dual impl via `syncBundleProvider` for bills/payments/stock/products/customers.
- Offline only for mobile staff: `syncEnabledFor()` in `lib/data/sync/sync_config.dart`.
- **No** `lib/application/` layer — feature providers orchestrate (documented in `Architecture.md`).
- Role shells: `lib/features/shell/`, `lib/web/shell/`.

---

## 5. Dependencies (highlights)

See [`docs/DEPENDENCIES.md`](docs/DEPENDENCIES.md) for locked versions.

- **Present:** supabase_flutter, flutter_riverpod, go_router, drift, firebase_*, pdf/printing/share_plus, image, nepali_utils, Inter assets.
- **Absent:** `google_fonts` (removed; Inter bundled), riverpod_generator (analyzer conflict with drift_dev).

---

## 6. Tests & CI

| Suite | Location | In CI? |
|-------|----------|--------|
| Unit/widget | `test/` (~42 files) | Yes (`flutter test`) |
| pgTAP RLS | `supabase/tests/` (14 files) | Yes (`supabase test db`) |
| Integration | `integration_test/`, `test/integration/` | No (local scripts) |
| Playwright E2E | `scripts/e2e_web.mjs` | No |

---

## 7. Security inventory

- RLS + FORCE RLS on tenant tables; helpers `current_business_id()` / `current_role_name()`.
- Edge Functions: `register-business`, `create-member`, `reset-member-password`, `delete-account`, `notify` — fail closed without `ALLOWED_ORIGIN`.
- Client secrets: `--dart-define` only; Drift cache plaintext on device; tenant wipe on business switch.
- Prod checklist: [`docs/SECURITY.md`](docs/SECURITY.md) (unchecked ops items).

---

## 8. Residual inventory gaps

1. Web FCM stub; integration/E2E not in CI.
2. iOS IPA not in release workflow.
3. Prod Auth ops checklist (`docs/SECURITY.md`) still open.
