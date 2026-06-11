# Supabase backend

## Local development (Docker)

Prerequisites: Docker Desktop, Supabase CLI (`npm i -g supabase`).

```bash
supabase start          # starts Postgres, Auth, API, Studio
supabase status         # copy Publishable key → .env.local
supabase db reset       # apply migrations + seed
supabase test db        # RLS policy tests (pgTAP)
supabase functions serve  # hot-reload Edge Functions (optional)
supabase stop           # tear down containers
```

- **Studio:** http://127.0.0.1:54323
- **API:** http://127.0.0.1:54321
- **DB:** `postgresql://postgres:postgres@127.0.0.1:54322/postgres`

Copy `.env.example` → `.env.local` and fill keys from `supabase status`.

Run Flutter against local stack:

```powershell
.\scripts\run_dev.ps1
# or: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Edge Functions

| Function | Auth | Purpose |
|---|---|---|
| `register-business` | Public | Owner signup: creates auth user + business + owner member |
| `create-member` | Owner JWT | Creates staff/customer login (+ customer profile if role=customer) |

## Conventions

- All schema changes are migration files in `migrations/` — never edit the dashboard schema directly.
- Every tenant table ships with RLS policies + `FORCE ROW LEVEL SECURITY` in the same migration.
- RLS tests live in `tests/`; run with `supabase test db`.

## Remote (production)

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```
