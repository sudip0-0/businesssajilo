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

ANDROID_PACKAGE="com.businesssajilo.businesssajilo"

device_id=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[$i]}" in
    -d|--device-id)
      if (( i + 1 < ${#args[@]} )); then
        device_id="${args[$((i + 1))]}"
      fi
      ;;
    --device-id=*)
      device_id="${args[$i]#--device-id=}"
      ;;
  esac
done

adb_cmd() {
  if [[ -n "$device_id" ]]; then
    adb -s "$device_id" "$@"
  else
    adb "$@"
  fi
}

enable_android_debug_keep_alive() {
  command -v adb >/dev/null 2>&1 || return 0
  # Android 12+ kills Flutter's extra Dart VM ("phantom process") when the
  # app is backgrounded or during hot reload → "Lost connection to device."
  adb_cmd shell device_config put activity_manager max_phantom_processes 2147483647 >/dev/null 2>&1 || true
  adb_cmd shell settings put global settings_enable_monitor_phantom_procs false >/dev/null 2>&1 || true
  adb_cmd shell settings put global stay_on_while_plugged_in 7 >/dev/null 2>&1 || true
  adb_cmd shell settings put global always_finish_activities 0 >/dev/null 2>&1 || true
  adb_cmd shell settings put global wifi_sleep_policy 2 >/dev/null 2>&1 || true
  adb_cmd shell dumpsys deviceidle whitelist "+$ANDROID_PACKAGE" >/dev/null 2>&1 || true
  for op in RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND WAKE_LOCK; do
    adb_cmd shell cmd appops set "$ANDROID_PACKAGE" "$op" allow >/dev/null 2>&1 || true
  done
  echo "Android debug keep-alive applied (phantom-process limit, battery whitelist, stay awake)."
  echo "Leave BusinessSajilo in the foreground during hot reload; OEM battery savers can still kill the session."
}

enable_android_debug_keep_alive

if [[ "${SUPABASE_URL}" =~ https?://(127\.0\.0\.1|localhost):([0-9]+) ]]; then
  api_port="${BASH_REMATCH[2]}"
  if command -v adb >/dev/null 2>&1; then
    adb_cmd reverse "tcp:${api_port}" "tcp:${api_port}" || true
  fi
fi

flutter run \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
  --dart-define="SENTRY_DSN=${SENTRY_DSN:-}" \
  "$@"
