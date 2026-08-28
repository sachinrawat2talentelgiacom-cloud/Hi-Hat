# Composited track-card feedback

Commit: `5b1bdf2`

## Problem

`client/lib/widgets/app_widgets.dart` uses `AnimatedPositioned` to move the play control from `bottom: -45` to `bottom: 8`. This animates layout for a frequent hover interaction and does not consult `MediaQuery.disableAnimations`.

## Target

- Keep the control at its settled position and animate only opacity plus a vertical transform.
- Use the existing `HiHatTokens.motionFast` duration (120 ms) and `Curves.easeOutCubic`.
- When platform animations are disabled, keep the control at its settled transform and change only its static visibility.
- Preserve the always-visible playing state and the existing click target.

## Steps

1. In `TrackCardBlock`, read `MediaQuery.disableAnimationsOf(context)`.
2. Replace `AnimatedPositioned` with a fixed `Positioned(bottom: 8, right: 8)`.
3. Wrap the control in `AnimatedSlide`, from `Offset(0, .25)` to `Offset.zero`, and `AnimatedOpacity`.
4. Use zero translation when animations are disabled.
5. Keep hover motion desktop-only through the existing `MouseRegion`; touch continues to use the static card and long press.

## Scope boundaries

Do not animate artwork, navigation, track-list rows, seek progress, or scrolling content.

## Verification

- Run `flutter analyze` and widget tests.
- Hover rapidly in and out; the transition must retarget without jumping.
- Enable Windows animation effects off and verify that the control does not travel.
- Inspect at slow speed: no layout shift should occur around the artwork.
