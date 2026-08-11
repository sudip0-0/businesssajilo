# Agent.md — AI Agent Instructions for BusinessSajilo

Instructions for AI coding agents working on this repository. Read `product.md`, `Architecture.md`, `Design.md`, and `tasks.md` before making changes; they are the source of truth.

## Project Snapshot

- Multi-tenant SaaS for Nepali dealers/distributors: inventory, quote-first ordering, non-VAT billing, credit (udharo) ledger, order chat.
- **Stack:** Flutter (Android/iOS/Web, single codebase) + Supabase (Postgres/RLS, Auth, Realtime, Storage, Edge Functions) + FCM. Offline-first via Drift on staff mobile only.
- Roles: `owner`, `sales`, `warehouse`, `customer`. Permission matrix in `product.md` §4 — enforce in RLS first, UI second.

## Hard Rules (never violate)

1. **Warehouse must never view customer balance or ledger** — DB-enforced (no `customer_balances` / payments / dues access). Warehouse **may** create and view bills.
2. Every tenant table has `business_id` with an RLS policy; never query across tenants.
3. Only the Owner creates customer/staff credentials, via the `create-member` Edge Function. Service role key never reaches client code.
4. `stock_movements`, `payments`, `messages` are **append-only** — no UPDATE/DELETE; corrections are new compensating rows.
5. Bills are immutable after creation (item snapshots); changes go through returns/credit notes (v1.1).
6. No VAT/tax logic in v1. Don't add tax fields speculatively.
7. All user-facing strings go through ARB l10n (EN + NP). No hardcoded text.
8. Client-generated UUID primary keys for offline-capable entities; all sync upserts idempotent.

## Conventions

- **State management:** Riverpod 3 with hand-written `Notifier`/`AsyncNotifier` providers — **no riverpod codegen** (riverpod_generator conflicts with drift_dev on analyzer versions). Navigation: go_router with role-based redirects.
- **Models:** freezed + json_serializable. Enums for `Role`, `OrderStatus`, `BillStatus`, `PaymentMethod` — match Postgres enums exactly.
- **Layering:** features depend on repositories (interfaces in `lib/data/repositories/`); repository implementations choose remote vs local+sync. Never call `supabase_flutter` directly from widgets.
- **DB changes:** only via migration files in `supabase/migrations/` (Supabase CLI). Every new table ships with RLS policies + policy tests in the same migration/PR. After writing a migration, **always** apply it to local Supabase in the same turn (`supabase migration up --local`) — see “After database change or creation”.
- **Money:** integer paisa or `NUMERIC` in DB; format with `MoneyText`/money formatter (Nepali grouping). Never use doubles for currency math.
- **Dates:** store UTC timestamps; display via BS/AD utils in `core/`.
- **Order state machine:** transitions only through the defined pipeline (product.md §5.1); validate transitions server-side (trigger or Edge Function).

## Workflow

- Pick tasks from `tasks.md`, respect phase order; mark items ✅ when completed.
- Run `flutter analyze` and `flutter test` before considering a task done; zero analyzer warnings.
- For a full local pre-release check, run `scripts/local_hardening_gate.ps1` (see `docs/LOCAL_TESTING.md`). Set `HARDENING_GATE=1` to fail on missing Docker/Deno instead of skipping.
- For DB/RLS/permission changes: run `supabase test db` and add or update a per-role test proving both the allow and the deny path.
- Test on at least Android + Web for any UI change (layouts must be responsive).
- Keep diffs focused; don't refactor unrelated code in feature PRs.
- Don't add dependencies without need; prefer the ones already listed in Architecture.md §1.

## Gotchas

- Offline bill numbers are provisional (`D{n}-{seq}`) until the server assigns the final per-business sequence — never assume `bill_no` is final on a pending record.
- Stock level is derived from movements (cached column maintained by trigger) — never set stock directly.
- Quotes are versioned; a re-quote creates a new `quotes` row, old versions stay for history.
- Customer app shows **no prices** in the catalog — prices appear only inside quotes/bills.
- Devanagari strings are longer than English — test layouts in Nepali locale.

## After database change or creation

Whenever you add or edit files under `supabase/migrations/`:

1. Apply them to **local** Supabase immediately — do not wait for the user to ask:
   ```bash
   supabase migration up --local
   ```
2. Confirm with `supabase migration list --local` that the new version appears in both Local and Remote columns.
3. If local Supabase is not running, start it (`supabase start`) then run step 1.
4. For DB/RLS/permission changes, also run `supabase test db` (and add/update per-role allow+deny tests) as in Workflow above.

Never leave a new migration unapplied on the local DB at the end of a turn.
