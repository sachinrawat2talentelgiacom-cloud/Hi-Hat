import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/services/provider_search_service.dart';
import 'package:hi_hat/features/search/search_controller.dart';

void main() {
  test('provider search exposes the intended cache duration', () {
    expect(ProviderSearchService.cacheTtl, const Duration(minutes: 7));
  });

  test('provider search starts with the current Monochrome catalog API', () {
    expect(
      ProviderSearchService.catalogSearchEndpoints.first,
      'https://api.tidal.com/v1/search/tracks',
    );
  });

  test('search watchdog is bounded to three ten-second attempts', () {
    expect(SearchController.searchTimeout, const Duration(seconds: 10));
    expect(SearchController.maxSearchAttempts, 3);
  });
}
