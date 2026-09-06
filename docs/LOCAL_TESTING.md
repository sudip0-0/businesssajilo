# Local testing and hardening

Use the source commands below and record their actual results. A skipped test, a compiled integration, or a successful screenshot is not a completed user journey. See `tasks.md` and `handoff.md` for the latest execution state.

## Safe local database workflow

With Docker Desktop and the Supabase CLI available:

```powershell
supabase start
supabase migration up --local
supabase migration list --local
supabase test db --local
```

The CLI's Local/Remote migration columns refer to the selected local target when `--local` is supplied; they do not prove a hosted deployment.

**Do not reset by default.** `supabase db reset` deletes local data. The hardening script now only resets with `-ResetLocalDatabase` and an exact interactive confirmation, in addition to explicit user approval. Agents must not pass that switch or reset another way without permission.

## Local gate

```powershell
.\scripts\local_hardening_gate.ps1 -SkipOutdated
```

The script checks formatting without rewriting, generates code and l10n, runs analyze, and applies/lists local migrations when Docker/Supabase are available. The full Flutter unit/widget suite runs without backend dart-defines. A separate pass runs the three live repository tests with local `SUPABASE_URL` / `SUPABASE_ANON_KEY` and `HARDENING_GATE=1`; never inject live settings into ordinary unit tests or the plugin-backed web-button VM tests. The gate then runs pgTAP and Deno validation/push-policy tests when available. Missing live configuration or Docker/Supabase/Deno is recorded as SKIP normally and FAIL with `HARDENING_GATE=1`. Each native subcommand's exit status is checked separately. `flutter pub outdated` is informational and does not fail the gate; `-SkipOutdated` skips the network check.

Browser widget and actual-app E2E layers remain separate commands below. They are wired into CI/release quality gates.

Windows detector regression: `powershell.exe -NoProfile -File scripts/local_hardening_gate_supabase_defines_test.ps1`. This uses disposable command fixtures, not real credentials or databases. Successful Docker/Supabase stderr warnings must not abort the gate or make an available service look unavailable; nonzero exit codes still fail detection.

## Dart verification layers

| Layer | Location | External requirements |
|---|---|---|
| Unit/widget, mocked HTTP | `test/`, `test/data/remote_repo_http_test.dart` | Flutter only |
| Sync/recovery/auth | `test/sync_*`, `test/tenant_cache_isolation_test.dart`, `test/auth_*` | Temporary local fixtures; never use real legacy caches in tests |
| UI order/quote/accept/bill | `test/integration/ui_order_to_bill_flow_test.dart` | Deterministic repositories; actual screen pumps, not a bootstrap stub |
| Live order/quote/bill | `test/integration/repository_order_to_bill_test.dart` | Local Supabase, `create-member`, seeded E2E owner |
| Live warehouse privacy/billing | `test/integration/repository_warehouse_billing_test.dart` | Same local services |
| Live concurrent payment allocation | `test/integration/payment_allocation_concurrency_test.dart` | Same local services plus Docker/Postgres lock inspection |
| Browser widgets | `test/support/web_search_test_bootstrap.dart` | Local web build and Playwright; no Supabase credentials |
| Actual-app web smoke | `scripts/e2e_web.mjs` | Served local web build and local Supabase |

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

For relevant model changes, run `flutter gen-l10n` and/or `dart run build_runner build`, then review generated diffs. Do not overwrite unsaved editor buffers while verifying filesystem code; save all and confirm both views match first.

Live integration example (replace placeholders with local configuration only):

```powershell
supabase functions serve
flutter test test/integration/repository_order_to_bill_test.dart --dart-define=SUPABASE_URL=http://127.0.0.1:55021 --dart-define=SUPABASE_ANON_KEY=<local-publishable-key> --dart-define=HARDENING_GATE=1
```

Run the warehouse and payment-concurrency files the same way. `E2E_EMAIL`/`E2E_PASSWORD` dart-defines override the seeded local owner (`e2e-owner@test.com` / `password123`). These tests create accounts and business documents and leave fixtures intact; do not target production or delete fixtures without approval. Missing configuration is a skip in ordinary runs and a failure in strict runs.

## Browser widgets without the broken direct Chrome runner

The direct `flutter test --platform chrome` runner returned CanvasKit JS/Wasm 404s on this Windows setup. The supported alternative builds ordinary Flutter web assets and reads the public integration-test results through a local browser harness:

```powershell
flutter build web --debug --no-web-resources-cdn --no-wasm-dry-run --target=test/support/web_search_test_bootstrap.dart --output=build/web_search_tests
node scripts/run_web_search_tests.mjs
```

This runs real search, shell, warehouse billing, order-role, notification, bill-input, quote-builder, and order-to-bill widgets. The integration callback reports 68 widget results; the imported suites also include four pure tests covered by the normal Flutter runner. Browser fixtures use the production web theme, including its bundled Inter/Devanagari fallbacks. The harness fails on missing widget results, failed assertions, browser errors, or external network requests; its larger bounded timeout accommodates the expanded suites. `pubspec.yaml` aliases Flutter's default `Roboto` family to the existing Inter asset. Test assets and network assertions must not be modified to hide font failures.

## Actual-app browser verification

Build with the explicit local URL and publishable key:

```powershell
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run --output=build/e2e_local --dart-define=SUPABASE_URL=http://127.0.0.1:55021 --dart-define=SUPABASE_ANON_KEY=<local-publishable-key>
python -m http.server 4173 --bind 127.0.0.1 --directory build/e2e_local
```

In another terminal, set `BASE_URL=http://127.0.0.1:4173`, the local `SUPABASE_URL`, and local `SUPABASE_ANON_KEY`, then run `npm run e2e:web`. The runner enables Flutter semantics and verifies actual buttons, sidebar destinations, notification Escape/View All, and persisted EN/NE state. It rejects non-loopback targets, has bounded execution, closes test browsers, and does not convert failed clicks into passes using direct navigation fallbacks.

## Deno, CI and devices

`npm test` runs the configured Deno validation and push-policy suites. Deno must be installed; absence is not a pass. No production FCM delivery is exercised by these unit tests.

CI/release source uses Flutter 3.44.8. Workflows build web without the removed `--web-renderer canvaskit` flag, using `--no-web-resources-cdn --no-wasm-dry-run`. CI runs the build-based browser widget harness and local-resource actual-app E2E; release quality repeats those checks before deployment. Generated sources are verified with `git diff --exit-code` after `gen-l10n` and `build_runner`.

Android and iOS device sign-off is separate from VM/browser widgets. This session had no Android device/emulator and no macOS/iOS toolchain. Record EN/NP, narrow-layout, large-text, keyboard and real printing/share checks on supported devices before release.

## Demo data and gated projection

The local seed scripts define an E2E business plus bulk demo products/customers/bills. Never load them into shared/staging/production databases. Existing local data can be used without a reset; missing fixtures require an explicitly approved setup action.

Live balances remain on `customer_balances`. Do not activate `customer_balance_projections` until `scripts/benchmark_customer_balances.sql` demonstrates acceptable latency and `customer_balance_projection_drift` is zero. No projection activation or production benchmark was performed during this hardening work.
