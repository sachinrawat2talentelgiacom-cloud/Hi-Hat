# Browser acquisition status

Windows implementation now routes acquisition through the local C# WebView2 helper and FastAPI.

## Boundary

- The Flutter client sends non-local Play requests to FastAPI; it no longer opens its own provider WebView.
- FastAPI asks the localhost-only helper to open the exact `/track/{provider_track_id}` route in a persistent WebView2 profile.
- Existing provider verification remains visible and must be completed by the user.
- Hi Hat checks for the visible `#download-track-btn` and invokes that ordinary page action only.
- Cookies, local storage, Turnstile values, Cloudflare state, authorization headers, and signed URLs are never read or sent to FastAPI.
- Reset Browser Session travels through FastAPI to the helper and clears its WebView2 profile data without touching local music.

## Download and finalization

The helper subscribes to WebView2 `DownloadStarting`, associates the operation with the acquisition ID, and directs it to `%LOCALAPPDATA%\HiHat\Acquisitions\<id>\incoming.flac`. FastAPI then:

1. validates the FLAC marker and stream metadata;
2. compares actual and expected duration;
3. hashes and deduplicates the file;
4. writes a managed `.part` copy;
5. validates that copy again;
6. atomically renames it into the managed music library;
7. updates Drift;
8. returns the local track to the original Play action for autoplay.

## Current verification

- Dart formatting: passed.
- Flutter analysis: passed.
- Flutter unit/widget tests: passed.
- Native helper build: blocked on this machine until the .NET SDK is installed; the launcher now performs that one-time bootstrap.
- Live browser download and autoplay: not yet claimed.
- Android: not yet tested.

Visible debug mode intentionally remains the default until a real known-track test confirms search, download capture, validation, finalization, and autoplay. Set `HI_HAT_HELPER_HIDDEN=1` only after that acceptance test passes.
