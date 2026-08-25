# Current upstream Monochrome source flow

Reference checkout: `monochrome-music/monochrome` commit `7a2fbeaaab95b8a9f6c8112ad9d71340214582d1` (2026-08-25). License: Apache-2.0.

Inspected modules include `js/api.js`, `js/music-api.js`, `js/HiFi.ts`, `js/downloads.js`, `js/download-utils.ts`, `js/dash-downloader.ts`, `js/hls-downloader.js`, `js/player.js`, metadata modules, `js/storage.js`, `js/proxy-utils.js`, README/DOCKER documentation, and playback/fallback tests.

## Findings

- Search primarily uses native TIDAL querying through `HiFiClient.query`; failures fall back to configured HiFi worker instances.
- Normal playback calls `MusicAPI.getStreamUrl` -> `LosslessAPI.getStreamUrl`.
- Outside dev mode, playback obtains metadata and tries Unified Playback first with `intent=stream`; ISRC-based Deezer resolution is the next stereo fallback.
- Download uses `downloadTrack` -> `enrichTrack`. Enrichment calls the same Unified Playback resolver with `intent=download`, then uses ISRC-based Deezer fallback. The resulting direct/DASH/HLS resource is downloaded and metadata is added.
- Dev mode is different: it directly calls the configured paid HiFi endpoint's `/trackManifests/` route.
- Unified Playback can select Monochrome, TIDAL, or Amazon resources. Some Amazon resources include CENC/decryption material; Hi Hat intentionally does not implement those protected paths.
- Quality is normalized, but actual file quality must still be validated after acquisition.
- Current source defaults Unified Playback to an external API and a public client token. For that default token, `fetchUnifiedPlaybackEnvelope` first obtains an `X-Turnstile-JWT` through the browser. Authorization failures are not a supported anonymous backend contract.
- The README says non-official deployed origins cannot stream; localhost self-hosting is the exception, or a user may configure a working paid HiFi endpoint.

Therefore the official application succeeds through Unified Playback and/or its ISRC fallback, while Hi Hat previously used only the public `/track/` strategy. The reusable supported boundary is an authorized resolver contract supplied by the user; the official browser Turnstile session is not reusable in FastAPI.

The selected upstream Vitest suites could not execute in this environment because the repository's browser test configuration requires a Playwright Chromium binary that is not installed. No upstream test result is claimed; the call graphs above come from the pinned source and test assertions inspected directly.
