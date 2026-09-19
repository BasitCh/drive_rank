import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_trip.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/consistency_qualification_policy.dart';
import 'package:drive_rank/features/social/domain/usecases/calculate_consistency.dart';
import 'package:drive_rank/features/social/domain/usecases/calculate_distance.dart';
import 'package:drive_rank/features/social/domain/usecases/calculate_longest_trip.dart';
import 'package:drive_rank/features/social/domain/usecases/competition_metric_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var nextId = 1;

  CompetitionTrip tripOn(
    DateTime startedAt, {
    double distanceKm = 10,
    int durationSeconds = 600,
    bool eligible = true,
  }) {
    return CompetitionTrip(
      tripId: nextId++,
      startedAt: startedAt,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      eligible: eligible,
      utcOffsetMinutes: startedAt.timeZoneOffset.inMinutes,
    );
  }

  // The week of Mon 2026-08-31 .. Sun 2026-09-06.
  final week = CompetitionWindow(
    start: DateTime(2026, 8, 31),
    end: DateTime(2026, 9, 7),
  );

  group('distance', () {
    test('sums eligible trips inside the window', () {
      final value = calculateDistanceKm(
        trips: [
          tripOn(DateTime(2026, 8, 31), distanceKm: 12.5),
          tripOn(DateTime(2026, 9, 3), distanceKm: 30),
        ],
        window: week,
      );
      expect(value, 42.5);
    });

    test('excludes trips outside the window', () {
      final value = calculateDistanceKm(
        trips: [
          tripOn(DateTime(2026, 8, 30, 23, 59), distanceKm: 100),
          tripOn(DateTime(2026, 9, 7), distanceKm: 100),
          tripOn(DateTime(2026, 9, 1), distanceKm: 5),
        ],
        window: week,
      );
      expect(value, 5);
    });

    test('excludes ineligible trips', () {
      final value = calculateDistanceKm(
        trips: [
          tripOn(DateTime(2026, 9, 1), distanceKm: 40, eligible: false),
          tripOn(DateTime(2026, 9, 2), distanceKm: 8),
        ],
        window: week,
      );
      expect(value, 8);
    });

    test('a trip crossing midnight counts once, in the period its start '
        'falls in — never split across two', () {
      final value = calculateDistanceKm(
        // Starts Sunday 23:50, ends after the window closed.
        trips: [tripOn(DateTime(2026, 9, 6, 23, 50), distanceKm: 25)],
        window: week,
      );
      expect(value, 25);
    });

    test('is 0 with no trips', () {
      expect(calculateDistanceKm(trips: [], window: week), 0);
    });
  });

  group('longest trip', () {
    test('takes the max eligible distance in the window', () {
      final value = calculateLongestTripKm(
        trips: [
          tripOn(DateTime(2026, 9, 1), distanceKm: 12),
          tripOn(DateTime(2026, 9, 2), distanceKm: 51.3),
          tripOn(DateTime(2026, 9, 3), distanceKm: 30),
        ],
        window: week,
      );
      expect(value, 51.3);
    });

    test('ignores a longer ineligible trip', () {
      final value = calculateLongestTripKm(
        trips: [
          tripOn(DateTime(2026, 9, 1), distanceKm: 900, eligible: false),
          tripOn(DateTime(2026, 9, 2), distanceKm: 20),
        ],
        window: week,
      );
      expect(value, 20);
    });

    test('ignores a longer trip from another window', () {
      final value = calculateLongestTripKm(
        trips: [
          tripOn(DateTime(2026, 9, 20), distanceKm: 900),
          tripOn(DateTime(2026, 9, 2), distanceKm: 20),
        ],
        window: week,
      );
      expect(value, 20);
    });

    test('is 0 with no trips', () {
      expect(calculateLongestTripKm(trips: [], window: week), 0);
    });
  });

  group('consistency', () {
    test('counts distinct qualifying days, not trips', () {
      final value = calculateConsistencyDays(
        trips: [
          tripOn(DateTime(2026, 9, 1, 8)),
          tripOn(DateTime(2026, 9, 1, 18)),
          tripOn(DateTime(2026, 9, 2, 9)),
        ],
        window: week,
      );
      expect(value, 2);
    });

    test('a trip under the distance floor earns no day', () {
      final value = calculateConsistencyDays(
        trips: [tripOn(DateTime(2026, 9, 1), distanceKm: 0.7)],
        window: week,
      );
      expect(value, 0);
    });

    test('a trip under the duration floor earns no day, even a long one '
        '— the floors are AND-ed', () {
      final value = calculateConsistencyDays(
        trips: [
          tripOn(
            DateTime(2026, 9, 1),
            distanceKm: 40,
            durationSeconds: 120,
          ),
        ],
        window: week,
      );
      expect(value, 0);
    });

    test('a trip exactly on both floors qualifies', () {
      final value = calculateConsistencyDays(
        trips: [
          tripOn(DateTime(2026, 9, 1), distanceKm: 1, durationSeconds: 300),
        ],
        window: week,
      );
      expect(value, 1);
    });

    test('one qualifying trip carries the day even when other trips that '
        'day fall short', () {
      final value = calculateConsistencyDays(
        trips: [
          tripOn(DateTime(2026, 9, 1, 8), distanceKm: 0.4),
          tripOn(DateTime(2026, 9, 1, 18), distanceKm: 20),
        ],
        window: week,
      );
      expect(value, 1);
    });

    test('an ineligible trip earns no day', () {
      final value = calculateConsistencyDays(
        trips: [tripOn(DateTime(2026, 9, 1), eligible: false)],
        window: week,
      );
      expect(value, 0);
    });

    test('days are bucketed in local time even when the timestamp arrives '
        'UTC-flavored — reading .day off a UTC DateTime would put an '
        'early-morning local drive on the previous day', () {
      final utcMorning = DateTime.utc(2026, 9, 1, 2);
      final value = calculateConsistencyDays(
        trips: [tripOn(utcMorning), tripOn(utcMorning.toLocal())],
        window: CompetitionWindow(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 10, 1),
        ),
      );
      // Same instant expressed two ways must collapse to one day.
      expect(value, 1);
    });

    test('a full week of driving is 7', () {
      final value = calculateConsistencyDays(
        trips: [
          for (var day = 31; day <= 31; day++) tripOn(DateTime(2026, 8, day)),
          for (var day = 1; day <= 6; day++) tripOn(DateTime(2026, 9, day)),
        ],
        window: week,
      );
      expect(value, 7);
    });

    test('honours a custom policy', () {
      final value = calculateConsistencyDays(
        trips: [tripOn(DateTime(2026, 9, 1), distanceKm: 3)],
        window: week,
        policy: const ConsistencyQualificationPolicy(minimumDistanceKm: 5),
      );
      expect(value, 0);
    });
  });

  group('DefaultCompetitionMetricCalculator', () {
    const calculator = DefaultCompetitionMetricCalculator();
    final trips = [
      tripOn(DateTime(2026, 9, 1), distanceKm: 10),
      tripOn(DateTime(2026, 9, 2), distanceKm: 30),
    ];

    test('dispatches each metric to its own calculation', () {
      expect(
        calculator.calculate(
          metric: CompetitionMetric.distance,
          trips: trips,
          window: week,
        ),
        40,
      );
      expect(
        calculator.calculate(
          metric: CompetitionMetric.longestTrip,
          trips: trips,
          window: week,
        ),
        30,
      );
      expect(
        calculator.calculate(
          metric: CompetitionMetric.consistency,
          trips: trips,
          window: week,
        ),
        2,
      );
    });
  });
}
