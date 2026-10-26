import 'package:flutter_test/flutter_test.dart';
import 'package:gitfruffen/core/widgets/command_palette.dart';

void main() {
  group('paletteMatches', () {
    test('empty query matches', () {
      expect(paletteMatches('', 'Open repository'), isTrue);
      expect(paletteMatches('   ', 'Open repository'), isTrue);
    });

    test('matches an ordered subsequence', () {
      expect(paletteMatches('orep', 'Open repository'), isTrue);
    });

    test('matches regardless of case', () {
      expect(paletteMatches('OPEN', 'Open repository'), isTrue);
    });

    test('rejects a non-subsequence', () {
      expect(paletteMatches('xyz', 'Open repository'), isFalse);
    });
  });
}
