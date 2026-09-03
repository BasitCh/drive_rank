import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/usecases/evaluate_competition_eligibility.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 9, 3, 9);

  /// A clean 1 Hz drive of [count] points creeping north at ~54 km/h.
  List<TripPoint> cleanTrip({
    int count = 30,
    double accuracyMeters = 8,
    double speedKmh = 54,
    bool isMocked = false,
  }) {
    return [
      for (var i = 0; i < count; i++)
        TripPoint(
          // ~15 m/s at 1 Hz ≈ 0.000135° of latitude per sample.
          lat: 31.5 + i * 0.000135,
          lng: 74.3,
          speedKmh: speedKmh,
          accuracyMeters: accuracyMeters,
          timestamp: start.add(Duration(seconds: i)),
          isMocked: isMocked,
        ),
    ];
  }

  CompetitionEligibility evaluate(List<TripPoint> points) =>
      evaluateCompetitionEligibility(
        points: points,
        distanceKm: 12,
        durationSeconds: 600,
      );

  test('a clean trip is eligible', () {
    final result = evaluate(cleanTrip());
    expect(result.eligible, isTrue);
    expect(result.reasons, isEmpty);
    expect(result.mockedSampleCount, 0);
  });

  group('insufficientTripData', () {
    test('too few points', () {
      expect(
        evaluate(cleanTrip(count: 4)).reasons,
        contains(EligibilityFailureReason.insufficientTripData),
      );
    });

    test('no distance', () {
      final result = evaluateCompetitionEligibility(
        points: cleanTrip(),
        distanceKm: 0,
        durationSeconds: 600,
      );
      expect(
        result.reasons,
        contains(EligibilityFailureReason.insufficientTripData),
      );
    });

    test('no duration', () {
      final result = evaluateCompetitionEligibility(
        points: cleanTrip(),
        distanceKm: 12,
        durationSeconds: 0,
      );
      expect(
        result.reasons,
        contains(EligibilityFailureReason.insufficientTripData),
      );
    });
  });

  group('insufficientGpsQuality', () {
    test('a trip that is mostly unresolvable fixes is not eligible', () {
      expect(
        evaluate(cleanTrip(accuracyMeters: 120)).reasons,
        contains(EligibilityFailureReason.insufficientGpsQuality),
      );
    });

    test('a handful of poor fixes is fine — normal drives dip under '
        'bridges and start on a cold fix', () {
      final points = [
        ...cleanTrip(count: 25),
        ...[
          for (var i = 0; i < 5; i++)
            TripPoint(
              lat: 31.51 + i * 0.000135,
              lng: 74.3,
              speedKmh: 54,
              accuracyMeters: 200,
              timestamp: start.add(Duration(seconds: 25 + i)),
            ),
        ],
      ];
      expect(
        evaluate(points).reasons,
        isNot(contains(EligibilityFailureReason.insufficientGpsQuality)),
      );
    });
  });

  group('invalidTimestampSequence', () {
    test('a rewound timestamp is caught', () {
      final points = cleanTrip()
        ..insert(
          10,
          TripPoint(
            lat: 31.5,
            lng: 74.3,
            speedKmh: 54,
            accuracyMeters: 8,
            timestamp: start.subtract(const Duration(minutes: 5)),
          ),
        );
      expect(
        evaluate(points).reasons,
        contains(EligibilityFailureReason.invalidTimestampSequence),
      );
    });

    test('a duplicate timestamp is caught', () {
      final points = cleanTrip();
      points[5] = TripPoint(
        lat: points[5].lat,
        lng: points[5].lng,
        speedKmh: points[5].speedKmh,
        accuracyMeters: points[5].accuracyMeters,
        timestamp: points[4].timestamp,
      );
      expect(
        evaluate(points).reasons,
        contains(EligibilityFailureReason.invalidTimestampSequence),
      );
    });
  });

  group('impossibleJump — position evidence', () {
    test('a teleport between consecutive fixes is caught', () {
      final points = cleanTrip();
      // ~500 km away, one second later.
      points[15] = TripPoint(
        lat: 36,
        lng: 74.3,
        speedKmh: 54,
        accuracyMeters: 8,
        timestamp: points[15].timestamp,
      );
      final reasons = evaluate(points).reasons;
      expect(reasons, contains(EligibilityFailureReason.impossibleJump));
    });

    test('the same displacement across a wide gap is not judged — a '
        'pause/resume boundary or a stale cached first fix legitimately '
        'covers real ground between samples', () {
      final points = [
        ...cleanTrip(count: 15),
        // Resumes 40 minutes and 30 km later.
        for (var i = 0; i < 15; i++)
          TripPoint(
            lat: 31.8 + i * 0.000135,
            lng: 74.3,
            speedKmh: 54,
            accuracyMeters: 8,
            timestamp: start.add(Duration(minutes: 40, seconds: i)),
          ),
      ];
      expect(
        evaluate(points).reasons,
        isNot(contains(EligibilityFailureReason.impossibleJump)),
      );
    });
  });

  group('suspiciousSpeedPattern — speed-channel evidence', () {
    test('a speed above the road-vehicle cap is caught', () {
      final points = cleanTrip();
      points[12] = TripPoint(
        lat: points[12].lat,
        lng: points[12].lng,
        speedKmh: 480,
        accuracyMeters: 8,
        timestamp: points[12].timestamp,
      );
      expect(
        evaluate(points).reasons,
        contains(EligibilityFailureReason.suspiciousSpeedPattern),
      );
    });

    test('a physically impossible acceleration is caught even when every '
        'speed is individually plausible', () {
      final points = cleanTrip();
      points[12] = TripPoint(
        lat: points[12].lat,
        lng: points[12].lng,
        // 54 -> 250 km/h in one second.
        speedKmh: 250,
        accuracyMeters: 8,
        timestamp: points[12].timestamp,
      );
      expect(
        evaluate(points).reasons,
        contains(EligibilityFailureReason.suspiciousSpeedPattern),
      );
    });

    test('is independent of position evidence — consistent coordinates '
        'with a glitched speed channel is not reported as a jump', () {
      final points = cleanTrip();
      points[12] = TripPoint(
        lat: points[12].lat,
        lng: points[12].lng,
        speedKmh: 250,
        accuracyMeters: 8,
        timestamp: points[12].timestamp,
      );
      final reasons = evaluate(points).reasons;
      expect(reasons, contains(EligibilityFailureReason.suspiciousSpeedPattern));
      expect(reasons, isNot(contains(EligibilityFailureReason.impossibleJump)));
    });

    test('brisk real-world acceleration stays eligible', () {
      final points = [
        for (var i = 0; i < 30; i++)
          TripPoint(
            lat: 31.5 + i * 0.0001,
            lng: 74.3,
            // ~0-100 km/h in 5s, then steady.
            speedKmh: i < 5 ? i * 20.0 : 100,
            accuracyMeters: 8,
            timestamp: start.add(Duration(seconds: i)),
          ),
      ];
      expect(evaluate(points).eligible, isTrue);
    });
  });

  group('mockLocationDetected', () {
    test('any mocked sample makes the trip ineligible and is counted', () {
      final points = cleanTrip();
      points[3] = TripPoint(
        lat: points[3].lat,
        lng: points[3].lng,
        speedKmh: points[3].speedKmh,
        accuracyMeters: points[3].accuracyMeters,
        timestamp: points[3].timestamp,
        isMocked: true,
      );
      final result = evaluate(points);
      expect(
        result.reasons,
        contains(EligibilityFailureReason.mockLocationDetected),
      );
      expect(result.mockedSampleCount, 1);
    });

    test('counts every mocked sample, so the record says how much of the '
        'trip was spoofed', () {
      expect(evaluate(cleanTrip(isMocked: true)).mockedSampleCount, 30);
    });
  });

  group('result shape', () {
    test('reports every failed rule, not just the first', () {
      final result = evaluateCompetitionEligibility(
        points: cleanTrip(count: 3, accuracyMeters: 300, isMocked: true),
        distanceKm: 0,
        durationSeconds: 0,
      );
      expect(result.reasons.length, greaterThan(2));
      expect(result.eligible, isFalse);
    });

    test('reasons come back in enum order, so the persisted list and the '
        'primary reason are stable across runs', () {
      final result = evaluateCompetitionEligibility(
        points: cleanTrip(count: 3, isMocked: true),
        distanceKm: 12,
        durationSeconds: 600,
      );
      final ordered = [...result.reasons]
        ..sort((a, b) => a.index.compareTo(b.index));
      expect(result.reasons, ordered);
      expect(result.primaryReason, result.reasons.first);
    });

    test('a recovered trip, whose points carry no heading or altitude, is '
        'not punished for it', () {
      final points = [
        for (var i = 0; i < 30; i++)
          TripPoint(
            lat: 31.5 + i * 0.000135,
            lng: 74.3,
            speedKmh: 54,
            accuracyMeters: 8,
            timestamp: start.add(Duration(seconds: i)),
          ),
      ];
      expect(points.every((p) => p.heading == null), isTrue);
      expect(evaluate(points).eligible, isTrue);
    });

    test('an empty trip is ineligible but does not divide by zero', () {
      final result = evaluateCompetitionEligibility(
        points: const [],
        distanceKm: 0,
        durationSeconds: 0,
      );
      expect(result.eligible, isFalse);
      expect(
        result.reasons,
        contains(EligibilityFailureReason.insufficientTripData),
      );
    });
  });
}
