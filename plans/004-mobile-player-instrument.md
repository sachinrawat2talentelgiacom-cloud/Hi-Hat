# Mobile player instrument redesign

## Outcome

Replace the desktop-derived compact full-player layout with a phone-first playback instrument while preserving every playback action, queue behavior, lyrics and translation, verified quality, output reporting, keyboard behavior on desktop, and reduced-motion handling.

## Audit findings

1. `full_player_screen.dart` uses a fixed 188 logical-pixel compact control deck and scales eight controls through `FittedBox`. On 320dp phones, the targets look tiny even though their hit regions are difficult to understand.
2. Compact mode places 40px immersive lyrics in the same scrolling column as artwork and identity. Playback truth loses priority and the page develops nested scrolling.
3. The 128px app bar and full-screen 38-sigma blur spend too much phone height and GPU budget before the primary controls.
4. Quality and output facts are absent from the compact full-screen hierarchy even though they are central product commitments.
5. Active-line auto-follow takes 420ms, which feels slow for a frequently repeating state update.

## Direction

Use the existing Calibrated Silence system: a clean chamber surface, album art as the only large color field, mineral type, and chartreuse only for live playback state. Use Material controls and Android safe areas, with 48dp minimum targets. Avoid glass, decorative meters, visualizer graphics, nested cards, ambient motion, and streaming-service chrome.

## Implementation

1. Keep the existing immersive two-column desktop player at 860dp and above.
2. Add a dedicated compact stage below 860dp with explicit portrait and short-landscape compositions.
3. Portrait order: artwork, track identity, seek/timing, previous/seek/play/seek/next transport, then shuffle plus quality/output plus repeat.
4. Keep Lyrics and Queue as focused Material bottom sheets opened from the app bar. This removes nested scrolling while keeping both one tap away.
5. Use a 64dp compact app bar and a flat tonal background. Do not blur a full-screen album image on compact devices.
6. Shorten active lyric auto-follow to 220ms with the existing ease-out curve and preserve the immediate reduced-motion path.

## Verification

- [x] Widget tests at 320x568, 320x800, 640x360, and 1440x900.
- [x] Confirm visible controls stay inside bounds and core transport targets are at least 48dp.
- [x] Confirm the Lyrics sheet opens from the compact app bar.
- [x] Confirm long titles, 200% text scale, zero-duration handling, quality pending, shuffle/repeat states, and reduced motion remain safe.
- [x] Run `dart format`, `flutter analyze`, and the complete Flutter test suite.
- [x] Render and inspect the 320x800 compact player before shipping.
- [x] Produce release Android and Windows artifacts.
