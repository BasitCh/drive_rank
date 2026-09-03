/// Pairwise plausibility primitives over consecutive speed samples.
///
/// Extracted so the two places that judge a Δv/Δt pair — the live
/// accel/decel counters in `TrackingBloc._processAcceleration` and the
/// social feature's leaderboard-eligibility check — share one
/// definition instead of two that quietly diverge. Each caller keeps its
/// own policy for what to do with an implausible pair: the bloc drops
/// the sample, eligibility flags the trip.
///
/// Kept as pure top-level functions, mirroring `zeroToHundredSecondsFrom`.
library;

import 'package:drive_rank/core/constants/app_constants.dart';

/// Seconds between two samples, or null when the gap can't carry a
/// continuous acceleration event — non-positive (duplicate or
/// out-of-order timestamps) or wider than
/// [AppConstants.maxAccelSampleGapSeconds], which is what a
/// pause/resume boundary or a stale cached first fix looks like.
double? usableSampleGapSeconds({
  required DateTime fromAt,
  required DateTime toAt,
}) {
  final dtSeconds = toAt.difference(fromAt).inMilliseconds / 1000.0;
  if (dtSeconds <= 0) return null;
  if (dtSeconds > AppConstants.maxAccelSampleGapSeconds) return null;
  return dtSeconds;
}

/// Signed acceleration (m/s²) implied by a speed change over
/// [dtSeconds]. Positive accelerating, negative decelerating.
double accelerationMps2({
  required double fromSpeedKmh,
  required double toSpeedKmh,
  required double dtSeconds,
}) => ((toSpeedKmh - fromSpeedKmh) / 3.6) / dtSeconds;

/// Whether [accelMps2] exceeds what a road vehicle can physically do —
/// a GPS speed-glitch artifact rather than a real g.
bool isImplausibleAcceleration(double accelMps2) =>
    accelMps2.abs() > AppConstants.maxPlausibleAccelMps2;

/// Whether [speedKmh] is above the absolute road-vehicle cap.
bool isImplausibleSpeed(double speedKmh) =>
    speedKmh > AppConstants.maxPlausibleRoadSpeedKmh;
