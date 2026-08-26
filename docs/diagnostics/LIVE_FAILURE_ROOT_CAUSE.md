# Live failure root cause

## Test Query

`closer`; exact track `monochrome:63232677`, Closer by The Chainsmokers.

## Last Successful Stage

Provider Download action invoked by `BrowserAcquisitionScreen._onLoaded`.

## First Failed Stage

WebView download callback / download start.

## Exact Symptom

Acquisition remained `STARTING_DOWNLOAD` for more than 20 seconds. The
`onDownloadStarting` callback never changed state to `DOWNLOADING`.

## Exact Error

`DOWNLOAD_NOT_STARTED: The provider accepted Download, but no file transfer started.`

## File

`client/lib/features/browser_acquisition/browser_acquisition_screen.dart`

## Class / Function

`_BrowserAcquisitionScreenState._onLoaded` and the `InAppWebView.onDownloadStarting` callback.

## Runtime State

PING PASS; Search RESULTS_READY (25); local miss; route open; Download selector
matched; action invoked; acquisition `STARTING_DOWNLOAD`; progress 0.

## Root Cause

The provider's current Download action does not produce an event recognized by
the Windows `flutter_inappwebview` `onDownloadStarting` callback. Because that
callback owns controlled-path creation, no file enters the finalization path.

## Required Fix

Inspect the normal provider page's post-click navigation/download behavior using
safe WebView navigation telemetry. Support the resulting ordinary browser
download event without reading or exporting authorization state.

## Components Proven Working And Not To Change

Named-pipe bridge, live SearchController path, exact result selection, shared
Play coordinator, local lookup, FLAC validation/finalization, Drift, and
`media_kit` local playback.
