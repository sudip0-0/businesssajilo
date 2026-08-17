# Local testing & hardening gate

Run this before release candidates or after migrations / auth / sync changes.

## Quick start (Windows)

```powershell
# Optional: load Supabase keys from .env.local
Copy-Item .env.example .env.local   # if needed
.\scripts\run_dev.ps1 --help       # see run_dev for dart-defines

# Full local gate (skips Docker/Deno when unavailable)
.\scripts\local_hardening_gate.ps1

# Strict mode — skipped optional steps become failures
$env:HARDENING_GATE = "1"
.\scripts\local_hardening_gate.ps1
```

## What the gate runs

| Step | Required | Notes |
|------|----------|-------|
| `dart format --set-exit-if-changed` | Yes | Same as CI (`lib test integration_test`) |
| `dart run build_runner build` | Yes | Regenerates Drift/Freezed before analyze |
| `flutter analyze` | Yes | Zero warnings policy |
| `flutter test` | Yes | Passes `--dart-define=HARDENING_GATE=1` when gate is on |
| `supabase db reset` + `supabase test db` | Optional* | Needs Docker + Supabase CLI; includes QoL filter + balance-projection pgTAP |
| `deno test` validation + `notify/push_policy_test.ts` | Optional* | Edge Function input helpers and FCM push policy |
| `flutter pub outdated` | Informational | Never fails the gate |

\*Fails when `HARDENING_GATE=1` and Docker/Supabase/Deno is missing.

## Flutter test layers

| Layer | Location | Needs local Supabase |
|-------|----------|----------------------|
| Unit / widget | `test/` | No |
| HTTP remote repo contracts | `test/data/remote_repo_http_test.dart` | No (mock HTTP) |
| Sync strategy | `test/sync_strategy_test.dart`, `test/sync_*` | No |
| Auth lifecycle | `test/auth_repository_test.dart`, `test/auth_provider_test.dart` | No |
| Repository integration | `test/integration/repository_order_to_bill_test.dart` | Yes — skips if unreachable |
| UI integration stub | `test/integration/ui_order_to_bill_flow_test.dart` | Yes — bootstrap only; extend with screen pumps |

Integration tests expect seeded E2E owner (`e2e-owner@test.com` / `password123`) after `supabase db reset`.

macOS / Linux: `scripts/run_dev.sh` (same dart-defines as `run_dev.ps1`).

## Bulk demo data (E2E owner)

`supabase db reset` also loads [`supabase/seeds/e2e_bulk_demo.sql`](../supabase/seeds/e2e_bulk_demo.sql): **55 products**, **55 customers**, **220 bills** for the E2E business. The script is idempotent (skips when ≥50 products already exist).

**Full reset (clean slate + seed):**

```powershell
npx supabase db reset
```

**Populate without wiping** (local DB already running with the E2E owner):

```powershell
Get-Content supabase\seeds\e2e_bulk_demo.sql -Raw |
  docker exec -i supabase_db_businesssajilo psql -U postgres -v ON_ERROR_STOP=1
```

**Verify counts:**

```powershell
docker exec -i supabase_db_businesssajilo psql -U postgres -c @"
select
  (select count(*) from products where business_id = 'e2e00000-0000-4000-8000-000000000010') as products,
  (select count(*) from customers where business_id = 'e2e00000-0000-4000-8000-000000000010') as customers,
  (select count(*) from bills where business_id = 'e2e00000-0000-4000-8000-000000000010') as bills;
"@
```

## Environment variables

| Variable | Purpose |
|----------|---------|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Dart-defines for integration tests |
| `E2E_EMAIL`, `E2E_PASSWORD` | Override seeded owner credentials |
| `HARDENING_GATE=1` | Fail instead of skip for optional steps |
| `SENTRY_TRACES_SAMPLE_RATE` | Optional 0–1 Sentry tracing rate (default 0.1) |

## CI layers

GitHub Actions (`ci.yml`, Flutter **3.44.8**) runs format, generated-code, analyze, unit/widget tests, Deno tests, pgTAP, and Playwright web E2E (`scripts/e2e_web.mjs`) against a local Supabase + CanvasKit web build. `release.yml` runs the same quality gates before `supabase db push` / function deploy / app builds, then a post-build smoke check.

Local Playwright (needs a served web build + running Supabase):

```powershell
npm test                          # Deno Edge Function tests
npm run e2e:web                   # requires BASE_URL + SUPABASE_ANON_KEY
```

## Customer-balance projection (gated)

Live reads stay on `customer_balances`. Migration 37 adds `customer_balance_projections` plus `customer_balance_projection_drift` for parity checks. Do not switch repository reads until `scripts/benchmark_customer_balances.sql` shows acceptable latency **and** drift is zero. Rollback is to keep reading the view.

```powershell
Get-Content scripts\benchmark_customer_balances.sql -Raw |
  docker exec -i supabase_db_businesssajilo psql -U postgres
```

## Known gaps (honest)

- UI order→quote→bill flow is documented but not fully pumped through screens yet (`ui_order_to_bill_flow_test.dart`).
- Deno is not installed by default on Windows; install from [deno.land](https://deno.land) for Edge Function unit tests locally.
- Customer-balance projection is additive and unused by the app until the benchmark gate passes.
