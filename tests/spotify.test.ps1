# Smoke tests for spotify.ps1 - verify it runs cleanly whether or not Spotify is installed.
# Usage: pwsh -File tests/spotify.test.ps1
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot '..\skills\claudoremi\spotify.ps1'
$script:failures = 0

function Assert([bool]$Condition, [string]$Message) {
    if ($Condition) { Write-Host "  ok   - $Message" }
    else { Write-Host "  FAIL - $Message"; $script:failures++ }
}

Write-Host 'spotify.ps1 tests'

# Status never throws and always prints a one-line state.
$out = & $script 2>&1
Assert ($LASTEXITCODE -eq 0) 'status exits 0'
Assert ($out -match '^spotify:') 'status prints a spotify: line'

# Open/Uri must NOT pop a system dialog when Spotify is absent - they exit cleanly with a message.
$out = & $script -Open 'test query' 2>&1
Assert ($out -match 'spotify') 'open prints a spotify-related message'
Assert ($LASTEXITCODE -in @(0, 1)) 'open exits with a defined code (no hang/dialog)'

# Invalid control value is rejected by the parameter validator.
$threw = $false
try { & $script -Control 'frobnicate' 2>$null } catch { $threw = $true }
Assert ($threw -or $LASTEXITCODE -ne 0) 'invalid -Control value is rejected'

if ($script:failures -gt 0) {
    Write-Host "`n$($script:failures) test(s) FAILED"
    exit 1
}
Write-Host "`nAll spotify tests passed."
exit 0
