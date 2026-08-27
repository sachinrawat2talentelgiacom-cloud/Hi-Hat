# Codex Task — Artist-based home feed (select artists, auto-load similar songs on launch)

## Context

Hi Hat's home page is `SearchScreen` (`AppShell` page 0). Today it shows only a search bar + empty state until the user types. We want:
- A first-run (and editable) flow where the user selects artists they like.
- The selection is stored locally and read automatically every time the app/exe launches.
- On the home page, without the user typing anything, show a feed built from (a) tracks by the selected artists and (b) genre-similar tracks — merged, deduplicated, shuffled — rendered as large cover-art cards with title + artist.

Key files:
- `client/lib/features/search/search_screen.dart` — home page.
- `client/lib/features/shell/app_shell.dart` — hosts `pages[0] = SearchScreen`.
- `client/lib/services/provider_search_service.dart` — `search(query, {limit})` → `GET {instance}/search/?s=...` → `List<TrackSummary>`.
- `client/lib/models/track.dart` — `TrackSummary` (has `artist`, `title`, `artworkUrl`, `highResArtworkUrl`, `displayTitle`).
- `client/lib/widgets/track_artwork.dart` — existing artwork widget.
- `client/lib/services/track_playback_coordinator.dart` — `play(track, navigator)`; reuse for card taps, do NOT build new acquisition logic.

## Hard data constraints (read first — do not invent APIs)

- Monochrome exposes **only** `GET {instance}/search/?s={query}` and `GET {instance}/track/?id=...`. No artist, popular, chart, recommendation, genre, or "similar" endpoint exists.
- The current `ProviderSearchService._mapTrack` does **not** populate `TrackSummary.genre` (it is always null in practice). So there is no real genre signal per track.

Therefore:
- "Tracks by selected artists" = search `"{artist}"` for each selected artist and collect the results.
- "Similar tracks" must be synthesized from genre/mood seed queries (e.g. `pop`, `rock`, `hip hop`, `electronic`, `jazz`, `lo-fi`, `indie`, `classical`, `metal`, `country`, `dance`, `r&b`, `ambient`). Since per-track genre is absent, derive a genre tag for each selected artist from a small, editable static `artist → genres` map where possible, and also let the user optionally pick genre chips. Fall back to a default "popular" seed set when genre is unknown. The UI must stay honest — no fabricated chart/rank data.

## Requirements

### 1. Artist selection (first run + editable)
- On first launch with no stored artists, show an artist-pick onboarding surface (dialog or dedicated screen): a text field that searches by artist name, shows matching tracks/artists, and lets the user add artist names to a saved list. Also allow choosing genre/type chips here.
- Store the selected artist names as a list (and any genre chips) in `SharedPreferences` (JSON or delimited string). Restore on startup.
- Make the selection editable later from the home page (an "Edit artists" / preferences affordance) so the user can add/remove artists without reinstalling.

### 2. Auto-load feed on launch
- On app start, read the stored artist list. If non-empty, automatically fetch and build the home feed. The user must never see an empty home screen.
- If no artists are stored yet, show the onboarding picker, and after selection immediately build the feed.

### 3. Feed composition
- For each selected artist: search the artist name, keep those tracks (their own songs).
- For the "similar" portion: for each artist, resolve a genre tag from the static `artist→genres` map (fallback to the user's genre chips or a default seed list), then search those genre seeds and keep those tracks, excluding tracks that are already the artist's own (by `providerTrackId`).
- Merge own + similar, dedupe by `providerTrackId`, shuffle, cap at ~30–60 tracks.
- If any individual search fails, skip it silently and still show whatever succeeded. Only show an error state if every search failed.

### 4. Home page rendering
- Large cover-art grid (not the small `TrackResultTile`): big square artwork (`highResArtworkUrl` preferred, fallback `artworkUrl`) with `displayTitle` and `artist` beneath/overlaid. Responsive: 1–2 columns compact, 3–5 wide. Keep the existing charcoal/mineral/chartreuse design language; artwork is the only vivid field.
- Loading state (spinner/shimmer) and a graceful, non-blaming error state consistent with existing `_SearchMessage`.
- "Refresh" action re-fetches + reshuffles.
- Tapping a card plays via `ref.read(trackPlaybackCoordinatorProvider).play(track, Navigator.of(context))`.
- When the user types a query, normal search results take priority; clearing the query restores the feed.

### 5. Service/controller layer
- `DiscoveryService` (Riverpod provider): takes selected artists + genres, maps artists→genre seeds (via the static map) and genres→seed queries, runs searches through the existing `ProviderSearchService` (same failover/timeout), merges/dedupes/shuffles, and returns a bounded `List<TrackSummary>`.
- `DiscoveryController` (StateNotifier) exposing `AsyncValue<List<TrackSummary>>`, plus `setArtists(List<String>)`, `setGenres(Set<String>)`, `refresh()`, and a method to load/save from `SharedPreferences`.
- `ArtistPreferencesStore` (or similar) owning `SharedPreferences` read/write of the artist list and genre chips. Keep the `artist→genres` seed map in one obvious, editable location.

## Constraints

- Follow existing Riverpod / StateNotifier / `TrackSummary` / `TrackArtwork` patterns. No unrelated refactors.
- No new dependencies unless strictly necessary.
- Do not add backend routes or invent provider endpoints. Everything is synthesized from `/search/`.
- Keep search-priority behavior intact: typed query shows results, empty query shows the artist feed.

## Verification

1. `cd client && flutter analyze` — clean.
2. `cd client && flutter test` — all pass; add pure-logic tests for artist→genre mapping, dedupe, and shuffle.
3. Manual:
   - Fresh install → artist picker appears → select artists → feed appears immediately.
   - Relaunch app/exe → feed auto-loads from stored artists, no empty screen.
   - Add/remove an artist → feed updates and persists after restart.
   - Tap card → plays through existing acquisition dock.
   - Type search → results replace feed; clear → feed returns.
   - Check compact and wide grid layouts.
