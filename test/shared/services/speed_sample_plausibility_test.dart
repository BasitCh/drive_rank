import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/shared/services/speed_sample_plausibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime(2026, 9, 3, 9);

  group('usableSampleGapSeconds', () {
    test('returns the gap for a normal 1 Hz pair', () {
      expect(
        usableSampleGapSeconds(
          fromAt: at,
          toAt: at.add(const Duration(seconds: 1)),
        ),
        1,
      );
    });

    test('handles sub-second gaps', () {
      expect(
        usableSampleGapSeconds(
          fromAt: at,
          toAt: at.add(const Duration(milliseconds: 500)),
        ),
        0.5,
      );
    });

    test('rejects a duplicate timestamp', () {
      expect(usableSampleGapSeconds(fromAt: at, toAt: at), isNull);
    });

    test('rejects an out-of-order pair', () {
      expect(
        usableSampleGapSeconds(
          fromAt: at,
          toAt: at.subtract(const Duration(seconds: 1)),
        ),
        isNull,
      );
    });

    test('rejects a gap wider than the sample-gap ceiling — that is a '
        'pause/resume boundary or a stale cached fix, not a continuous '
        'acceleration event', () {
      expect(
        usableSampleGapSeconds(
          fromAt: at,
          toAt: at.add(
            Duration(
              milliseconds:
                  (AppConstants.maxAccelSampleGapSeconds * 1000).round() + 1,
            ),
          ),
        ),
        isNull,
      );
    });

    test('accepts a gap exactly at the ceiling', () {
      expect(
        usableSampleGapSeconds(
          fromAt: at,
          toAt: at.add(
            Duration(
              milliseconds:
                  (AppConstants.maxAccelSampleGapSeconds * 1000).round(),
            ),
          ),
        ),
        AppConstants.maxAccelSampleGapSeconds,
      );
    });
  });

  group('accelerationMps2', () {
    test('is positive when speeding up and negative when slowing down', () {
      expect(
        accelerationMps2(fromSpeedKmh: 0, toSpeedKmh: 36, dtSeconds: 1),
        closeTo(10, 0.001),
      );
      expect(
        accelerationMps2(fromSpeedKmh: 36, toSpeedKmh: 0, dtSeconds: 1),
        closeTo(-10, 0.001),
      );
    });

    test('is zero at constant speed', () {
      expect(
        accelerationMps2(fromSpeedKmh: 54, toSpeedKmh: 54, dtSeconds: 1),
        0,
      );
    });

    test('scales with the elapsed time', () {
      expect(
        accelerationMps2(fromSpeedKmh: 0, toSpeedKmh: 36, dtSeconds: 2),
        closeTo(5, 0.001),
      );
    });
  });

  group('isImplausibleAcceleration', () {
    test('accepts brisk real-world acceleration — 0-100 km/h in 4s', () {
      final a = accelerationMps2(
        fromSpeedKmh: 0,
        toSpeedKmh: 100,
        dtSeconds: 4,
      );
      expect(isImplausibleAcceleration(a), isFalse);
    });

    test('rejects a physically impossible jump, in both directions', () {
      final up = accelerationMps2(
        fromSpeedKmh: 0,
        toSpeedKmh: 200,
        dtSeconds: 1,
      );
      expect(isImplausibleAcceleration(up), isTrue);
      expect(isImplausibleAcceleration(-up), isTrue);
    });
  });

  group('isImplausibleSpeed', () {
    test('accepts fast highway speed', () {
      expect(isImplausibleSpeed(180), isFalse);
    });

    test('rejects above the road-vehicle cap', () {
      expect(
        isImplausibleSpeed(AppConstants.maxPlausibleRoadSpeedKmh + 1),
        isTrue,
      );
    });

    test('the cap itself is allowed', () {
      expect(isImplausibleSpeed(AppConstants.maxPlausibleRoadSpeedKmh), isFalse);
    });
  });
}
