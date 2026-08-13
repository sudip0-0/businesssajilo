#!/usr/bin/env bash
# Run Flutter against local Supabase. Requires: supabase start, .env.local
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env.local"
if [[ ! -f "$ENV_FILE" ]]; then
  echo ".env.local not found. Copy .env.example to .env.local and run 'supabase status' for keys." >&2
  exit 1
fi
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a
if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env.local" >&2
  exit 1
fi
cd "$ROOT"
flutter run \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
  --dart-define="SENTRY_DSN=${SENTRY_DSN:-}" \
  "$@"
