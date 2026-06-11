---
name: musicc
description: Play and control music in the terminal while you work (mpv + yt-dlp; YouTube search, the user's own YouTube playlists, or local files). Use for requests like "play some music", "play X", "play my playlist", "list my playlists", "pause", "resume", "skip", "next song", "volume up/down", "set volume to 80", "mute", "what's playing", "stop the music".
---

# musicc — terminal music for Claude Code

Music plays in a **detached `mpv` process** in the background and is controlled over a
JSON IPC named pipe (`\\.\pipe\mpv-claude`). The music keeps playing after every tool
call ends — Claude only talks to it through the pipe.

Set `$mu` to this skill's base directory (printed at the top of this skill when it loads).
All helper files live there:

- `mpv-ipc.ps1` — sends one JSON command to the pipe (`-Read` for queries)
- `get-yt-cookies.mjs` — pulls YouTube cookies from the user's running Chromium browser (optional, for personal playlists)
- `yt-dlp.exe` — local copy, created on first use (system copies are often outdated)
- `yt-cookies.txt` — generated locally, **sensitive; never share, commit, or print it**

## Dependencies — bootstrap silently on first use

Never send the user off to install things; check and fix it yourself:

```powershell
$mpv = (Get-Command mpv -ErrorAction SilentlyContinue).Source
if (-not $mpv) { $mpv = @('C:\Program Files\MPV Player\mpv.exe', "$env:LOCALAPPDATA\Programs\mpv\mpv.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1 }
```

1. **mpv** missing → `winget install -e --id shinchiro.mpv --accept-source-agreements --accept-package-agreements` (lands in `C:\Program Files\MPV Player\mpv.exe`).
2. **yt-dlp**: always use `$mu\yt-dlp.exe`. If missing: `Invoke-WebRequest 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' -OutFile "$mu\yt-dlp.exe"`.
3. **Node.js**: required for YouTube (yt-dlp's "n challenge" solver) and the cookie bridge. If `node` is missing, ask the user before installing (`winget install -e --id OpenJS.NodeJS.LTS`).

When calling yt-dlp from the CLI, **always** pass `--js-runtimes node` (and `--cookies "$mu\yt-cookies.txt"` if the file exists).

## Interpreting the request

- **URL** (youtube.com / youtu.be / playlist) → play it directly
- **"my playlists" / "list my playlists"** → list the user's YouTube playlists
- **"play my <name> playlist"** → fetch the playlist list first, play the matching one
- **"liked videos"** → `list=LL`, **"watch later"** → `list=WL`
- **"stop" / "quit the music"** → quit mpv
- **"pause" / "resume"** → pause toggle
- **"mute" / "unmute"** → mute toggle (music keeps running, just silent)
- **"volume up/down"** → volume ±10; **"set volume to 80"** → absolute value
- **"system volume..." / "computer volume..."** → Windows master volume, not mpv (see System volume)
- **"skip" / "next"** → next track
- **"what's playing"** → query media-title
- **local file/folder name** → play from the local music folder (`$env:USERPROFILE\Music` by default), shuffled
- **anything else** → treat as a YouTube search

## The user's YouTube account (optional)

With browser cookies, yt-dlp can list and play the user's own playlists — including
private ones — with **no API keys**. Works with any Chromium browser (Brave, Chrome, Edge)
started with `--remote-debugging-port=9222`:

```powershell
node "$mu\get-yt-cookies.mjs"        # writes $mu\yt-cookies.txt from the running browser
```

If port 9222 is closed, tell the user to start their browser with
`--remote-debugging-port=9222` (or skip account features — search still works without cookies).
As a fallback when the browser is **closed**, `--cookies-from-browser brave` (or `chrome`/`edge`)
also works; it fails with "Could not copy cookie database" while the browser is open.

List the user's playlists:

```powershell
& "$mu\yt-dlp.exe" --js-runtimes node --cookies "$mu\yt-cookies.txt" --flat-playlist --print "%(title)s :: %(url)s" "https://www.youtube.com/feed/playlists"
```

Same command with a playlist URL at the end shows its tracks. If a private playlist
returns "sign in" / "unavailable", the cookies are stale — re-run the cookie bridge.

## Playing (always a single instance)

```powershell
Stop-Process -Name mpv -ErrorAction SilentlyContinue -Confirm:$false
```

Shared mpv arguments (add to every play command):

```powershell
$mpvArgs = @('--no-video','--volume=55','--force-window=no',
  '--input-ipc-server=\\.\pipe\mpv-claude',
  "--script-opts=ytdl_hook-ytdl_path=$mu\yt-dlp.exe",
  "--ytdl-raw-options=cookies=$mu\yt-cookies.txt,js-runtimes=node",
  '--ytdl-format=bestaudio')
```

(If `yt-cookies.txt` doesn't exist, drop the `cookies=` part of `--ytdl-raw-options`.)

YouTube search (single result — ideal for radio/long mixes; use `ytsearch10:` for a queue):

```powershell
Start-Process $mpv -ArgumentList ($mpvArgs + '"ytdl://ytsearch1:SEARCH QUERY"')
```

Playlist/URL (the user's own playlists work too, thanks to cookies):

```powershell
Start-Process $mpv -ArgumentList ($mpvArgs + @('--shuffle','"https://www.youtube.com/playlist?list=..."'))
```

Local folder (shuffled, endless):

```powershell
Start-Process $mpv -ArgumentList ($mpvArgs + @('--shuffle','--loop-playlist=inf',"`"$env:USERPROFILE\Music`""))
```

Single local file: pass the file path instead (no `--shuffle`/`--loop-playlist`).
Arguments containing spaces need embedded quotes: `'"..."'`.

## Verify before you claim — the golden rule

**Never tell the user something worked until you've read the state back.** Resolution can
take 10–30 s (yt-dlp + the Node challenge solver), and a started process is not the same
as audible music.

- After starting playback: poll `media-title` every 3 s (up to ~12 tries) until it answers,
  then read `playback-time` twice ~3 s apart. **Only if it increased** report "now playing".
  A raw `ytsearch1:...` title means it's still resolving — keep polling.
- After changing volume/mute/pause: read the property back and report the **actual** value.
- If `playback-time` doesn't advance or mpv exits: say so honestly, diagnose (process alive?
  yt-dlp error? stale cookies?) and retry yourself — e.g. rephrase the search. Don't make
  the user debug.

## Control (IPC)

```powershell
& "$mu\mpv-ipc.ps1" -Json '{"command":["cycle","pause"]}'                                        # pause/resume
& "$mu\mpv-ipc.ps1" -Json '{"command":["playlist-next"]}'                                       # next track
& "$mu\mpv-ipc.ps1" -Json '{"command":["set_property","volume",80]}'                            # volume 0-100 (boost up to 130)
& "$mu\mpv-ipc.ps1" -Json '{"command":["add","volume",10]}'                                     # volume up a bit (negative: down)
& "$mu\mpv-ipc.ps1" -Json '{"command":["cycle","mute"]}'                                        # mute/unmute toggle
& "$mu\mpv-ipc.ps1" -Json '{"command":["get_property","media-title"],"request_id":1}' -Read     # what's playing
& "$mu\mpv-ipc.ps1" -Json '{"command":["get_property","volume"],"request_id":2}' -Read          # current volume
& "$mu\mpv-ipc.ps1" -Json '{"command":["get_property","mute"],"request_id":3}' -Read            # mute state
& "$mu\mpv-ipc.ps1" -Json '{"command":["get_property","playback-time"],"request_id":4}' -Read   # position (for verification)
```

## System volume (Windows master)

When the user means the **computer's** volume, not mpv's, simulate media keys
(each press is ±2 of 100):

```powershell
$sh = New-Object -ComObject WScript.Shell
1..10 | ForEach-Object { $sh.SendKeys([char]175) }   # system volume up (+20)
1..10 | ForEach-Object { $sh.SendKeys([char]174) }   # system volume down (-20)
$sh.SendKeys([char]173)                              # system mute toggle
```

## Stopping

```powershell
& "$mu\mpv-ipc.ps1" -Json '{"command":["quit"]}'
Stop-Process -Name mpv -ErrorAction SilentlyContinue -Confirm:$false   # if the pipe doesn't answer
```

## Troubleshooting

- **Pipe not found** → mpv died (or never started). Check `Get-Process mpv`, restart playback.
- **"Only images are available" / "n challenge solving failed"** → Node missing or
  `--js-runtimes node` not passed. Fix and retry.
- **Private playlist asks to sign in** → stale cookies; re-run `node "$mu\get-yt-cookies.mjs"`.
- **Two mpv processes** → kill all (`Stop-Process -Name mpv -Force`) and start one cleanly.
- **winget missing** → download mpv from https://mpv.io/installation/ and yt-dlp from GitHub releases manually.

## Notes

- After every action tell the user briefly what's playing / what changed; don't dump raw output.
- mpv opens no window (`--force-window=no`); audio shows up as "mpv" in the Windows volume mixer.
- Platform: built for Windows 10/11 (PowerShell + named pipes). On macOS/Linux the same flow
  works with `--input-ipc-server=/tmp/mpv-claude` and writing JSON to that socket
  (e.g. `echo '{"command":[...]}' | socat - /tmp/mpv-claude`).
- If this folder is ever shared/published: `yt-cookies.txt` and `yt-dlp.exe` must never be
  included (personal cookies; per-user binary).
