# Run owner web UI integration tests (widget finders, reliable button taps).
# Requires: Docker (supabase start), Windows desktop target, Developer Mode (symlinks).
param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY,
  [string]$E2eEmail = $env:E2E_EMAIL,
  [string]$E2ePassword = $env:E2E_PASSWORD
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot

$envFile = Join-Path $projectRoot ".env.local"
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
      $name = $matches[1].Trim()
      $value = $matches[2].Trim()
      if (-not (Get-Item -Path "env:$name" -ErrorAction SilentlyContinue)) {
        Set-Item -Path "env:$name" -Value $value
      }
    }
  }
  if (-not $SupabaseUrl) { $SupabaseUrl = $env:SUPABASE_URL }
  if (-not $SupabaseAnonKey) { $SupabaseAnonKey = $env:SUPABASE_ANON_KEY }
}

if (-not $SupabaseUrl -or -not $SupabaseAnonKey) {
  Write-Error "SUPABASE_URL and SUPABASE_ANON_KEY required (env or .env.local)."
}

$defines = @(
  "--dart-define=SUPABASE_URL=$SupabaseUrl",
  "--dart-define=SUPABASE_ANON_KEY=$SupabaseAnonKey",
  "--dart-define=FORCE_WEB_UI=true"
)
if ($E2eEmail) { $defines += "--dart-define=E2E_EMAIL=$E2eEmail" }
if ($E2ePassword) { $defines += "--dart-define=E2E_PASSWORD=$E2ePassword" }

flutter pub get
flutter test integration_test/web_owner_buttons_test.dart -d windows @defines
