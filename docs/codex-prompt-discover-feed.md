# Codex Task — Discover feed on the home page (genre preferences + big cover-art cards)

## Context

Hi Hat's home page is `SearchScreen` (page index 0 in `AppShell`), which currently renders only a search bar and an empty state until the user types a query. We want the home page to show a discover feed instead of nothing: user picks genre/type preferences, and gets random popular tracks rendered as large cover-art blocks with title + artist.

Key files:
- `client/lib/features/search/search_screen.dart` — current home page.
- `client/lib/features/shell/app_shell.dart` — hosts pages; `SearchScreen` is `pages[0]`.
- `client/lib/services/provider_search_service.dart` — `ProviderSearchService.search(query, {limit})` calls Monochrome `GET {instance}/search/?s=...` and returns `List<TrackSummary>`.
- `client/lib/models/track.dart` — `TrackSummary` already has `genre`, `artworkUrl`, `highResArtworkUrl`, `displayTitle`, `artist`, etc.
- `client/lib/widgets/track_artwork.dart` — existing artwork widget.
- `client/lib/services/track_playback_coordinator.dart` — `play(track, navigator)` starts acquisition/playback (reuse this, do NOT build a new download path).

## Hard data constraint (read this first)

Monochrome exposes **only** `/search/?s={query}` and `/track/?id=...`. There is no popular/chart/genre/discover/trend endpoint. Do **not** invent a new API contract or add backend routes.

The discover feed must be synthesized from search:
- Maintain a curated list of "popular" seed queries that broadly map to genres/moods, e.g. `pop hits`, `rock classics`, `hip hop`, `electronic`, `jazz`, `lo-fi`, `top 40`, `billboard hits`, `indie`, `r&b`, `classical`, `metal`, `country`, `ambient`, `dance`, etc.
- To render the feed, pick the user's selected preferences (or a default set), fire searches for those seed queries, merge/dedupe results, shuffle them, and show them as cards.
- Popularity is not available in the payload — do not fabricate play counts or rankings. "Popular" = drawn from popular-genre search queries and shuffled. The UI must not claim real chart data.

## Requirements

### 1. Genre/type preference chips on the home page
- Add a horizontal, wrap-friendly row of selectable chips above the discover grid (e.g. `All`, `Pop`, `Rock`, `Hip-Hop`, `Electronic`, `Jazz`, `R&B`, `Lo-Fi`, `Indie`, `Classical`, `Metal`, `Country`, `Ambient`, `Dance`).
- Multi-select. `All` means "no filter, use the default popular seeds."
- Persist the selection in `SharedPreferences` (single key, e.g. comma-separated or JSON list). Restore on app start.
- A chip tap should refresh the feed without a full page reload.

### 2. Discover feed (replaces the empty state)
- On first load (no search query typed), fetch and show the discover feed automatically. Do not wait for the user to type.
- On screen, each track is a **large cover-art block**: big square artwork (`highResArtworkUrl` preferred, fallback `artworkUrl`), overlaid or immediately below it the song title and artist name (use `displayTitle` and `artist`). Keep the existing design language (charcoal fields, mineral text, acid-chartreuse accent; artwork is the only vivid field).
- Responsive grid: `GridView`/`SliverGrid` with `SliverGridDelegateWithMaxCrossAxisExtent`. On compact screens show 1–2 columns; on wide screens show 3–5 columns. Cards should be visually large, not the small existing `TrackResultTile`.
- Include a "Refresh" action that re-fetches and reshuffles the feed.
- Include a loading state (spinner or shimmer) and a graceful error state that does not blame the user (consistent with the existing `_SearchMessage` empty/error states).

### 3. Interaction
- Tapping a card plays the track using the existing flow: `ref.read(trackPlaybackCoordinatorProvider).play(track, Navigator.of(context))`.
- Do not build new acquisition logic. Reuse the coordinator; it already handles local/remote and the acquisition overlay/dock.
- When the user actually types into the search box, the feed should yield to the normal search results (search takes priority over the discover feed). Clearing the search restores the discover feed.

### 4. Service layer
- Add a focused `DiscoveryService` (Riverpod provider) that:
  - Accepts a set of selected genres.
  - Maps genres → seed queries (keep the mapping in one place, easy to edit).
  - Runs searches via the existing `ProviderSearchService` (with the same failover/timeout behavior). If a search for one seed fails, skip it; the feed still shows whatever succeeded.
  - Merges results, dedupes by `providerTrackId` (or `id`), shuffles, and returns a bounded list (cap at ~30–60 to keep it responsive).
  - Is cached briefly in memory so switching tabs doesn't refetch every time.
- Expose a `DiscoveryController` (StateNotifier) with `AsyncValue<List<TrackSummary>>` so the UI can `watch` it, plus methods `setGenres(Set<String>)` and `refresh()`.

### 5. Preference selection flow
- The preference chips live on the home page itself (not buried in Settings), per the request: "I can select the preference of what I want and which type of music I want on the front page."
- Genre chip selection updates the controller, which re-runs the seed search and updates the grid.

## Constraints

- Follow existing Riverpod / StateNotifier patterns, `TrackSummary`, and `TrackArtwork`. No unrelated refactors.
- No new dependencies unless strictly necessary (the existing `shared_preferences`, `flutter_riverpod` are enough).
- Do not invent chart/popularity data; the feed is "popular-genre searches, shuffled." The copy must stay honest.
- Keep the existing search UX intact: typing a query shows search results; empty query shows the discover feed.

## Verification

1. `cd client && flutter analyze` — clean.
2. `cd client && flutter test` — all pass. Add tests for the genre→seed mapping and result dedupe/shuffle in the service layer where it's pure logic.
3. Manual:
   - Launch app → home shows large cover-art cards with title + artist immediately, no empty screen.
   - Tap several genre chips → feed changes and selection persists after restart.
   - Tap "Refresh" → feed reshuffles.
   - Tap a card → the track downloads/plays through the existing acquisition dock (no new window behavior changes).
   - Type in search → normal results replace the feed; clear search → feed returns.
   - Check compact and wide layouts for the grid.
