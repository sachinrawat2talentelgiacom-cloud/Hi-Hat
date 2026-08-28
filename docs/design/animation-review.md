# Animation review

Verdict: approved after fixes.

| Severity | Finding | Resolution |
| --- | --- | --- |
| Must fix | `AnimatedPositioned` caused layout work during frequent card hover. | Replaced with fixed positioning plus composited `AnimatedSlide` and `AnimatedOpacity`. |
| Must fix | Hover motion did not follow the platform reduced-motion preference. | Added `MediaQuery.disableAnimationsOf` and zero-duration/no-travel behavior. |
| Should fix | Timing was inconsistent and the hover shadow added visual noise. | Standardized at 120 ms `easeOutCubic`; removed the decorative shadow. |
| Should fix | Generic spinning loaders did not explain the incoming layout. | Replaced with semantic, static grid and ledger skeletons. |
| Must fix | Artwork Hero transitions could still travel under the platform reduced-motion preference. | `TrackArtwork` now omits Hero participation when animations are disabled. |
| Pass | Destination replacement could have introduced layout travel during shell redesign. | Uses a 180–220 ms `AnimatedSwitcher` fade and becomes immediate under reduced motion. |
| Pass | Interactive surface and track-card feedback must remain interruptible and composited. | Scale, slide, and opacity are 120 ms `easeOutCubic`; no continuous loops were introduced. |

Remaining animation is brief, interruptible, transform/opacity based, and attached to user intent. Playback progress remains functional state rather than ornamental motion.
