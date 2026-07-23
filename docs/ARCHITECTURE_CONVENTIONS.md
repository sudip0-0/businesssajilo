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
- Initial bootstrap is resumable: page/duration budgets persist `bootstrap_table` + `bootstrap_offset` in `syncMeta`; table watermarks advance only after that table completes.
- Credit notes (online-only) update `customer_balances.updated_at` on the server; the customers delta pull in `SyncPuller` upserts revised `balance_due` into Drift.
- Local verification: `test/sync_strategy_test.dart` covers watermark deferral, bootstrap resume offsets, bill-before-payment ordering, legacy queue rejection.

## Local hardening gate

See `docs/LOCAL_TESTING.md` and `scripts/local_hardening_gate.ps1`. Set `HARDENING_GATE=1` to treat missing Docker/Deno as failures instead of skips.

## Screen-size guidance

- Use `BsBreakpoints` / `BsTouchTargets` from `lib/core/` once available; avoid scattering raw `480`/`768`/`900`/`1024` literals in feature code.
- Mobile primary controls: ≥ 48dp. Compact web pointer targets: ≥ 40px (44px on touch-capable compact web).
