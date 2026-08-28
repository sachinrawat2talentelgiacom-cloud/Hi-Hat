# Twenty-skill redesign execution

The redesign is implemented in the running Flutter product. The rendered Windows evidence is [hi-hat-redesign-windows.png](../screenshots/hi-hat-redesign-windows.png).

## Material product changes

- Replaced the generic 240 px playlist sidebar, profile avatar, notification chrome, and desktop mini-player with an identity rail, focused working ledger, explicit transfer/local status, and persistent listening instrument.
- Added a production code-native cymbal/wave/listening-gap mark and full Hi Hat lockup.
- Bundled licensed Poppins and Lora fonts for offline Windows and Android rendering, while retaining system type for dense operational data.
- Split the accent system: editorial orange identifies Hi Hat; chartreuse communicates playing, verified, selected, focused, or progressing state; green communicates local ownership.
- Rebuilt Home around current listening and locally owned tracks before discovery.
- Rebuilt Search around the monumental “Find. Verify. Own.” command and underlined field.
- Reframed Library as “Owned here,” with verified/offline archive readings instead of a promotional first-track hero.
- Expanded the player truth ledger with source, owned-file path, output, stream, acoustic, catalog, and archive facts.
- Reframed Settings as a flat setup console with truthful playback wording, system accessibility behavior, identity, and use boundary.
- Added reduced-motion-safe destination transitions and disabled artwork Hero travel under reduced motion.

## Skill proof

| Skill | Shipped contribution |
| --- | --- |
| animate | Composited hover/press feedback and destination fades with zero-duration reduced-motion behavior. |
| animation-vocabulary | Shared fade, slide, press scale, state replacement, and skeleton terminology in plans/reviews. |
| apple-hig-designer | Content-first hierarchy, readable states, semantics, focus, safe area, and platform preference handling. |
| apple-ui-designer | Calm identity strip, restrained surfaces, concise labels, and native controls. |
| better-colors | Brand and product-truth domains, semantic ownership color, true light/dark schemes, and contrast discipline. |
| better-layout | 92 px rail, adaptive 360/440 px player, compact navigation stack, bounded ledgers, and structural skeletons. |
| better-typography | Bundled Poppins/Lora roles, operational system type, tabular time/metadata, and rebuilt display hierarchy. |
| better-ui | New shell states, intent-based destinations, clear acquisition/local status, copy, tooltips, and 48 px targets. |
| brand-guidelines | Official palette/type/voice applied in the running product and governed under `docs/brand`. |
| brandkit | Original cymbal/wave identity translated from presentation board into a scalable code-native production mark. |
| design-an-interface | Three independent proposals were synthesized: minimal reusable surfaces, common listening flow, and adaptive topology. |
| design-taste-frontend | Removed generic dashboard/sidebar/profile patterns and avoided gratuitous cards, gradients, and giant promotional UI. |
| find-animation-opportunities | Read-only ranked opportunity audit limited motion to comprehension and direct feedback. |
| high-end-visual-design | Strong macro hierarchy, deliberate negative space, artwork dominance, sparse palette, and real rendered QA. |
| impeccable | Product-wide craft sweep corrected false bit-perfect wording, transient server behavior, overflow, fallback, and consistency issues. |
| improve-animations | Ordered plan-only artifacts defined composited hover and structural state-loading work before implementation. |
| industrial-brutalist-ui | Flat telemetry ledgers, explicit rules, uppercase readings, technical truth, and instrument geometry. |
| mobile-android-design | Material 3 topology, safe-area shell, compact player/nav stack, touch sizing, and native back-compatible routes. |
| redesign-existing-projects | Preserved Riverpod, Drift, provider, download, validation, queue, and playback behavior while replacing the visible structure. |
| review-animations | Independent read-only review found and then verified the reduced-motion Hero fix; final verdict approved. |

## Runtime QA result

The actual 1280×720 Windows process was captured through its native window handle. That run exposed a 17 px transport overflow in the 360 px player; spacing was corrected while retaining 48 px action targets, hot reload produced no further rendering exception, and the accepted screenshot was captured afterward.
