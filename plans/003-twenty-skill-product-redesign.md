# Hi Hat: twenty-skill product redesign

## Outcome

Transform Hi Hat from a functional Material application with light styling into a recognizable, premium listening instrument. The redesign must be immediately visible on launch while preserving the proven search, acquisition, local-library, and playback paths.

Success is not “twenty documents.” Success is:

- a distinctive Hi Hat identity visible in the installed application;
- a redesigned adaptive shell, home, search, library, player, and settings experience;
- clear separation between brand expression and functional playback state;
- calm, meaningful motion with full reduced-motion behavior;
- verified accessibility, responsiveness, search, playback, and Windows build integrity.

## Creative direction

**Listening Instrument** combines three ideas:

1. **Brand layer:** warm charcoal, mineral paper, editorial orange, cymbal/wave mark, Poppins/Lora in expressive moments.
2. **Product layer:** chartreuse remains reserved for live/verified/selected/progress states; operational UI stays clean and native.
3. **Information layer:** album artwork, track identity, local ownership, verified source, and output path form a precise telemetry ledger.

Orange and chartreuse must never compete in one control. Orange identifies Hi Hat and editorial discovery; chartreuse communicates live product truth.

## Phase 0 — Baseline and safety net

1. Capture screenshots at 360, 700, 980, and 1320 logical pixels for Home, Search results, Library, full player, and Settings.
2. Add golden/widget coverage for shell topology, semantic labels, text scale, keyboard focus, and reduced motion.
3. Record startup, search-result, and large-library frame timings.
4. Preserve a live diagnostic script for PING, SEARCH, and local-only playback checks.

Exit: reproducible visual and functional baseline exists before redesign work.

## Phase 1 — Brand and design-system foundation

### Visible work

- Build a production, code-native `HiHatMark` from the approved cymbal + waveform + listening-gap concept; provide full lockup, compact mark, monochrome, and semantic variants.
- Make the new mark the app masthead, navigation identity, empty-art fallback, About identity, and Windows/Android icon source.
- Introduce explicit semantic tokens for brand orange, live chartreuse, information blue, local/ready green, chamber neutrals, focus, warning, and error.
- Add bundled, license-verified Poppins and Lora assets: Poppins for brand/display moments, Lora for editorial discovery copy, native system type for dense controls and technical data.
- Rebuild type and spacing tokens to match the documented hierarchy at all text scales.
- Produce a compact in-app brand specimen route available only in debug builds.

### Skill owners

- **brandkit:** logo metaphor, complete identity world, icon and application consistency.
- **brand-guidelines:** official palette/type application, brand voice, fallbacks, governance.
- **better-colors:** semantic color roles, dark/light schemes, contrast and state validation.
- **better-typography:** expressive/operational type split, hierarchy, line length, tabular readings.
- **industrial-brutalist-ui:** telemetry labels, hard rules, data density, instrument-like geometry.

Exit: the running app is unmistakably Hi Hat before any feature screen is opened.

## Phase 2 — Adaptive shell and navigation redesign

### Visible work

- Replace generic navigation identity with the new lockup and a status rail showing backend, local library, and current output state.
- Compact shell: edge-to-edge content, branded top identity, mini-player above native bottom navigation.
- Expanded shell: identity rail + working ledger + persistent listening instrument, with draggable or tokenized player width where appropriate.
- Add intentional empty, offline, backend-unavailable, and local-only shell states.
- Guarantee keyboard traversal, visible focus, safe areas, high contrast, screen-reader ordering, and minimum 48 px targets.

### Skill owners

- **better-layout:** topology, content widths, spacing rhythm, responsive breakpoints.
- **apple-hig-designer:** hierarchy, discoverability, platform adaptation, accessibility audit.
- **apple-ui-designer:** calm content-first composition and concise interaction language.
- **mobile-android-design:** Material 3 navigation, back behavior, touch ergonomics, Android safe areas.
- **design-taste-frontend:** anti-slop review applied to desktop composition—no generic dashboard/card grid or decorative hero excess.

Exit: resizing across four target widths produces intentional topology changes, not stretched layouts.

## Phase 3 — Home and search become the primary instrument

### Home: “Listening now”

- Replace the generic featured grid with a strong current-listening stage when a track exists.
- Add a quiet “Ready locally” strip sourced only from the user’s local library.
- Present discovery as an editorial field using artwork, orange brand labels, and restrained Lora copy; no fabricated recommendations or claims.
- Make offline/local-only mode useful instead of presenting a server error.

### Search: “Find → verify → own”

- Monumental command-like search field with recent local queries and keyboard shortcut affordance on Windows.
- Results become a scan-optimized ledger with provider state, verified/lossless status, ownership state, duration, and one primary play/acquire action.
- Progressive partial results appear without blocking on a failed provider; errors identify whether search, backend, provider, or network failed.
- Add deterministic loading, empty, retry, stale-cache, and offline-local-result states.

### Skill owners

- **redesign-existing-projects:** preserve task flow and data while rebuilding hierarchy and states.
- **better-ui:** actionable states, copy, affordances, feedback, semantics, and interaction completeness.
- **high-end-visual-design:** art direction, negative space, artwork framing, macro hierarchy, premium restraint.
- **impeccable:** final craft sweep against product intent, consistency, edge cases, and non-generic execution.

