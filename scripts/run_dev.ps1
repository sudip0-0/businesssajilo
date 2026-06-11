# Run Flutter against local Supabase. Requires: supabase start, .env.local
$envFile = Join-Path $PSScriptRoot "..\.env.local"
if (-not (Test-Path $envFile)) {
    Write-Error ".env.local not found. Copy .env.example to .env.local and run 'supabase status' for keys."
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        Set-Item -Path "env:$($matches[1].Trim())" -Value $matches[2].Trim()
    }
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_ANON_KEY) {
    Write-Error "SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env.local"
    exit 1
}

$projectRoot = Join-Path $PSScriptRoot ".."
Set-Location $projectRoot

flutter run `
    --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
    --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY `
    @args
