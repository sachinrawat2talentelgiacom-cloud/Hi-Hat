# Failure root cause

## Summary

The prescribed live diagnostic flow first fails at the native diagnostic
control-interface readiness stage.

## Last Successful Stage

`HiHat.exe` process startup. The debug executable remained alive after five
seconds.

## First Failed Stage

Native diagnostic channel readiness.

## Exact Symptom

Connecting to `\\.\pipe\HiHat.Test` timed out after 2,000 ms. The required
`\\.\pipe\HiHat.Diagnostics` server is likewise absent.

## Exact Error

`Exception calling "Connect" with "1" argument(s): "The operation has timed out."`

## File / Function

- `client/windows/runner/main.cpp`: Windows process entry point; no diagnostic
  pipe service is started.
- `scripts/hihat-test-client.ps1`: `NamedPipeClientStream.Connect` exposes the
  missing server.

## Why It Failed

The repository contains a named-pipe client but no server implementation inside
`HiHat.exe`. Consequently the required automated live observations cannot cross
the app boundary. This is an implementation gap, not a provider failure.

## Evidence

- App process: started and remained alive (`pid=7464`, `exited=False`).
- Pipe PING: timed out.
- Code audit: no `NamedPipeServerStream`, `CreateNamedPipe`, diagnostics
  MethodChannel, or equivalent server exists in the Windows runner or Dart code.

## Independent Live Search Finding

Direct probes of the exact endpoints configured in
`ProviderSearchService.instances` showed volatile upstream state:

- `https://monochrome-api.samidy.com/search/`: initially HTTP 401, then a
  successful response in 1.59 seconds on the diagnostic rerun.
- `https://api.monochrome.tf/search/`: HTTP 503 Service Unavailable.

The primary endpoint can currently support search, while the fallback remains
unavailable. This volatility is an external dependency condition, not the cause
of the missing named-pipe interface.

## Is This A Root Cause Or A Secondary Error?

Missing diagnostic server: root cause of the automated live diagnostic failure.
Provider HTTP failures: transient external degradation; not currently a total
search blocker because the primary endpoint recovered.

## Required Fix

Add a debug-only named-pipe server inside `HiHat.exe`, bridge its commands to the
same Riverpod search/play paths used by the UI, and expose read-only state
snapshots. Then rerun with a configured permitted provider session/test track.

## What Should NOT Be Changed

Do not replace the proven Drift library, FLAC parser, managed finalization, or
`media_kit` local playback path. Do not bypass provider authorization controls.
