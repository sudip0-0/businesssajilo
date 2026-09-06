# Local hardening gate — run before release or after major DB/auth/sync changes.
# Does NOT modify CI workflows or deploy configs.
#
# Usage:
#   .\scripts\local_hardening_gate.ps1
#   $env:HARDENING_GATE = "1"; .\scripts\local_hardening_gate.ps1
#
# When HARDENING_GATE=1, skipped optional steps (Docker/Supabase/Deno) fail
# instead of reporting SKIP.

param(
    [switch]$SkipOutdated,
    [switch]$ResetLocalDatabase
)

$ErrorActionPreference = "Stop"
$HardeningGate = ($env:HARDENING_GATE -eq "1")
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $ProjectRoot

$results = @()
$failed = $false

function Write-Step([string]$Name) {
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
}

function Record([string]$Name, [string]$Status, [string]$Detail = "") {
    $script:results += [pscustomobject]@{ Step = $Name; Status = $Status; Detail = $Detail }
    if ($Status -eq "FAIL") { $script:failed = $true }
}

function Invoke-Step([string]$Name, [scriptblock]$Action) {
    Write-Step $Name
    try {
        & $Action
        Record $Name "PASS"
    } catch {
        Record $Name "FAIL" $_.Exception.Message
    }
}

function Invoke-Checked([scriptblock]$Command) {
    $global:LASTEXITCODE = 0
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $Command"
    }
}

function Test-Command([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-DockerAvailable {
    if (-not (Test-Command "docker")) { return $false }
    try {
        docker info *> $null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Test-SupabaseCli {
    return Test-Command "supabase"
}

function Get-LocalSupabaseDartDefines {
    $output = & supabase status -o env 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    $map = @{}
    foreach ($line in $output) {
        if ($line -match '^(API_URL|ANON_KEY|PUBLISHABLE_KEY|SUPABASE_URL|SUPABASE_ANON_KEY)=(.*)$') {
            $map[$matches[1]] = $matches[2].Trim('"').Trim("'")
        }
    }
    $url = $map['SUPABASE_URL']
    if (-not $url) { $url = $map['API_URL'] }
    $key = $map['SUPABASE_ANON_KEY']
    if (-not $key) { $key = $map['ANON_KEY'] }
    if (-not $key) { $key = $map['PUBLISHABLE_KEY'] }
    if (-not $url -or -not $key) { return $null }
    return @{ Url = $url; Key = $key }
}

Write-Host "BusinessSajilo local hardening gate" -ForegroundColor Green
Write-Host "Project: $ProjectRoot"
Write-Host "HARDENING_GATE: $HardeningGate"

if ($ResetLocalDatabase) {
    $confirmation = Read-Host "This deletes ALL local Supabase data. Type RESET LOCAL DATABASE to confirm"
    if ($confirmation -cne 'RESET LOCAL DATABASE') {
        throw 'Local database reset was not confirmed. No gate commands were run.'
    }
}

Invoke-Step "dart format (check)" {
    Invoke-Checked { dart format --output=none --set-exit-if-changed lib test integration_test }
}

Invoke-Step "generated code (build_runner + l10n)" {
    Invoke-Checked { dart run build_runner build --delete-conflicting-outputs }
    Invoke-Checked { flutter gen-l10n }
}

Invoke-Step "flutter analyze" {
    Invoke-Checked { flutter analyze }
}

# --- Supabase (optional unless gate). Apply migrations before Flutter tests
# so live integration files can receive dart-defines in the same run. ---
$dockerOk = Test-DockerAvailable
$supabaseOk = Test-SupabaseCli
$supabaseDefines = $null

if ($dockerOk -and $supabaseOk) {
    Invoke-Step "supabase local migrations" {
        if ($ResetLocalDatabase) {
            Invoke-Checked { supabase db reset --local --yes }
        }
        Invoke-Checked { supabase migration up --local }
        Invoke-Checked { supabase migration list --local }
    }
    $supabaseDefines = Get-LocalSupabaseDartDefines
} else {
    $detail = "docker=$dockerOk supabase_cli=$supabaseOk"
    if ($HardeningGate) {
        Record "supabase local migrations" "FAIL" $detail
    } else {
        Record "supabase local migrations" "SKIP" $detail
    }
}

Invoke-Step "flutter test" {
    $flutterArgs = @()
    if ($HardeningGate) {
        $flutterArgs += "--dart-define=HARDENING_GATE=1"
        if ($dockerOk -and $supabaseOk -and -not $supabaseDefines) {
            throw "Supabase dart-defines unavailable for strict live integration tests"
        }
    }
    if ($supabaseDefines) {
        $flutterArgs += "--dart-define=SUPABASE_URL=$($supabaseDefines.Url)"
        $flutterArgs += "--dart-define=SUPABASE_ANON_KEY=$($supabaseDefines.Key)"
    }
    Invoke-Checked { flutter test @flutterArgs }
}

if ($dockerOk -and $supabaseOk) {
    Invoke-Step "supabase pgTAP" {
        Invoke-Checked { supabase test db --local }
    }
} else {
    $detail = "docker=$dockerOk supabase_cli=$supabaseOk"
    if ($HardeningGate) {
        Record "supabase pgTAP" "FAIL" $detail
    } else {
        Record "supabase pgTAP" "SKIP" $detail
    }
}

# --- Deno Edge Function unit tests (optional unless gate) ---
if (Test-Command "deno") {
    Invoke-Step "deno test (validation.ts)" {
        Invoke-Checked { deno test supabase/functions/_shared/validation_test.ts --allow-read }
        Invoke-Checked { deno test supabase/functions/notify/push_policy_test.ts --allow-read }
    }
} else {
    if ($HardeningGate) {
        Record "deno test (validation.ts)" "FAIL" "deno not installed"
    } else {
        Record "deno test (validation.ts)" "SKIP" "deno not installed"
    }
}

if (-not $SkipOutdated) {
    Write-Step "flutter pub outdated"
    $global:LASTEXITCODE = 0
    try {
        flutter pub outdated
        Record "flutter pub outdated" "PASS" "informational (exit $LASTEXITCODE)"
    } catch {
        Record "flutter pub outdated" "PASS" "informational (command error: $($_.Exception.Message))"
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

if ($failed) {
    Write-Host "HARDENING GATE FAILED" -ForegroundColor Red
    exit 1
}

Write-Host "HARDENING GATE PASSED" -ForegroundColor Green
exit 0
