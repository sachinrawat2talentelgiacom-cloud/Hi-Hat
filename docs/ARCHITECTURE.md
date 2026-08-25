# Hi Hat architecture

```text
Flutter Android / Windows
          |
          | stable /v1 contract
          v
FastAPI + DownloadManager
          |
          | generic MusicProvider
          v
MonochromeProvider -> compatible Monochrome API instance
```

The client never receives upstream instance URLs, signed media URLs, manifests, or provider response objects. `MonochromeProvider` owns the current `/search/` and `/trackManifests/` contract, compatible-instance failover, manifest decoding, and provider error conversion.

Playback never opens a Monochrome URL. FastAPI acquires and validates a complete FLAC, the client transfers it into a `.part` file, verifies SHA-256, renames atomically, commits its Drift row, acknowledges completion, and opens the final local path through `media_kit`.

## Security boundary

- Only HTTPS media hosts on the explicit allowlist are accepted.
- DRM/encrypted manifests and access challenges are rejected.
- FFmpeg is invoked without a shell and with a restricted protocol list.
- LAN mode is opt-in and requires a bearer token.
- Public instances are treated as volatile dependencies; local playback is independent.

