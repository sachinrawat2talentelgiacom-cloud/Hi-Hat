import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/services/provider_search_service.dart';
import 'package:hi_hat/features/search/search_controller.dart';

void main() {
  test('provider search exposes the intended cache duration', () {
    expect(ProviderSearchService.cacheTtl, const Duration(minutes: 7));
  });

  test('search watchdog is bounded to three ten-second attempts', () {
    expect(SearchController.searchTimeout, const Duration(seconds: 10));
    expect(SearchController.maxSearchAttempts, 3);
  });
}
