# Supabase backend

## Setup

```bash
npm i -g supabase            # or scoop install supabase
supabase init                # once, if config.toml is missing
supabase login
supabase link --project-ref <your-project-ref>
supabase db push             # apply migrations
```

## Conventions

- All schema changes are migration files in `migrations/` — never edit the dashboard schema directly.
- Every tenant table ships with RLS policies in the same migration (see Agent.md hard rules).
- Edge Functions live in `functions/` (added in Phase 1: `create-member`, later `notify`).
