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
| `reset-member-password` | Owner JWT | Temporary password + forced change |
| `delete-account` | Member JWT | Self-anonymize or owner business purge |
| `notify` | Service role | Sends FCM push for a `notifications` row (optional when FCM not configured) |

All Edge Functions **require** `ALLOWED_ORIGIN` (no default). Unset → function fails at boot.

Local serve example:

```bash
# PowerShell
$env:ALLOWED_ORIGIN="http://localhost:3000"
supabase functions serve

# bash
ALLOWED_ORIGIN=http://localhost:3000 supabase functions serve
```

Production:

```bash
supabase secrets set ALLOWED_ORIGIN=https://your-app.example.com
```

For local-only CORS during development you may use `ALLOWED_ORIGIN=*`, but production must use the real app origin(s).

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

Release tags (`v*`) run `supabase link` → `db push` → `functions deploy`
automatically when the GitHub secrets `SUPABASE_ACCESS_TOKEN`,
`SUPABASE_PROJECT_REF`, and `SUPABASE_DB_PASSWORD` are set (see
`.github/workflows/release.yml`). Manual fallback:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
supabase functions deploy
```

### Migration rollback policy

- **Forward-fix only.** We do not ship down-migrations; reverting a
  bad deploy means shipping a new migration that undoes or repairs the
  previous change.
- **Expand–contract** for breaking schema changes: add the new
  column/table first (expand), dual-write / migrate readers, then drop
  the old shape in a later release (contract). Never rename or drop a
  live column in the same migration that apps still depend on.
- Keep `supabase/tests/` pgTAP coverage green before tagging a release.
