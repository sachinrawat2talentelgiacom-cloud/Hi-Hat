# Hi Hat

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter client for Android and Windows; Python 3.12+ FastAPI backend hosted on the user's Windows PC and reachable by Android over a trusted local network. Riverpod owns client state, Drift/SQLite owns local metadata, and media_kit owns local audio playback.

## Users

Hi Hat is for a personal/internal-use listener who values lossless music, wants to find a track with minimal interaction, and expects downloaded music to remain available offline on their Windows PC or Android device.

## Product Purpose

Hi Hat makes lossless listening direct: search, select a track, press Play, wait for the best permitted lossless source to download and validate, then listen from a permanent local copy. Success means the same local file can be played again without the backend, network, or provider.

## Positioning

Hi Hat combines a deliberately small search-to-play experience with explicit source quality and local ownership. Remote acquisition is a replaceable input; the local library and player are the product's durable center.

## Operating Context

- Windows may host both the Flutter desktop client and FastAPI backend.
- Android reaches FastAPI over a trusted private LAN for new searches and downloads.
- Existing local tracks remain browsable and playable when the PC, backend, network, or Monochrome is unavailable.
- The Windows listening context may include speakers, headphones, or an external DAC; Android may use its system audio routes.

## Capabilities and Constraints

- Search by track, artist, or album through a generic backend provider interface.
- Monochrome is the only initial remote provider and never communicates directly with Flutter.
- Download and validate the complete audio file before local playback; remote streaming is excluded.
- Prefer the highest verified supported lossless representation and never silently substitute lossy audio.
- Actual file inspection determines codec, sample rate, bit depth, channels, bitrate, duration, and quality labels.
- Do not bypass authentication, DRM, paywalls, CAPTCHAs, or access controls. Acquire only content the user is permitted to download.
- Local FLAC import and playback remain independent of remote acquisition.
- Imported files must pass FLAC header validation before entering the library; embedded title, artist, album, sample rate, bit depth, and channel metadata should be used when available.
- Preserve the downloaded source without transcoding or re-encoding. The device playback stack may still apply system-level mixing or conversion, which the UI must not misrepresent as bit-perfect output.
- Prioritize reliable decoding, stable playback, local-file reliability, honest quality display, and gapless-ready playback architecture before adding features.
- Support search, search results, player, local library, and minimal settings on Android and Windows.
- Playlists, recommendations, accounts, social features, cloud sync, podcasts, radio, and advanced library management are out of scope.

## Brand Commitments

The product name is Hi Hat. The experience must feel modern, minimal, premium, calm, fast, and audiophile-focused without copying a feature-heavy streaming service. Album artwork, track identity, playback state, and honest quality information are the visual priorities.

## Evidence on Hand

The product and development specifications are supplied externally. No logo, proprietary typeface, final artwork library, customer claims, or commercial evidence exists and none may be fabricated.

## Product Principles

1. Search and Play should be enough.
2. Playback reliability and local ownership outrank feature count.
3. Show verified quality honestly, including output fallbacks.
4. Provider volatility must not leak into the client or local library.
5. Polish comes from clarity, responsiveness, artwork, and precise interaction rather than added screens.

## Provider Boundary

Provider adapters remain replaceable behind the backend contract. A Lucida adapter may be added only for a documented endpoint the user is authorized to use; the product does not automate CAPTCHA or Cloudflare clearance and does not bypass authentication, DRM, subscriptions, paywalls, or other access controls.

## Accessibility & Inclusion

Honor Android Material interaction conventions, Windows keyboard and focus conventions, system text scaling, screen readers, reduced-motion preferences, high contrast, and touch targets of at least 48 logical pixels.
