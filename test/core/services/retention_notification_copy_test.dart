import 'package:drive_rank/core/services/retention_notification_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('personalRecordBody', () {
    test('speed copy names the new value', () {
      final body = RetentionNotificationCopy.personalRecordBody(
        kind: RecordCelebrationKind.speed,
        valueLabel: '184 km/h',
      );
      expect(body, contains('184 km/h'));
      expect(body, contains('top speed'));
    });

    test('distance copy names the new value', () {
      final body = RetentionNotificationCopy.personalRecordBody(
        kind: RecordCelebrationKind.distance,
        valueLabel: '51.3 km',
      );
      expect(body, contains('51.3 km'));
      expect(body, contains('longest trip'));
    });
  });

  group('weeklyRecapBody', () {
    test('includes trip count and distance, singular "trip" for one', () {
      final body = RetentionNotificationCopy.weeklyRecapBody(
        tripCount: 1,
        distanceLabel: '12 km',
        recordCount: 0,
      );
      expect(body, '1 trip · 12 km');
    });

    test('pluralises "trips" for more than one', () {
      final body = RetentionNotificationCopy.weeklyRecapBody(
        tripCount: 4,
        distanceLabel: '127 km',
        recordCount: 0,
      );
      expect(body, '4 trips · 127 km');
    });

    test('appends the record count when nonzero, singular', () {
      final body = RetentionNotificationCopy.weeklyRecapBody(
        tripCount: 4,
        distanceLabel: '127 km',
        recordCount: 1,
      );
      expect(body, '4 trips · 127 km · 1 personal record');
    });

    test('appends the record count when nonzero, plural', () {
      final body = RetentionNotificationCopy.weeklyRecapBody(
        tripCount: 4,
        distanceLabel: '127 km',
        recordCount: 2,
      );
      expect(body, '4 trips · 127 km · 2 personal records');
    });

    test('omits the record clause entirely when zero', () {
      final body = RetentionNotificationCopy.weeklyRecapBody(
        tripCount: 3,
        distanceLabel: '80 km',
        recordCount: 0,
      );
      expect(body, isNot(contains('record')));
    });
  });
}
