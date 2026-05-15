import 'package:drive_rank/features/onboarding/domain/entities/car_make.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CarMake.fromJson', () {
    test('parses required fields', () {
      final m = CarMake.fromJson(const {
        'id': 'toyota',
        'name': 'Toyota',
        'popularIn': <String>['PK', 'JP'],
        'models': <String>['Corolla', 'Camry'],
      });
      expect(m.id, 'toyota');
      expect(m.name, 'Toyota');
      expect(m.popularIn, {'PK', 'JP'});
      expect(m.models, ['Corolla', 'Camry']);
    });

    test('treats missing popularIn/models as empty (forwards-compatible)', () {
      final m = CarMake.fromJson(const {'id': 'x', 'name': 'X'});
      expect(m.popularIn, isEmpty);
      expect(m.models, isEmpty);
    });
  });

  group('CarMake.isPopularIn', () {
    final toyota = CarMake.fromJson(const {
      'id': 'toyota',
      'name': 'Toyota',
      'popularIn': <String>['PK', 'JP'],
      'models': <String>['Corolla'],
    });

    test('returns true when country code is in popularIn', () {
      expect(toyota.isPopularIn('PK'), isTrue);
    });

    test('returns false when country code is absent', () {
      expect(toyota.isPopularIn('FR'), isFalse);
    });
  });

  test('equality is by id', () {
    final a = CarMake.fromJson(const {
      'id': 'x',
      'name': 'X1',
      'popularIn': <String>[],
      'models': <String>[],
    });
    final b = CarMake.fromJson(const {
      'id': 'x',
      'name': 'X2',
      'popularIn': <String>['US'],
      'models': <String>['Anything'],
    });
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });
}
