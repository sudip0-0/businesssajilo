# BusinessSajilo

**Tapaiko business, sajilo tarika le.**

A multi-platform (Android · iOS · Web) business app for small and medium dealers/distributors in Nepal selling to retailers. Replaces copy books, Viber orders, and Excel with one app: inventory, ordering & quotes, simple non-VAT billing, credit (udharo) tracking, and customer messaging.

## Key Features

- **Multi-role login** — Business Owner, Sales Person, Warehouse Manager, and Customer (retailer) accounts, each with a purpose-built home screen and strict access control (e.g. warehouse can never bill).
- **Inventory** — products, categories, stock-in, adjustments, low-stock alerts.
- **Quote-first ordering** — customers browse the catalog (no prices), place orders; sales sends a quote; customer accepts; warehouse packs & dispatches; bill is generated.
- **Simple billing (no VAT)** — itemized invoices, walk-in counter sales, per-business bill numbering.
- **Credit / udharo ledger** — partial payments, running customer balances, dues aging.
- **Order chat** — message threads tied to each order/quote, with push notifications.
- **Offline-first staff app** — billing, payments, and stock ops work without internet and sync later.
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
supabase db reset

# Copy keys from `supabase status` into .env.local (see .env.example)
.\scripts\run_dev.ps1          # Windows
# flutter run --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_ANON_KEY=<publishable-key>

flutter analyze && flutter test
supabase test db               # RLS policy tests
```

## Status

Phases 0–10 complete: full v1 (auth/roles, inventory, ledger, billing, orders/quotes/chat, notifications, offline sync, reports, release polish) plus credit notes, invoice PDF/image export, and report CSV export. Current work: Phase 11 — Launch Hardening (password reset, phone login, account deletion, reorder, statement share, registration captcha) — see [tasks.md](tasks.md).

## License

Proprietary — all rights reserved (decide before public release).
