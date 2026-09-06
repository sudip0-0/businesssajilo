$ErrorActionPreference = 'Stop'
$failed = 0
$passed = 0

function Write-CaseResult([bool]$Ok, [string]$Name) {
    if ($Ok) {
        $script:passed++
        Write-Host "PASS $Name"
    } else {
        $script:failed++
        Write-Host "FAIL $Name"
    }
}

function Get-ExtractedFunction([string]$Path, [string]$Name) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        throw "Failed to parse $Path"
    }
    $funcAst = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $Name
    }, $true) | Select-Object -First 1
    if (-not $funcAst) {
        throw "Function $Name was not found"
    }
    return $funcAst.Extent.Text
}

$gatePath = Join-Path $PSScriptRoot 'local_hardening_gate.ps1'
Invoke-Expression (Get-ExtractedFunction $gatePath 'Test-Command')
Invoke-Expression (Get-ExtractedFunction $gatePath 'Test-DockerAvailable')
Invoke-Expression (Get-ExtractedFunction $gatePath 'Get-LocalSupabaseDartDefines')

$stubDir = Join-Path ([System.IO.Path]::GetTempPath()) ('bs-gate-supabase-stub-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stubDir | Out-Null
$stubCmd = Join-Path $stubDir 'supabase.cmd'
$dockerCmd = Join-Path $stubDir 'docker.cmd'
$originalPath = $env:PATH

function Set-SupabaseStub {
    param(
        [string[]]$StdoutLines,
        [int]$ExitCode = 0,
        [string]$StderrLine = 'Stopped services: [supabase_imgproxy_businesssajilo supabase_pooler_businesssajilo]'
    )
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('@echo off')
    foreach ($stdoutLine in $StdoutLines) {
        [void]$lines.Add('echo ' + $stdoutLine)
    }
    [void]$lines.Add('echo ' + $StderrLine + ' >&2')
    [void]$lines.Add('exit /b ' + $ExitCode)
    Set-Content -Path $stubCmd -Value $lines.ToArray() -Encoding Ascii
}

function Assert-FixtureSupabase {
    $resolved = Get-Command supabase -ErrorAction Stop
    if (-not $resolved.Source) {
        throw 'Resolved supabase has no source path; aborting to avoid a non-fixture command.'
    }
    $sourceDir = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($resolved.Source))
    $fixtureDir = [System.IO.Path]::GetFullPath($stubDir)
    if (-not [string]::Equals($sourceDir, $fixtureDir, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Resolved supabase is not the test fixture; aborting to avoid the real CLI.'
    }
}

function Set-DockerStub {
    param(
        [int]$ExitCode = 0,
        [string]$StderrLine = 'WARNING: daemon connection is slow'
    )
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('@echo off')
    [void]$lines.Add('echo ' + $StderrLine + ' >&2')
    [void]$lines.Add('exit /b ' + $ExitCode)
    Set-Content -Path $dockerCmd -Value $lines.ToArray() -Encoding Ascii
}

function Assert-FixtureDocker {
    $resolved = Get-Command docker -ErrorAction Stop
    if (-not $resolved.Source) {
        throw 'Resolved docker has no source path; aborting to avoid a non-fixture command.'
    }
    $sourceDir = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($resolved.Source))
    $fixtureDir = [System.IO.Path]::GetFullPath($stubDir)
    if (-not [string]::Equals($sourceDir, $fixtureDir, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Resolved docker is not the test fixture; aborting to avoid real Docker.'
    }
}

function Assert-DefinesMatch($Got, [string]$ExpectedUrl, [string]$ExpectedKey, [string]$Name) {
    $ok = $null -ne $Got -and $Got.Url -eq $ExpectedUrl -and $Got.Key -eq $ExpectedKey
    Write-CaseResult $ok $Name
}

function Assert-DefinesMissing($Got, [string]$Name) {
    Write-CaseResult ($null -eq $Got) $Name
}

$expectedUrl = 'http://127.0.0.1:54321'
$expectedAnon = 'test-anon-key'
$expectedPublishable = 'test-publishable-key'

try {
    Set-SupabaseStub -StdoutLines @(
        "API_URL=$expectedUrl"
        "ANON_KEY=$expectedAnon"
    ) -ExitCode 0
    $env:PATH = $stubDir + ';' + $originalPath
    Assert-FixtureSupabase
    Write-CaseResult $true 'stub supabase is resolved from fixture PATH'

    $ErrorActionPreference = 'Stop'
    $threw = $false
    $got = $null
    try {
        $got = Get-LocalSupabaseDartDefines
    } catch {
        $threw = $true
    }
    Write-CaseResult (-not $threw) 'success plus stderr does not throw under Stop'
    Assert-DefinesMatch $got $expectedUrl $expectedAnon 'success plus stderr returns ANON_KEY'

    Set-SupabaseStub -StdoutLines @(
        "API_URL=$expectedUrl"
        "ANON_KEY=$expectedAnon"
    ) -ExitCode 1
    Assert-FixtureSupabase
    $got = Get-LocalSupabaseDartDefines
    Assert-DefinesMissing $got 'nonzero exit returns null even with env stdout'

    Set-SupabaseStub -StdoutLines @(
        "API_URL=$expectedUrl"
    ) -ExitCode 0
    Assert-FixtureSupabase
    $got = Get-LocalSupabaseDartDefines
    Assert-DefinesMissing $got 'missing key returns null'

    Set-SupabaseStub -StdoutLines @(
        "API_URL=$expectedUrl"
        "ANON_KEY="
        "PUBLISHABLE_KEY="
    ) -ExitCode 0
    Assert-FixtureSupabase
    $got = Get-LocalSupabaseDartDefines
    Assert-DefinesMissing $got 'empty key values return null'

    Set-SupabaseStub -StdoutLines @(
        "API_URL=$expectedUrl"
        "ANON_KEY=$expectedAnon"
    ) -ExitCode 0
    Assert-FixtureSupabase
    $got = Get-LocalSupabaseDartDefines
    Assert-DefinesMatch $got $expectedUrl $expectedAnon 'ANON_KEY fallback'

    Set-SupabaseStub -StdoutLines @(
        "API_URL=$expectedUrl"
        "PUBLISHABLE_KEY=$expectedPublishable"
    ) -ExitCode 0
    Assert-FixtureSupabase
    $got = Get-LocalSupabaseDartDefines
    Assert-DefinesMatch $got $expectedUrl $expectedPublishable 'PUBLISHABLE_KEY fallback'

    Set-SupabaseStub -StdoutLines @(
        "SUPABASE_URL=$expectedUrl"
        "SUPABASE_ANON_KEY=$expectedAnon"
        "ANON_KEY=ignored-anon"
        "PUBLISHABLE_KEY=ignored-publishable"
    ) -ExitCode 0
    Assert-FixtureSupabase
    $got = Get-LocalSupabaseDartDefines
    Assert-DefinesMatch $got $expectedUrl $expectedAnon 'SUPABASE_ANON_KEY preferred over fallbacks'

    $ErrorActionPreference = 'Stop'
    Set-SupabaseStub -StdoutLines @(
        "API_URL=$expectedUrl"
        "ANON_KEY=$expectedAnon"
    ) -ExitCode 0
    Assert-FixtureSupabase
    $null = Get-LocalSupabaseDartDefines
    Write-CaseResult ($ErrorActionPreference -eq 'Stop') 'Stop preference restored after success'

    $ErrorActionPreference = 'SilentlyContinue'
    $null = Get-LocalSupabaseDartDefines
    Write-CaseResult ($ErrorActionPreference -eq 'SilentlyContinue') 'SilentlyContinue preference restored after success'

    $ErrorActionPreference = 'Stop'
    Set-SupabaseStub -StdoutLines @(
        "API_URL=$expectedUrl"
        "ANON_KEY=$expectedAnon"
    ) -ExitCode 1
    Assert-FixtureSupabase
    $null = Get-LocalSupabaseDartDefines
    Write-CaseResult ($ErrorActionPreference -eq 'Stop') 'Stop preference restored after nonzero exit'

    $ErrorActionPreference = 'Continue'
    Set-SupabaseStub -StdoutLines @(
        "API_URL=$expectedUrl"
    ) -ExitCode 0
    Assert-FixtureSupabase
    $null = Get-LocalSupabaseDartDefines
    Write-CaseResult ($ErrorActionPreference -eq 'Continue') 'Continue preference restored after missing key'

    Set-DockerStub -ExitCode 0
    Assert-FixtureDocker
    Write-CaseResult $true 'stub docker is resolved from fixture PATH'

    $ErrorActionPreference = 'Stop'
    $threw = $false
    $dockerOk = $false
    try {
        $dockerOk = Test-DockerAvailable
    } catch {
        $threw = $true
    }
    Write-CaseResult (-not $threw) 'docker exit 0 plus stderr does not throw under Stop'
    Write-CaseResult ($dockerOk -eq $true) 'docker exit 0 plus stderr returns true'

    Set-DockerStub -ExitCode 1
    Assert-FixtureDocker
    Write-CaseResult ($(Test-DockerAvailable) -eq $false) 'docker nonzero exit returns false'

    $ErrorActionPreference = 'Stop'
    Set-DockerStub -ExitCode 0
    Assert-FixtureDocker
    $null = Test-DockerAvailable
    Write-CaseResult ($ErrorActionPreference -eq 'Stop') 'Stop preference restored after docker success'

    $ErrorActionPreference = 'SilentlyContinue'
    $null = Test-DockerAvailable
    Write-CaseResult ($ErrorActionPreference -eq 'SilentlyContinue') 'SilentlyContinue preference restored after docker success'

    $ErrorActionPreference = 'Stop'
    Set-DockerStub -ExitCode 1
    Assert-FixtureDocker
    $null = Test-DockerAvailable
    Write-CaseResult ($ErrorActionPreference -eq 'Stop') 'Stop preference restored after docker nonzero exit'
} finally {
    $env:PATH = $originalPath
    $ErrorActionPreference = 'SilentlyContinue'
    Remove-Item -LiteralPath $stubDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ("Summary: {0} passed, {1} failed" -f $passed, $failed)
if ($failed -gt 0) {
    exit 1
}
exit 0
