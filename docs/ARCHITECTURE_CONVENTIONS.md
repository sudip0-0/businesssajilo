# Architecture conventions

Local hardening conventions for BusinessSajilo. Keep layers directional and repositories uniform.

## Allowed import directions

```
lib/domain  → (nothing under lib/)
lib/data    → domain, core (no features/, no web/)
lib/core    → domain only (no features/, no data/feature providers, no web/)
lib/features→ core, data, domain (no web/)
lib/web     → features, core, data, domain
```

- Never import `lib/web/` from `lib/features/` or `lib/core/`.
- Never import feature providers from reusable `lib/core/` modules. Pass data in, or put orchestration under `lib/features/`.

## Repository shape

- Interfaces + Riverpod providers live in `lib/data/repositories/`.
- Supabase implementations live in `lib/data/remote/supabase_*.dart`.
- Cached/offline wrappers live in `lib/data/sync/cached_*.dart` and take a remote implementation plus Drift DB.
- **Exception:** `AuthRepository` may talk to the Supabase Auth SDK directly (session lifecycle). Do not force an auth remote split unless provider tests require it.

## Error handling

- Prefer throwing / converting to `AppFailure`.
- Snackbar writes: `runSubmitAction`.
- Inline field forms (login / register / change-password): `runInlineFormAction`.
- Never map failed searches to empty lists — surface an error state with retry.

## Sync lifecycle

- Active Drift + `SyncService` are owned by `SyncBundleRegistry`.
- `bootstrapSyncForSession` / `disposeSyncBundle` replace or clear the registry and bump `syncBundleVersionProvider`.
- Tenant switches must dispose the previous bundle before opening a new one.
- Staff mobile restores the last cached member when Supabase is unreachable, then opens Drift immediately so previously synced rows are usable offline.
- While the host is down, `SyncService` retries on a 5s/15s/30s/60s reachability backoff (Wi-Fi up + Docker down does not fire connectivity events).
- Offline bills send `created_at` on `create_bill` / `record_customer_sale` so delayed sync does not move the sale to today.
- Initial bootstrap is resumable: page/duration budgets persist `bootstrap_table` + `bootstrap_offset` in `syncMeta`; table watermarks advance only after that table completes.
- Credit notes (online-only) update `customer_balances.updated_at` on the server; the customers delta pull in `SyncPuller` upserts revised `balance_due` into Drift.
- Local verification: `test/sync_strategy_test.dart` covers watermark deferral, bootstrap resume offsets, bill-before-payment ordering, legacy queue rejection.
- Independent `payment` and `stock_movement` queue items may be pushed in parallel batches of 4; bills stay sequential.

## Dual UI

New billing and payment work belongs in `lib/features/` (`BillFormDraft`, `PaymentAllocation`, `recordCustomerPayment`) with thin `lib/web/` views. Do not copy those flows into `lib/web/features/` as a second source of truth.

## Reports

Dashboard KPIs, dues aging, and `total_dues` use RPCs. Client-side folds of already-fetched report rows (chart totals, stock valuation sums) are UI-only — do not add extra list-then-sum round trips.

## Local hardening gate

See `docs/LOCAL_TESTING.md` and `scripts/local_hardening_gate.ps1`. Set `HARDENING_GATE=1` to treat missing Docker/Deno as failures instead of skips.

## Screen-size guidance

- Use `BsBreakpoints` / `BsTouchTargets` from `lib/core/` once available; avoid scattering raw `480`/`768`/`900`/`1024` literals in feature code.
- Mobile primary controls: ≥ 48dp. Compact web pointer targets: ≥ 40px (44px on touch-capable compact web).
