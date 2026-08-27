# Codex Task — Background-only downloads, real cancel, draggable dock

## Context

Hi Hat is a Flutter app (client/) that downloads FLACs from monochrome.tf via `flutter_inappwebview`. Multi-window concurrent downloads were just added (commit 3cb4ab7). Three problems need fixing.

Key files:
- `client/lib/services/track_playback_coordinator.dart` — starts acquisition per track; inserts an `OverlayEntry` hosting `BrowserAcquisitionScreen` per download (`_activeSessions`, `_activeEntries` keyed by track.id).
- `client/lib/features/browser_acquisition/browser_acquisition_screen.dart` — the per-track window: runs the InAppWebView, automation JS, download interception (`onDownloadStarting`, blob handler), finalize → local import.
- `client/lib/features/browser_acquisition/acquisition_dock.dart` — fixed bottom-right pill list of active transfers with cancel buttons.
- `client/lib/services/download_service.dart` — Riverpod `StateNotifier<DownloadsState>` holding per-track `TransferState` (phase, progress, isMinimized, isMaximized).

## Problem 1 — Download window pops up; it must run fully in the background

**Current behavior:** `DownloadService.begin()` sets `isMinimized: false`, so every new download renders `BrowserAcquisitionScreen`'s centered modal window — including a `Material(color: Colors.black54)` barrier that blocks the entire app. Multiple downloads stack multiple blocking windows.

**Required:**
- Downloads must start hidden. The user only sees the dock chips — no window, no barrier. Change `begin()` to start with `isMinimized: true`.
- The `isMinimized` branch in `BrowserAcquisitionScreen.build` already wraps the webview in `Offstage` — verify the webview still initializes and automation still runs while offstage (it gates creation on the `initialization` future).
- **Exception — human verification:** when the phase becomes `AUTH_REQUIRED` (Cloudflare Turnstile / captcha), the webview must be seen. Auto-open that track's window (`focus(trackId)` + `showProviderBrowser = true`). Once the download actually starts (`STARTING_DOWNLOAD`), auto-minimize the window again.
- Keep: tapping a dock chip opens that track's window (`focus()`); the window's minimize button returns it to the dock.

## Problem 2 — Cancel is slow, unresponsive, and doesn't actually stop the work

**Current behavior:** The dock's X calls `DownloadService.cancel()`, which only sets `phase: 'CANCELLED'`. Nothing else reacts to it:
- The webview keeps downloading, the Dio HTTP download continues, timers keep running.
- The overlay entry is never removed and the `Completer` in `TrackPlaybackCoordinator._activeSessions` never completes — the `play()` future hangs forever.
- When the download eventually finishes, the cancelled track even gets imported and auto-plays.

**Required — cancellation must be real and instant:**
- In `BrowserAcquisitionScreen`, listen to this track's `TransferState` (e.g. `ref.listen` on `downloadServiceProvider`). When the phase becomes `CANCELLED`, tear down immediately:
  - Cancel `monitor`, `automationTimer`, and `downloadStartDeadline`.
  - `webViewController?.stopLoading()`, then dispose/close the webview.
  - Cancel any in-flight Dio download — add a `CancelToken` to `_downloadHttpUri`.
  - Add a cancelled flag checked before `_finalize`, `_saveDataUri`, and blob-extraction callbacks so nothing resumes after teardown.
  - Delete the partial `incoming.flac` if it exists.
  - Call `_finish(null)` so the overlay entry is removed, the completer completes with null, and `play()` returns promptly.
- A cancelled track must NOT auto-play, and tapping the track again must start a fresh, clean download (no stale `_activeSessions` state, no leftover partial file).
- After teardown completes, remove the transfer from the map (`DownloadService.remove(trackId)`); the chip already disappears instantly since `activeTransfers` filters out non-active phases — keep that instant UI response.
- Teardown is fire-and-forget async; the UI must never wait on it.

## Problem 3 — Dock must be draggable anywhere

**Current behavior:** `AcquisitionDock` is hard-pinned via `Align(alignment: Alignment.bottomRight)` inside `SearchScreen`'s `Stack`.

**Required:**
- Make the dock freely draggable within the window. Convert to a `StatefulWidget` holding an `Offset` position, rendered with `Positioned` in the `Stack`.
- The header row ("Active Downloads (n)") is the drag handle — `GestureDetector` `onPanUpdate` (or `Listener`) updates the offset.
- Clamp the position to the visible screen bounds so the dock can never be dragged off-screen. Handle window resizes gracefully.
- Keep the dock above other content; chip taps (focus/cancel) must still work and must not be swallowed by the drag gesture (use the header as the only drag area).
- Persist the position in-memory for the session (SharedPreferences optional).
- Recommended (small scope): hoist `AcquisitionDock` from `SearchScreen` up into the app shell so it stays visible while navigating to Library/Settings during a download.

## Constraints

- Follow existing code style and Riverpod patterns; no unrelated refactors.
- No new dependencies unless strictly necessary.

## Verification

1. `cd client && flutter analyze` — clean.
2. `cd client && flutter test` — all tests pass; update/extend `test/download_service_test.dart` for the cancel/removal behavior.
3. Manual checks:
   - Start 3 downloads → no window appears; dock shows 3 chips with progress.
   - Cancel one → chip vanishes instantly, partial file stops growing and is deleted, track does NOT auto-play, re-tapping it starts fresh.
   - Drag the dock to each screen corner → it stays put and stays interactive.
   - Force an `AUTH_REQUIRED` case → window auto-opens for verification → after verifying, window hides and the download completes in the background.
