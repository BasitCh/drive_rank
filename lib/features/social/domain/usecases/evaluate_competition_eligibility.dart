/// Client-side leaderboard-eligibility heuristics for a completed trip.
///
/// Pure, no I/O — same shape and rationale as `RecordGoalEvaluator`, so
/// the rules are unit-testable without standing up the tracking bloc's
/// dependency graph.
///
/// Runs on the **in-memory** points captured when the trip was saved,
/// not on `TripRepository.getWaypoints`: that query sorts by
/// `timestamp ASC` in SQL, which would silently repair the very
/// out-of-order timestamps this checks for, and the persisted waypoint
/// rows don't carry the mock-location flag.
library;

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/services/speed_sample_plausibility.dart';
import 'package:latlong2/latlong.dart';

/// Fraction of a trip's samples allowed to be worse than
/// [AppConstants.maxReliableAccuracyMeters] before the whole trip is
/// treated as too noisy to compete on.
///
/// Not zero-tolerance: a normal drive legitimately starts with a poor
/// cold-start fix and dips under bridges and in urban canyons, and the
/// accuracy bar itself was already relaxed to 40 m for bus/indoor
/// tracking. Half the trip being unresolvable is a different thing.
const double _maxPoorAccuracyShare = 0.5;

const Distance _distance = Distance();

/// Judges whether a trip counts toward competition.
///
/// [points] must be in **capture order**, not sorted.
CompetitionEligibility evaluateCompetitionEligibility({
  required List<TripPoint> points,
  required double distanceKm,
  required int durationSeconds,
}) {
  final reasons = <EligibilityFailureReason>{};

  final mockedSampleCount = points.where((p) => p.isMocked).length;
  if (mockedSampleCount > 0) {
    reasons.add(EligibilityFailureReason.mockLocationDetected);
  }

  // Not enough of a trip to judge, let alone rank. The waypoint floor
  // mirrors the elevation chart's reasoning: below it a single noisy
  // sample dominates whatever we compute.
  if (points.length < AppConstants.elevationChartMinWaypoints ||
      distanceKm <= 0 ||
      durationSeconds <= 0) {
    reasons.add(EligibilityFailureReason.insufficientTripData);
  }

  final poorAccuracyCount = points
      .where((p) => p.accuracyMeters > AppConstants.maxReliableAccuracyMeters)
      .length;
  if (points.isNotEmpty &&
      poorAccuracyCount / points.length > _maxPoorAccuracyShare) {
    reasons.add(EligibilityFailureReason.insufficientGpsQuality);
  }

  for (var i = 1; i < points.length; i++) {
    final previous = points[i - 1];
    final current = points[i];

    // Timestamps must strictly advance in capture order. Duplicates and
    // rewinds are checked on every pair regardless of gap width — a
    // stale cached first fix is exactly a rewind, so this is the one
    // rule that legitimately fires on it.
    if (!current.timestamp.isAfter(previous.timestamp)) {
      reasons.add(EligibilityFailureReason.invalidTimestampSequence);
      continue;
    }

    // Everything below is a Δ-over-time judgement, so it's only
    // meaningful across a gap that can carry a continuous event. Wider
    // gaps are pause/resume boundaries and stale cached fixes, and
    // judging across them would false-flag ordinary trips.
    final dtSeconds = usableSampleGapSeconds(
      fromAt: previous.timestamp,
      toAt: current.timestamp,
    );
    if (dtSeconds == null) continue;

    // Position evidence: the coordinates moved further than any road
    // vehicle could in the elapsed time — a teleport.
    final metres = _distance.as(
      LengthUnit.Meter,
      LatLng(previous.lat, previous.lng),
      LatLng(current.lat, current.lng),
    );
    final impliedKmh = (metres / dtSeconds) * 3.6;
    if (isImplausibleSpeed(impliedKmh)) {
      reasons.add(EligibilityFailureReason.impossibleJump);
    }

    // Speed-channel evidence: the reported speed series is itself
    // physically inconsistent, independent of where the device claims
    // to have been.
    if (isImplausibleSpeed(current.speedKmh) ||
        isImplausibleAcceleration(
          accelerationMps2(
            fromSpeedKmh: previous.speedKmh,
            toSpeedKmh: current.speedKmh,
            dtSeconds: dtSeconds,
          ),
        )) {
      reasons.add(EligibilityFailureReason.suspiciousSpeedPattern);
    }
  }

  return CompetitionEligibility(
    // Ordered by the enum's declaration order so the persisted reason
    // list and `primaryReason` are stable across runs.
    reasons: EligibilityFailureReason.values
        .where(reasons.contains)
        .toList(growable: false),
    mockedSampleCount: mockedSampleCount,
  );
}
