# Upstream Monochrome download call graph

At upstream commit `7a2fbeaaab95b8a9f6c8112ad9d71340214582d1`:

`downloadTracks`/album/playlist handler -> `downloadTrackBlob` -> `MusicAPI.downloadTrack` -> `LosslessAPI.downloadTrack` -> `enrichTrack` -> track metadata -> Unified Playback `GET /api/v2/track` with `intent=download` -> ISRC Deezer fallback when unresolved -> normalized resource -> direct, `DashDownloader`, or `HlsDownloader` -> post-processing/metadata -> Blob/browser or local-media writer.

In dev mode, `enrichTrack` instead calls `getTrackFromDevMode`, which uses the user-configured endpoint's `/trackManifests/` contract.

This is not the same flow as Hi Hat's former public `/track/`-only resolver.
