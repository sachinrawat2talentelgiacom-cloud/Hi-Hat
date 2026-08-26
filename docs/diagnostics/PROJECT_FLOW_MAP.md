# Project flow map

Audited: 2026-08-26

## Actual search path

```text
SearchScreen TextField.onChanged
  client/lib/features/search/search_screen.dart
  -> 300 ms Timer
SearchController.search
  client/lib/features/search/search_controller.dart
  -> Drift AppDatabase.searchLibrary
  -> ProviderSearchService.search
ProviderSearchService
  client/lib/services/provider_search_service.dart
  -> direct Dio HTTPS GET to configured Monochrome API instances
  -> Dart response traversal and TrackSummary mapping
SearchController
  -> request-generation check, local/remote deduplication
  -> AsyncValue.data or AsyncValue.error
SearchScreen
  -> Riverpod rebuild: results, bounded spinner, or error
```

There is no native SearchService, MethodChannel, provider WebView search, or
native-to-Flutter result serialization in the current code.

## Actual Play and acquisition path

```text
TrackResultTile.onTap
  -> SearchScreen._play
  -> AppDatabase.findByProviderId
     -> local hit: AudioEngine.playLocal -> media_kit Player.open
     -> local miss: push BrowserAcquisitionScreen
BrowserAcquisitionScreen
  -> InAppWebView loads monochrome.tf/track/<id>
  -> _onLoaded checks authorization and normal Download button
  -> _onDownloadStarted selects controlled acquisition destination
  -> _scanForCompletedFile waits for stable completed file
  -> _finalize calls LocalImportService.importForTrack
LocalImportService
  -> FlacMetadataReader.read
  -> full-duration comparison
  -> SHA-256 and deduplication
  -> managed .part write and atomic rename
  -> AppDatabase.saveTrack
  -> SearchScreen._play receives local TrackSummary
  -> AudioEngine.playLocal -> media_kit Player.open
```

The browser is embedded in `HiHat.exe`, but it is created per acquisition
route. No persistent startup WebView or native named-pipe diagnostic server is
implemented.
