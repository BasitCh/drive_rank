import 'package:drive_rank/core/database/app_database.dart' show TripRow;
import 'package:drive_rank/features/trip_insights/domain/entities/personal_record.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/replay_point.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_breakdown_slice.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_segment.dart';
import 'package:flutter/foundation.dart';

/// The single precomputed result the InsightsPage renders from.
///
/// Built once by `BuildInsights` when the page loads, held in
/// `InsightsState.ready`, read by every widget. No widget should do
/// math in `build()` — all of it lives upstream of this struct.
///
/// `chartEligible` / `breakdownEligible` / `recordsEligible` are the
/// gates that control which sections render. The page hides a section
/// entirely rather than rendering an empty card — better screenshot
/// hygiene than a stub.
@immutable
class InsightsBundle {
  const InsightsBundle({
    required this.trip,
    required this.smoothedSpeedKmh,
    required this.smoothedSecondsFromStart,
    required this.segments,
    required this.breakdown,
    required this.records,
    required this.bestAchievement,
    required this.chartEligible,
    required this.breakdownEligible,
    required this.recordsEligible,
    required this.smoothedElevationMeters,
    required this.smoothedElevationSecondsFromStart,
    required this.elevationEligible,
    required this.replayPoints,
    required this.replayEligible,
    required this.zeroToHundredSeconds,
  });

  final TripRow trip;

  /// Centred 5-point moving average of the trip's waypoint speeds.
  /// Indexes line up 1:1 with [smoothedSecondsFromStart].
  final List<double> smoothedSpeedKmh;

  /// Seconds since trip start at each smoothed sample — the chart's
  /// raw x-axis. Stored as ints because fl_chart's FlSpot wants doubles
  /// (cast at render time) and we save memory.
  final List<int> smoothedSecondsFromStart;

  /// Polyline groups for the intensity map (one per `SpeedBucket` run).
  final List<SpeedSegment> segments;

  /// Time-in-bucket histogram, one slice per `SpeedBucket`.
  final List<SpeedBreakdownSlice> breakdown;

  /// Records awarded for this trip, ordered most-impressive first.
  /// Empty when none fired (still rendered as long as the section is
  /// eligible — the empty state copy lives in the widget).
  final List<PersonalRecord> records;

  /// The "headline" badge — the first record in [records], or null if
  /// none. Surfaces in the hero strip's bottom-right cell. Null
  /// fall-back is to render the trip duration instead.
  final PersonalRecord? bestAchievement;

  final bool chartEligible;
  final bool breakdownEligible;
  final bool recordsEligible;

  /// Smoothed altitude series for the Elevation Over Time chart,
  /// paired 1:1 with [smoothedElevationSecondsFromStart]. Empty when
  /// [elevationEligible] is false.
  final List<double> smoothedElevationMeters;
  final List<int> smoothedElevationSecondsFromStart;

  /// False when the trip has under
  /// `AppConstants.elevationChartMinWaypoints` waypoints or no
  /// waypoint has a reliable altitude sample — the chart hides
  /// entirely rather than rendering a flat/broken line.
  final bool elevationEligible;

  /// Full-resolution position + live-stat series for the animated
  /// route replay. Empty when [replayEligible] is false.
  final List<ReplayPoint> replayPoints;

  /// False below 20 waypoints — replay is disabled entirely rather
  /// than showing a couple of jerky hops.
  final bool replayEligible;

  /// Fastest 0→100 km/h (≈0→60 mph) run, or null if the trip never
  /// reached it.
  final double? zeroToHundredSeconds;
}
