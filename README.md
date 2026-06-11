# 🎵 musicc — music for your Claude Code sessions

[![CI](https://github.com/coskundeniz89/musicc-claude-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/coskundeniz89/musicc-claude-skill/actions/workflows/ci.yml)

A [Claude Code](https://claude.com/claude-code) skill that turns Claude into your terminal DJ.
Ask in plain language — any language — and keep coding while the music plays:

```text
> play some lofi
  🎶 Now playing: "lofi hip hop radio — beats to relax/study to"

> play my Driving playlist        # your own YouTube playlists, even private ones
> skip
> set volume to 80
> mute                            # music keeps running, just silent
> what's playing?
> stop the music
```

No API keys. No subscriptions. No browser tab eating your RAM.

## Features

- **YouTube search** — "play deep house", "play Bohemian Rhapsody" → streams the audio instantly
- **Your YouTube account** — lists and plays your own playlists (including private ones) by
  borrowing cookies from your already-logged-in browser. Zero API setup.
- **Local files** — plays your `~/Music` folder or any file/folder you name
- **Full playback control** — pause, skip, volume, mute, "what's playing", all conversational
- **Honest feedback** — the skill instructs Claude to verify that audio is *actually* advancing
  before claiming "now playing", and to read volume/mute state back after every change
- **Self-bootstrapping** — missing mpv or yt-dlp? Claude installs them itself on first use

## How it works

```text
you ──(plain language)──▶ Claude Code ──(reads SKILL.md)──▶ PowerShell
                                                              │
            ┌── starts detached ──────────────────────────────┤
            ▼                                                 ▼
       mpv (audio) ◀──── JSON IPC over \\.\pipe\mpv-claude ── control
            │                                            (pause/skip/volume/status)
            ▼
       yt-dlp + Node ──▶ YouTube (search, playlists, your account via browser cookies)
```

- **mpv** runs detached and windowless — music survives between Claude tool calls and even
  between sessions. Claude talks to it over a named pipe using mpv's JSON IPC.
- **yt-dlp** resolves YouTube audio. A fresh local copy is kept inside the skill folder
  (system-wide copies are often outdated and silently break).
- **Cookie bridge** (optional): `get-yt-cookies.mjs` pulls your YouTube cookies live from a
  running Chromium browser (Brave/Chrome/Edge with `--remote-debugging-port=9222`) over the
  DevTools protocol — that's what unlocks *your* playlists without any Google API project.

## Requirements

- Windows 10/11 with PowerShell (5.1 or 7+)
- [Claude Code](https://claude.com/claude-code) CLI
- `winget` (for auto-installing mpv) — preinstalled on Windows 11 and current Windows 10
- Node.js 18+ — required for YouTube playback (yt-dlp's challenge solver) and the cookie bridge

> macOS/Linux: the architecture works there too (mpv uses a Unix socket instead of a named
> pipe), but this version ships Windows commands. Contributions welcome — see Roadmap.

## Install

### Option 1 — clone + setup script (recommended)

```powershell
git clone https://github.com/coskundeniz89/musicc-claude-skill.git
cd musicc-claude-skill
./setup.ps1
```

The script copies the skill to `~/.claude/skills/musicc`, installs mpv if missing (winget),
and downloads the latest yt-dlp into the skill folder.

### Option 2 — Claude Code plugin

Inside Claude Code:

```text
/plugin marketplace add coskundeniz89/musicc-claude-skill
/plugin install musicc@musicc-claude-skill
```

### Option 3 — manual

Copy `skills/musicc/` into `~/.claude/skills/musicc/`. Done — Claude bootstraps the
dependencies itself the first time you ask for music.

Then start a **new** Claude Code session and say: `play some music` 🎧

## Using your YouTube account (optional)

To let Claude see and play your own playlists, start your Chromium-based browser with
remote debugging enabled, e.g.:

```powershell
brave.exe --remote-debugging-port=9222    # or chrome.exe / msedge.exe
```

Then just ask: *"list my playlists"* or *"play my Workout playlist"*. Claude pulls your
YouTube cookies from the running browser automatically and refreshes them when they go stale.

**Privacy:** cookies are written to `yt-cookies.txt` *inside the skill folder on your
machine*, are listed in `.gitignore`, and are never sent anywhere except youtube.com
(by yt-dlp/mpv, exactly like your browser does). Plain YouTube search works fine without
any of this.

## Tests

```powershell
./tests/run-tests.ps1               # or individually:
node --test tests/cookies.test.mjs  # cookie → Netscape conversion
pwsh -File tests/mpv-ipc.test.ps1   # IPC client against an emulated pipe server
```

Tests run on every push via GitHub Actions (`windows-latest`) — no audio device or network needed.

## Roadmap

- macOS/Linux support (Unix socket IPC)
- Spotify (requires Premium; via `spotify_player`/librespot)
- Queue management ("add X to the queue"), crossfade… and one day, a proper DJ mode 🎚️

## License

[MIT](LICENSE)
