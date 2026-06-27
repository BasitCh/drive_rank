import 'package:drive_rank/features/trip_insights/domain/entities/speed_bucket.dart';
import 'package:flutter/foundation.dart';

/// One row in the breakdown bar chart.
///
/// `percentage` is computed from **time spent** in the bucket (not point
/// count) so uneven GPS sample rates don't skew the histogram. Computed
/// once in the use case and cached in `InsightsBundle` — widgets read,
/// never recompute.
@immutable
class SpeedBreakdownSlice {
  const SpeedBreakdownSlice({
    required this.bucket,
    required this.secondsInBucket,
    required this.percentage,
  });

  final SpeedBucket bucket;
  final double secondsInBucket;

  /// 0..1
  final double percentage;
}
