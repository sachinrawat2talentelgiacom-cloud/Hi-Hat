# Browser acquisition status

Updated: 2026-08-26

Windows acquisition now runs inside `HiHat.exe` through the
`flutter_inappwebview` WebView2 plugin. The launcher does not start FastAPI,
Python, or the former C# helper.

## Current flow

1. Play checks Drift for an existing provider track and plays it immediately.
2. A missing Monochrome track opens the in-app acquisition route.
3. The normal provider track page loads in an embedded WebView2 profile.
4. Human verification is shown when the page requires it.
5. Hi Hat invokes the page's ordinary visible Download action.
6. On Windows the download is directed to the app support acquisition folder.
7. The completed file is validated, duration-checked, hashed, deduplicated,
   copied through `.part`, atomically finalized, recorded in Drift, and played.

## Current verification

- Flutter formatting: passed.
- Flutter analysis: passed with no issues.
- Flutter tests: all four tests passed.
- Windows debug build: passed and produced `hi_hat.exe`.
- Live browser download and autoplay: requires an interactive acceptance test.
- Clean WebView shutdown on `6.2.0-beta.3`: requires an interactive acceptance
  test.
- Android browser acquisition: not yet tested.

## Remaining work

- Keep one prewarmed acquisition WebView alive across Play operations.
- Prove whether the browser-managed FLAC can be read safely while it grows.
- If safe, add progressive playback and adaptive buffering; otherwise retain
  honest full-download mode.
- Add download percentage events where content length is available.
