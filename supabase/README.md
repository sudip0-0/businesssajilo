# Supabase backend

## Local development (Docker)

Prerequisites: Docker Desktop, Supabase CLI (`npm i -g supabase`).

```bash
supabase start          # starts Postgres, Auth, API, Studio
supabase status         # copy Publishable key → .env.local
supabase db reset       # apply migrations + seed
supabase test db        # RLS policy tests (pgTAP) — also runs in CI
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
| `register-business` | Public | Owner signup: creates auth user + business + owner member (rate-limited via `[auth.rate_limit]` in `config.toml`) |
| `create-member` | Owner JWT | Creates staff/customer login (+ customer profile if role=customer) |
| `notify` | Service role | Sends FCM push for a `notifications` row (optional when FCM not configured) |

### Push notifications (optional)

Set Edge Function secrets on the linked project:

```bash
supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
```

In-app notifications work without FCM. When FCM is configured, either:

1. Rely on the `pg_net` hook from migration `00007` (local default URL), or
2. Create a **Database Webhook** on `notifications` INSERT → `https://<project>.supabase.co/functions/v1/notify` with `Authorization: Bearer <service_role_key>`.

Flutter FCM is also optional — pass Firebase `--dart-define` values documented in `.env.example`.

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
