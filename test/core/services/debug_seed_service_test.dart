import 'package:drive_rank/core/services/debug_seed_service.dart';
import 'package:drive_rank/features/social/domain/usecases/evaluate_competition_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DebugSeedService.eligibleTripNowStats', () {
    final now = DateTime(2026, 9, 13, 15, 30);
    final stats = DebugSeedService.eligibleTripNowStats(now);

    test('passes every competition eligibility rule', () {
      final eligibility = evaluateCompetitionEligibility(
        points: stats.points,
        distanceKm: stats.distanceKm,
        durationSeconds: stats.durationSeconds,
      );

      expect(eligibility.reasons, isEmpty);
    });

    test('no seeded trip is dated in the future — History renders one as '
        '"-3 days ago" and a competition window would count it', () {
      // Mid-month, so this month's day-16 blueprint would otherwise land
      // three days ahead.
      for (final at in [
        DateTime(2026, 9, 13, 15, 30),
        DateTime(2026, 1, 1, 0, 5),
        DateTime(2026, 2, 28, 23, 59),
      ]) {
        for (final startedAt in DebugSeedService.mockTripStartTimes(at)) {
          expect(startedAt.isAfter(at), isFalse, reason: '$startedAt at $at');
        }
      }
    });

    test('starts at now, so it lands inside a challenge opened before it', () {
      expect(stats.points.first.timestamp.isAfter(now), isTrue);
      expect(stats.distanceKm, greaterThan(9));
    });
  });
}
