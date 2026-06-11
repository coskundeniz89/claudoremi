# Control the Spotify desktop app with no API keys and no Premium requirement.
# Reads "now playing" from Spotify's window title and drives playback with global
# media keys (so it controls whichever app owns media focus - normally Spotify).
#
#   ./spotify.ps1                       # status / now playing
#   ./spotify.ps1 -Control playpause    # playpause | next | previous | stop
#   ./spotify.ps1 -Open "miles davis"   # open Spotify search for a query
#   ./spotify.ps1 -Uri spotify:track:.. # launch a specific Spotify URI/link
[CmdletBinding(DefaultParameterSetName = 'Status')]
param(
    [Parameter(ParameterSetName = 'Status')][switch]$Status,
    [Parameter(ParameterSetName = 'Control')][ValidateSet('playpause', 'next', 'previous', 'stop')][string]$Control,
    [Parameter(ParameterSetName = 'Open')][string]$Open,
    [Parameter(ParameterSetName = 'Uri')][string]$Uri
)

Add-Type @'
using System;
using System.Runtime.InteropServices;
public class MediaKey {
    [DllImport("user32.dll")] static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    const uint KEYUP = 0x2;
    public static void Send(byte vk) {
        keybd_event(vk, 0, 0, UIntPtr.Zero);
        keybd_event(vk, 0, KEYUP, UIntPtr.Zero);
    }
}
'@ -ErrorAction SilentlyContinue

$VK = @{ playpause = 0xB3; next = 0xB0; previous = 0xB1; stop = 0xB2 }

function Get-SpotifyProc { Get-Process Spotify -ErrorAction SilentlyContinue }

function Get-NowPlaying {
    # Spotify sets its window title to "Artist - Track" while playing, and back to
    # "Spotify"/"Spotify Premium"/"Spotify Free" when paused or idle.
    $p = Get-Process Spotify -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle } | Select-Object -First 1
    if (-not $p) { return $null }
    $t = $p.MainWindowTitle
    if ($t -in @('Spotify', 'Spotify Premium', 'Spotify Free')) { return [pscustomobject]@{ Playing = $false; Title = $null } }
    return [pscustomobject]@{ Playing = $true; Title = $t }
}

function Test-SpotifyInstalled {
    [bool]((Get-Command spotify -ErrorAction SilentlyContinue) -or
        (Test-Path "$env:APPDATA\Spotify\Spotify.exe") -or
        (Get-Process Spotify -ErrorAction SilentlyContinue) -or
        (Get-AppxPackage -Name 'SpotifyAB.SpotifyMusic' -ErrorAction SilentlyContinue))
}

switch ($PSCmdlet.ParameterSetName) {
    'Status' {
        if (-not (Get-SpotifyProc)) {
            $hint = if (Test-SpotifyInstalled) { 'installed but not running' } else { 'not installed' }
            "spotify: not running ($hint)"
        } else {
            $np = Get-NowPlaying
            if ($np.Playing) { "spotify: playing - $($np.Title)" }
            else { "spotify: running, paused/idle" }
        }
    }
    'Control' {
        if (-not (Get-SpotifyProc)) { "spotify is not running - open it first (or use -Open)"; exit 1 }
        [MediaKey]::Send([byte]$VK[$Control])
        Start-Sleep -Milliseconds 500
        $np = Get-NowPlaying
        if ($np.Playing) { "spotify: $($np.Title)" } else { "spotify: paused/idle" }
    }
    'Open' {
        if (-not (Test-SpotifyInstalled)) { "spotify is not installed - skipping (use YouTube instead)"; exit 1 }
        try {
            Start-Process ("spotify:search:" + [uri]::EscapeDataString($Open)) -ErrorAction Stop
            "spotify: opened search for '$Open' - press play, or run -Control playpause"
        } catch {
            "Could not launch Spotify ($($_.Exception.Message))"; exit 1
        }
    }
    'Uri' {
        if (-not (Test-SpotifyInstalled)) { "spotify is not installed - skipping (use YouTube instead)"; exit 1 }
        try {
            Start-Process $Uri -ErrorAction Stop
            "spotify: launched $Uri"
        } catch {
            "Could not launch $Uri ($($_.Exception.Message))"; exit 1
        }
    }
}
exit 0
