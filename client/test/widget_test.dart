import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hi_hat/core/theme.dart';
import 'package:hi_hat/features/search/search_screen.dart';

void main() {
  testWidgets('search surface exposes the primary task', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: HiHatTheme.dark,
        home: const ProviderScope(child: Scaffold(body: SearchScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('Hi Hat'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search for a song'), findsOneWidget);
    expect(find.text('FLAC'), findsOneWidget);
  });
}
