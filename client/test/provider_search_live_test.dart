import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/services/discovery_service.dart';
import 'package:hi_hat/services/provider_search_service.dart';

void main() {
  test('live catalog search returns usable track metadata', () async {
    if (Platform.environment['HIHAT_LIVE_SEARCH'] != '1') return;

    final results = await ProviderSearchService().search('circles', limit: 10);

    expect(results, isNotEmpty);
    expect(
      results.any((track) => track.title.toLowerCase() == 'circles'),
      isTrue,
    );
    expect(results.every((track) => track.providerTrackId.isNotEmpty), isTrue);
    expect(results.every((track) => track.artist.trim().isNotEmpty), isTrue);
  }, skip: Platform.environment['HIHAT_LIVE_SEARCH'] != '1');

  test(
    'live discovery composes concurrent artist and genre searches',
    () async {
      final provider = ProviderSearchService();
      final discovery = DiscoveryService(provider.search);

      final results = await discovery.buildFeed(
        artists: const ['Daft Punk'],
        genres: const {'Ambient'},
      );

      expect(results, isNotEmpty);
      expect(results.length, lessThanOrEqualTo(DiscoveryService.maximumTracks));
      expect(
        results.map((track) => track.providerTrackId).toSet().length,
        results.length,
      );
    },
    skip: Platform.environment['HIHAT_LIVE_SEARCH'] != '1',
  );
}
