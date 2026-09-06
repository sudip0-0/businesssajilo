# BusinessSajilo

**Tapaiko business, sajilo tarika le.**

A multi-platform (Android · iOS · Web) business app for small and medium dealers/distributors in Nepal selling to retailers. Covers inventory, ordering and negotiated quotes, non-VAT billing, credit (udharo), and notifications. Order chat and product categories have been removed.

## Key Features

- **Multi-role login** — Owner, sales, warehouse, and customer accounts. Warehouse may create/view bills but cannot access customer balances, payments, or ledgers.
- **Inventory** — products, stock-in, reasoned adjustments, movement history, low-stock alerts, and CSV/XLSX import.
- **Quote-first ordering** — a price-free customer catalog, orders, versioned quotes, customer acceptance/rejection, and billing. Order states are `placed → received → billed`; billing creates the stock deduction.
- **Simple billing (no VAT)** — itemized invoices, walk-in counter sales, per-business bill numbering.
- **Credit / udharo ledger** — partial payments, running customer balances, dues aging.
- **Offline staff-mobile workflows** — walk-in/customer billing, payments, and stock operations use a persisted sync queue. Order-linked billing, orders, quotes, returns, and reports remain online-only; web/customer apps do not use the offline queue.
- **Bilingual** — English + Nepali UI, BS + AD dates, NPR formatting.
- **Owner dashboard & reports** — sales summaries, outstanding dues, stock valuation.

## Tech Stack

| | |
|---|---|
| App | Flutter (one codebase → Android, iOS, Web), Riverpod, go_router |
| Backend | Supabase (Postgres + RLS, Auth, Realtime, Storage, Edge Functions) |
| Offline | Drift (SQLite) + sync queue on staff mobile |
| Push | Firebase Cloud Messaging |

## Documentation

| File | Contents |
|---|---|
| [product.md](product.md) | Full PRD: personas, roles & permissions, flows, scope, roadmap |
| [Architecture.md](Architecture.md) | System design, data model, RLS, offline sync, project structure |
| [Design.md](Design.md) | Design principles, brand, role-based UX, screen patterns |
| [tasks.md](tasks.md) | Phased implementation task breakdown |
| [Agent.md](Agent.md) | Rules & conventions for AI coding agents working on this repo |

## Getting Started

```bash
# Prereqs: Flutter SDK, Docker Desktop, Supabase CLI (npm i -g supabase)

flutter pub get
supabase start
supabase migration up --local
supabase migration list --local

# Copy keys from `supabase status` into .env.local (see .env.example)
.\scripts\run_dev.ps1          # Windows
# flutter run --dart-define=SUPABASE_URL=http://127.0.0.1:55021 --dart-define=SUPABASE_ANON_KEY=<publishable-key>

flutter analyze && flutter test
supabase test db               # RLS policy tests

# Optional web E2E (requires running web app + local Supabase):
# npm install
# npm run e2e:web
# npm run integration:web   # Windows + Developer Mode; see scripts/
```

**Note:** `.env.local` is read by helper scripts (`scripts/run_dev.ps1`), not by Flutter itself. The app only sees `--dart-define` values. On macOS/Linux, copy defines from `.env.example` into:

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:55021 \
  --dart-define=SUPABASE_ANON_KEY=<publishable-key>
```

## Status

The core workflows, returns, invoice/statement sharing, CSV exports, payment allocation, quote expiry, last-rate memory, tour, search, and notification preferences are implemented. Implementation is not production certification: see [tasks.md](tasks.md) for dated verification and remaining gaps, [docs/LOCAL_TESTING.md](docs/LOCAL_TESTING.md) for reproducible checks, and [docs/SECURITY.md](docs/SECURITY.md) for external setup. Auth/captcha/SMTP, FCM delivery, Sentry ingestion, store submission, and device sign-off require separate verification.

`supabase db reset` deletes local data. It is not required for routine migration/testing and must only be run with explicit approval. Demo/E2E seeds must never be applied to shared or production databases.

## License

Proprietary — all rights reserved (decide before public release).
