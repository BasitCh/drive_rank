import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapTheme', () {
    test('id round-trips through fromId', () {
      for (final t in MapTheme.values) {
        expect(MapTheme.fromId(t.id), t);
      }
    });

    test('unknown id falls back to regular', () {
      expect(MapTheme.fromId('not-a-real-theme'), MapTheme.regular);
    });

    test('every theme exposes a non-empty label and glyph', () {
      for (final t in MapTheme.values) {
        expect(t.label, isNotEmpty);
        expect(t.glyph, isNotEmpty);
      }
    });
  });
}