Exit: launch and search are substantially different in screenshots and remain one-action paths to playback.

## Phase 4 — Library and player as local-ownership proof

### Library

- Reframe Library as “Owned here,” with file availability, verified format, sample rate/bit depth, storage location, and last validation.
- Add compact/grid density choice without inventing advanced library management.
- Provide useful unavailable-file and rescanning states.

### Player

- Rebuild the expanded player as a calibrated instrument: dominant artwork, track identity, transport, honest acquisition phase, verified source, decoded-file facts, and output route.
- Full-screen player adopts the same instrument hierarchy on compact devices.
- Lyrics, when available, are secondary and never displace playback truth.
- Use brand orange for identity/editorial details; chartreuse only for playing, verified, progress, focus, and selection.

Exit: the player visibly communicates what is playing, what was verified, where it lives, and what output is active.

## Phase 5 — Motion system

The four motion skills run as separate stages so audits do not masquerade as implementation.

1. **animation-vocabulary:** publish the component/state motion vocabulary and shared names.
2. **find-animation-opportunities:** read-only audit across the redesigned flows; rank only comprehension-improving moments.
3. **improve-animations:** write ordered implementation plans under `plans/`, including reduced-motion substitutes and performance constraints.
4. **animate:** implement approved transitions—search/result state crossfade, mini/full-player continuity, acquisition phase change, queue insertion, and navigation selection—using opacity/transform where possible.
5. **review-animations:** independent read-only diff review; block layout animation, long easing, decorative loops, and reduced-motion failures.

Motion budget:

- micro feedback: 90–140 ms;
- state continuity: 180–240 ms;
- large player continuity: maximum 320 ms;
- no continuous shimmer, ambient loop, theatrical progress, or animation required to understand state.

Exit: approved animation review with no must-fix findings and stable frame timing.

## Phase 6 — Settings, onboarding cues, and final coherence

- Reorganize Settings into Connection, Library location, Playback/output, Appearance/accessibility, and About.
- Add inline connection testing and clear remediation for backend problems.
- Explain local ownership and verified-quality semantics in contextual first-use cues, not a multi-page onboarding flow.
- Add theme selection once both schemes pass contrast and screenshot validation.
- Apply the final **design-an-interface** workflow: produce at least three complete screen-system proposals in parallel, compare them against product principles, synthesize the winning details, and implement only after selection.

Exit: settings solve actual setup failures; the whole application feels like one designed system.

## Twenty-skill accountability matrix

| # | Skill | Required material contribution | Proof |
| --- | --- | --- | --- |
| 1 | animate | Implement approved interaction/state motion | Motion widget tests + recordings |
| 2 | animation-vocabulary | Name and specify the motion language | Motion specification |
| 3 | apple-hig-designer | Platform/accessibility audit and adaptive behavior | Audit checklist + fixes |
| 4 | apple-ui-designer | Content-first hierarchy and native interaction polish | Before/after screens |
| 5 | better-colors | Complete semantic dark/light color system | Contrast matrix + goldens |
| 6 | better-layout | Rebuild shell and responsive screen composition | Four-width goldens |
| 7 | better-typography | Brand/editorial/technical type system | Type specimen + scale tests |
| 8 | better-ui | Complete states, copy, affordances, and feedback | State inventory + widget tests |
| 9 | brand-guidelines | Govern logo, palette, typography, voice | Updated guide + in-app use |
| 10 | brandkit | Ownable identity and production applications | Code-native mark + icons |
| 11 | design-an-interface | Three proposals, comparison, synthesis | Proposal and decision record |
| 12 | design-taste-frontend | Desktop anti-generic composition review | Review checklist |
| 13 | find-animation-opportunities | Read-only ranked opportunity audit | Audit report |
| 14 | high-end-visual-design | Art direction and premium macro hierarchy | Visual QA board |
| 15 | impeccable | Product-wide craft and edge-case sweep | Final punch list at zero blockers |
| 16 | improve-animations | Motion implementation plan only | Ordered plan files |
| 17 | industrial-brutalist-ui | Technical ledger/instrument language | Library/player telemetry UI |
| 18 | mobile-android-design | Material, touch, safe area, back behavior | Android widget/device checks |
| 19 | redesign-existing-projects | Preserve behavior while changing structure | Flow parity matrix |
| 20 | review-animations | Read-only final animation review | Approval report |

## Verification gates

Every phase must pass:

- `dart format` and `flutter analyze` with no issues;
- all existing and new Flutter tests;
- Windows debug build with NuGet/WebView dependencies;
- compiled PING and SEARCH diagnostics;
- no regression in local FLAC import, metadata validation, queue, playback state, or offline library;
- screenshot review at 360, 700, 980, and 1320 logical pixels;
- text scales 1.0, 1.3, and 2.0; reduced motion; keyboard-only use; semantic traversal;
- `git diff --check` and a concise phase evidence update.

## Implementation order

1. Baseline and safety tests.
2. Brand mark, fonts, and semantic tokens.
3. Adaptive shell.
4. Home and Search.
5. Library and Player.
6. Settings and first-use cues.
7. Motion audit, plan, implementation, and review.
8. Full visual/accessibility/performance verification.

No phase is counted as “using a skill” until its proof artifact and running product change both exist, except skills that explicitly require a read-only audit or plan-only output.
