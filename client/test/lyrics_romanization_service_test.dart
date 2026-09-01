import 'package:flutter_test/flutter_test.dart';
import 'package:hi_hat/services/lyrics_romanization_service.dart';

void main() {
  test('romanizes Japanese lyrics while preserving line breaks', () async {
    final result = await LyricsRomanizationService().romanize(
      'まだこの世界は\n僕を飼いならしてたいみたいだ',
    );

    final lines = result.split('\n');
    expect(lines, hasLength(2));
    expect(lines.first.toLowerCase(), contains('mada'));
    expect(lines.last.toLowerCase(), contains('boku'));
    expect(result, isNot(contains('世界')));
  });
}
