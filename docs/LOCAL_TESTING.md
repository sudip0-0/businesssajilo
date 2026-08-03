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
| `dart format --set-exit-if-changed` | Yes | Same as CI |
| `flutter analyze` | Yes | Zero warnings policy |
| `flutter test` | Yes | Passes `--dart-define=HARDENING_GATE=1` when gate is on |
| `supabase db reset` + `supabase test db` | Optional* | Needs Docker + Supabase CLI |
| `deno test supabase/functions/_shared/validation_test.ts` | Optional* | Edge Function input helpers |
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

## Known gaps (honest)

- Two widget test files currently fail to compile (`dashboard_scoped_queries_test.dart`, `offline_query_scale_test.dart`) — repair before treating the gate as fully green.
- UI order→quote→bill flow is documented but not fully pumped through screens yet (`ui_order_to_bill_flow_test.dart`).
- Deno is not installed by default on Windows; install from [deno.land](https://deno.land) for Edge Function unit tests locally.
