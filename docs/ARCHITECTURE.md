# Hi Hat architecture

## Current Windows runtime

```text
HiHat.exe (Flutter)
  |-- Riverpod application state
  |-- Drift / SQLite local library
  |-- media_kit local FLAC playback
  |-- direct HTTPS provider search
  `-- embedded WebView2 provider acquisition
        `-- completed FLAC -> validate -> managed local library
```

The Windows launcher starts only Flutter. It does not start FastAPI, Uvicorn,
Python, or the former C# browser helper. WebView2 child processes are expected
because the provider browser is embedded through `flutter_inappwebview`.

Search is local-first, debounced, stale-result safe, cached in memory, and kept
separate from acquisition. Play checks SQLite for an existing provider track
before opening acquisition. Playback opens only a local path through
`media_kit`.

## Acquisition boundary

The embedded provider browser uses a WebView profile managed by the WebView2
plugin. Hi Hat loads the normal provider track page, detects genuine human
verification, and invokes the page's visible Download action. It does not read
or export cookies, Turnstile values, Cloudflare state, provider headers, or
signed media URLs.

The downloaded file is directed to the application support acquisition folder,
checked for stable completion, validated as a complete FLAC, copied through a
managed `.part` file, renamed atomically, and recorded in Drift.

## Known gaps

Online playback currently uses full-download-before-play. Progressive playback
has not been proven safe for the provider's browser download path and remains a
separate prototype phase. The embedded browser is currently created per
acquisition route rather than prewarmed once at application startup.

## Legacy source

`backend/` and `acquisition_helper/` remain as reference source during the
migration, but neither is part of the normal Windows runtime.
