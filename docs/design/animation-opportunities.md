# Animation opportunity audit

This was a read-only audit. It did not modify application source.

| Priority | Component | Opportunity | Trigger | Properties | Duration / easing | Reduced motion | Decision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| High | Track card play control | Reveal without layout movement | Pointer hover or active playback | Opacity + vertical slide | 120 ms, ease-out cubic | No travel; immediate state | Implemented later |
| High | Reusable interactive surface | Subtle physical press response | Pointer/touch press | Scale to 0.96 | 120 ms, ease-out cubic | Immediate | Implemented later |
| Medium | Home/search loading | Preserve expected content structure | Async loading | Static skeleton blocks | No continuous animation | Already static | Implemented later |
| Medium | Async state replacement | Gentle state continuity | Infrequent loading/error/data change | Opacity crossfade | 220 ms, ease-out cubic | Immediate | Deferred |

Rejected candidates: route navigation, scrolling track data, search submission, playback progress, artwork shimmer, and decorative ambient motion. They add latency, distraction, or accessibility risk without improving comprehension.
