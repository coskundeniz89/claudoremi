# Contributing to claudoremi

Music while you code should be for everyone — so contributions are genuinely welcome. **Hit a
bug? Open an issue or send a PR and we'll review and merge it.** Small fixes, new engines, other
platforms — all fair game.

## Good first contributions

- **macOS / Linux support** — the architecture already works there (mpv uses a Unix socket
  instead of a Windows named pipe). Port the PowerShell helpers to shell scripts.
- **Spotify Web API engine** — play an exact track/playlist by name using the user's *own*
  client ID set locally (no shared secrets). Today's Spotify support controls the desktop app
  via media keys; the API path is open.
- **More sources** — SoundCloud, Bandcamp, a local-library indexer, internet radio presets.
- **Queue management** — "add X to the queue", "play next".

## Ground rules (the things that make claudoremi *claudoremi*)

1. **No required API keys or paid accounts** for the core experience. Anything that needs a key
   must be optional and configured locally by the user on their own machine.
2. **Verify before claiming success.** If a command "plays" something, confirm it's actually
   playing (e.g. `playback-time` advancing) before reporting success. Don't make the user debug.
3. **Privacy first.** Never commit `yt-cookies.txt`, real cookies, tokens, or `yt-dlp.exe`.
   Keep sensitive data on the user's machine.
4. **Keep it conversational.** The user talks in plain language; the skill does the plumbing.

## Running the tests

```powershell
./tests/run-tests.ps1               # full suite
node --test tests/cookies.test.mjs  # Node: cookie → Netscape conversion
pwsh -File tests/mpv-ipc.test.ps1   # PowerShell: IPC client vs an emulated pipe server
```

Tests run on `windows-latest` via GitHub Actions on every push and PR — they need no audio
device or network, so please add coverage for new logic where it's practical.

## Sending a PR

1. Fork, branch, make your change.
2. Run the tests (green, please).
3. Open the PR with a short description of what and why. That's it — we'll take it from there.

Thanks for helping people code to a soundtrack. 🎧
