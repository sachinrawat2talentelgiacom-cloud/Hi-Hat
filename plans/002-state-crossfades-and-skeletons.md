# State crossfades and structural skeletons

Commit: `5b1bdf2`

## Problem

Home and search loading states replace the final content with generic circular progress indicators. The change is visually abrupt and does not preserve the structure users are waiting for.

## Target

- Replace generic full-screen spinners with static, layout-matched skeletons.
- Crossfade only occasional loading/error/data state changes using `AnimatedSwitcher` and `HiHatTokens.motionBase` (220 ms), `Curves.easeOutCubic`.
- Under `MediaQuery.disableAnimations`, use `Duration.zero`.
- Do not shimmer continuously; calm static tonal blocks fit Hi Hat and reduced-motion requirements.

## Steps

1. Add reusable `HiHatSkeleton` and `HiHatStateTransition` widgets under `client/lib/widgets/`.
2. Use semantic labels such as `Loading discovery tracks` and exclude decorative skeleton blocks from semantics.
3. Replace Home and Search circular loading states with skeleton arrangements matching their hero/grid and ledger shapes.
4. Key loading, error, empty, and data children so the crossfade is deterministic.
5. Keep retry actions and local/offline messaging reachable.

## Scope boundaries

Do not animate route navigation, keyboard search submission, progress values, or the playback timeline.

## Verification

- Run `flutter analyze` and all Flutter tests.
- Test at 360, 700, 980, and 1320 logical pixels.
- Verify text scaling and semantics do not announce decorative blocks.
- Disable platform animations and confirm state changes become immediate.
