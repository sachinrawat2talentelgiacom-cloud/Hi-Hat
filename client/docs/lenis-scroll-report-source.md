# Lenis-style wheel scrolling for Hi Hat

Audience: Hi Hat maintainers  
Date: 2026-08-31

## Scope and answer

The goal was to reproduce Lenis's smooth wheel feel in Flutter without slowing touch input or repeatedly restarting an easing animation. The implemented controller accumulates normalized wheel input into a target offset and advances the displayed offset toward that target once per rendered frame.

## Evidence and implementation decisions

- Lenis describes its pipeline as normalizing wheel delta, adding it to `targetScroll`, and animating toward that target. Its default interpolation intensity is `0.1`. Hi Hat uses the same target/animated-position separation with a slightly more responsive `0.14` intensity. Source: [Lenis core source](https://github.com/darkroomengineering/lenis/blob/main/packages/core/src/lenis.ts), Darkroom Engineering, accessed 2026-08-31.
- Lenis advances its animation from `requestAnimationFrame` and accounts for elapsed time. Hi Hat uses Flutter's `Ticker`, supplied by the scroll context, and converts the interpolation coefficient using elapsed frame time so behavior is refresh-rate independent. Sources: [Lenis core source](https://github.com/darkroomengineering/lenis/blob/main/packages/core/src/lenis.ts); [Flutter ScrollContext.vsync](https://api.flutter.dev/flutter/widgets/ScrollContext/vsync.html), Flutter API documentation, accessed 2026-08-31.
- Flutter documents that a new `animateTo` cancels the active animation. Reissuing it for every wheel event therefore restarts the curve and causes uneven motion under repeated input. The new controller does not call `animateTo` for wheel smoothing. Source: [Flutter ScrollPosition.animateTo](https://api.flutter.dev/flutter/widgets/ScrollPosition/animateTo.html), Flutter API documentation, accessed 2026-08-31.
- The controller updates pixels from its own frame driver only after putting the standard scroll activity idle, following Flutter's warning that an active driven activity can otherwise overwrite forced pixels. Source: [Flutter ScrollPosition.forcePixels](https://api.flutter.dev/flutter/widgets/ScrollPosition/forcePixels.html), Flutter API documentation, accessed 2026-08-31.

Small high-resolution trackpad deltas remain unscaled. Coarse mouse-wheel notches retain the existing `0.58` multiplier. Touch dragging and programmatic scrolling stop the smoothing ticker immediately, and reduced-motion mode jumps directly to the target.

## Limitations

This reproduces Lenis's continuous interpolation model, not its browser-specific DOM, nested-scroll, or CSS behavior. Perceived smoothness can still be affected by expensive application rendering; the regression test verifies interpolation and target accumulation, while profile-mode frame timing is the appropriate follow-up if device-specific jank remains.

## Claim-to-source ledger

- Continuous target interpolation and frame advancement — Lenis core source, Darkroom Engineering, current main branch, accessed 2026-08-31, https://github.com/darkroomengineering/lenis/blob/main/packages/core/src/lenis.ts
- Cancellation behavior of `animateTo` — Flutter API documentation, accessed 2026-08-31, https://api.flutter.dev/flutter/widgets/ScrollPosition/animateTo.html
- Frame ticker provider — Flutter API documentation, accessed 2026-08-31, https://api.flutter.dev/flutter/widgets/ScrollContext/vsync.html
- Manual pixel update constraints — Flutter API documentation, accessed 2026-08-31, https://api.flutter.dev/flutter/widgets/ScrollPosition/forcePixels.html
