# Current Hi Hat backend resolution flow

The Flutter search screen's `_play` checks `localPath`. If absent, `DownloadService.acquire` posts to `/v1/downloads`, polls the job, downloads `/v1/downloads/{job}/file`, records the local track, and `AudioEngine` opens that local path.

Backend call graph:

`POST /v1/downloads` -> `DownloadManager._run` -> `ProviderManager.get` -> `MonochromeProvider.resolve_audio` -> acquisition -> `validate_audio` -> ready file.

Resolution details:

1. The legacy/public strategy calls `/track/?id=...`, not `/trackManifests`.
2. It accepts only a `FULL` asset and lossless manifest; the app requests `best_lossless` and the adapter currently resolves the service's returned lossless representation.
3. Instance order starts with samidy and is subsequently sorted by observed failure count.
4. Known-track responses are HTTP 403 from samidy and HTTP 503 from api.monochrome.tf.
5. A 401/403 becomes the internal `PUBLIC_INSTANCE_ACCESS_DENIED`; all instances are attempted.
6. Before this audit there was no current Unified Playback strategy.
7. The public strategy is derived from the older HiFi/public API contract and is not equivalent to current Monochrome playback/download resolution.

After this audit, an explicitly configured, user-authorized Unified Playback strategy is attempted first. It contains no bundled official token and no Turnstile implementation. The existing public-instance strategy remains fallback.
