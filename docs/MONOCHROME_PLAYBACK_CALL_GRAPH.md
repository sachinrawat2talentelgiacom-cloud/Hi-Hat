# Upstream Monochrome playback call graph

At upstream commit `7a2fbeaaab95b8a9f6c8112ad9d71340214582d1`:

Play/queue -> player -> `MusicAPI.getStreamUrl` -> `LosslessAPI.getStreamUrl` -> metadata -> Unified Playback with `intent=stream` -> ISRC Deezer fallback -> native audio/Shaka handling for direct, DASH, HLS, or supported encrypted Amazon playback.

Playback and download share provider resolution concepts, but use different intent values and downstream consumers. Hi Hat correctly prefers the download intent because its product flow acquires, validates, stores, and then plays a local file.
