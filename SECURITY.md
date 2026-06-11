# Security Policy

## How claudoremi handles your data

claudoremi can read browser cookies to access your own YouTube playlists, so transparency
about that is a first-class concern:

- **Consent-gated.** The cookie bridge only ever talks to a browser *you* explicitly started
  with `--remote-debugging-port=9222`. Nothing runs silently or in the background.
- **Local only.** Cookies are written to `yt-cookies.txt` inside the skill folder, are listed
  in `.gitignore`, and are only ever sent to youtube.com (by yt-dlp/mpv — the same destination
  your browser already sends them to). They are never uploaded, logged, or printed.
- **Your account only.** The bridge is scoped to the session already logged into your browser.
  It does not touch any other browser, profile, or account.
- **Fully optional.** Plain YouTube search and local-file playback require no cookies at all.

If you publish a fork, never commit `yt-cookies.txt` or any real cookie data.

## Reporting a vulnerability

Found a security issue? Please open a [GitHub issue](https://github.com/coskundeniz89/claudoremi/issues)
with the `security` label, or describe the problem privately via the repository owner's profile.
We'll respond as quickly as we can.
