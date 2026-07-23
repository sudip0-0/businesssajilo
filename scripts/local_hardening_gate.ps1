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
    [switch]$SkipOutdated
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
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            Record $Name "FAIL" "exit code $LASTEXITCODE"
            return
        }
        Record $Name "PASS"
    } catch {
        Record $Name "FAIL" $_.Exception.Message
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

Write-Host "BusinessSajilo local hardening gate" -ForegroundColor Green
Write-Host "Project: $ProjectRoot"
Write-Host "HARDENING_GATE: $HardeningGate"

Invoke-Step "dart format (check)" {
    dart format --output=none --set-exit-if-changed .
}

Invoke-Step "flutter analyze" {
    flutter analyze
}

Invoke-Step "flutter test" {
    if ($HardeningGate) {
        flutter test --dart-define=HARDENING_GATE=1
    } else {
        flutter test
    }
}

# --- Supabase pgTAP (optional unless gate) ---
$dockerOk = Test-DockerAvailable
$supabaseOk = Test-SupabaseCli

if ($dockerOk -and $supabaseOk) {
    Invoke-Step "supabase db reset + pgTAP" {
        supabase db reset --yes
        supabase test db
    }
} else {
    $detail = "docker=$dockerOk supabase_cli=$supabaseOk"
    if ($HardeningGate) {
        Record "supabase db reset + pgTAP" "FAIL" $detail
    } else {
        Record "supabase db reset + pgTAP" "SKIP" $detail
    }
}

# --- Deno Edge Function unit tests (optional unless gate) ---
if (Test-Command "deno") {
    Invoke-Step "deno test (validation.ts)" {
        deno test supabase/functions/_shared/validation_test.ts --allow-read
    }
} else {
    if ($HardeningGate) {
        Record "deno test (validation.ts)" "FAIL" "deno not installed"
    } else {
        Record "deno test (validation.ts)" "SKIP" "deno not installed"
    }
}

if (-not $SkipOutdated) {
    Invoke-Step "flutter pub outdated" {
        flutter pub outdated
        # Informational only — do not fail gate on outdated packages.
        $global:LASTEXITCODE = 0
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
