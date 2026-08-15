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

$androidPackage = "com.businesssajilo.businesssajilo"

function Get-FlutterDeviceId {
    param([string[]]$RunArgs)
    for ($i = 0; $i -lt $RunArgs.Count; $i++) {
        $arg = $RunArgs[$i]
        if ($arg -eq "-d" -or $arg -eq "--device-id") {
            if ($i + 1 -lt $RunArgs.Count) { return $RunArgs[$i + 1] }
        }
        if ($arg -match "^--device-id=(.+)$") { return $Matches[1] }
    }
    return $null
}

function Invoke-Adb {
    param(
        [string]$Serial,
        [string[]]$AdbArgs
    )
    $prefix = @()
    if ($Serial) { $prefix = @("-s", $Serial) }
    & adb @prefix @AdbArgs 2>$null
}

function Enable-AndroidDebugKeepAlive {
    param([string]$Serial)

    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if (-not $adb) { return }

    # Android 12+ kills Flutter's extra Dart VM ("phantom process") when the
    # app is backgrounded or during hot reload. That shows up as
    # "Lost connection to device." These settings reset on reboot, so apply
    # them every run.
    Invoke-Adb $Serial @(
        "shell", "device_config", "put", "activity_manager",
        "max_phantom_processes", "2147483647"
    ) | Out-Null
    Invoke-Adb $Serial @(
        "shell", "settings", "put", "global",
        "settings_enable_monitor_phantom_procs", "false"
    ) | Out-Null
    Invoke-Adb $Serial @(
        "shell", "settings", "put", "global", "stay_on_while_plugged_in", "7"
    ) | Out-Null
    Invoke-Adb $Serial @(
        "shell", "settings", "put", "global", "always_finish_activities", "0"
    ) | Out-Null
    Invoke-Adb $Serial @(
        "shell", "settings", "put", "global", "wifi_sleep_policy", "2"
    ) | Out-Null
    Invoke-Adb $Serial @(
        "shell", "dumpsys", "deviceidle", "whitelist", "+$androidPackage"
    ) | Out-Null
    foreach ($op in @("RUN_IN_BACKGROUND", "RUN_ANY_IN_BACKGROUND", "WAKE_LOCK")) {
        Invoke-Adb $Serial @("shell", "cmd", "appops", "set", $androidPackage, $op, "allow") | Out-Null
    }
}

$deviceId = Get-FlutterDeviceId -RunArgs @($args)
$adb = Get-Command adb -ErrorAction SilentlyContinue
if ($adb) {
    Enable-AndroidDebugKeepAlive -Serial $deviceId
    Write-Host "Android debug keep-alive applied (phantom-process limit, battery whitelist, stay awake)."
    Write-Host "Leave BusinessSajilo in the foreground during hot reload; OEM battery savers can still kill the session."
}

# A physical phone's 127.0.0.1 is the phone, not this PC. Reverse the API port
# over USB so local Supabase stays reachable without changing .env.local.
if ($env:SUPABASE_URL -match 'https?://(127\.0\.0\.1|localhost):(\d+)') {
    $apiPort = $Matches[2]
    if ($adb) {
        Invoke-Adb $deviceId @("reverse", "tcp:$apiPort", "tcp:$apiPort") | Out-Host
    }
}

flutter run `
    --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
    --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY `
    --dart-define=SENTRY_DSN=$($env:SENTRY_DSN) `
    @args
