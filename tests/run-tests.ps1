# Runs the full test suite. Usage: ./tests/run-tests.ps1
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    Write-Host '=== Node unit tests ==='
    node --test tests/cookies.test.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Node tests failed' }

    Write-Host "`n=== PowerShell IPC tests ==="
    & (Join-Path $PSScriptRoot 'mpv-ipc.test.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'PowerShell IPC tests failed' }

    Write-Host "`nAll tests passed."
} finally {
    Pop-Location
}
