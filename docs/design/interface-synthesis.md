# Interface proposal synthesis

Three independent proposals were evaluated:

1. A minimal reusable semantic surface with hover, press, roles, and reduced motion.
2. A policy-driven adaptive surface system with broader layout and breakpoint abstractions.
3. A unified listening surface combining discovery, queue, and playback context.

The minimal surface was selected because it solved duplicated interaction behavior with the smallest API and lowest migration risk. The policy system was deferred as premature infrastructure. The unified listening concept is valuable for a future navigation redesign but exceeded the current repair scope.

The selected result is `client/lib/widgets/hi_hat_surface.dart`, used by search album results and available for progressive adoption elsewhere.
