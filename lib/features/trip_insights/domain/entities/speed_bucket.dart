import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:flutter/widgets.dart' show Color;

/// Canonical km/h bands used by the speed-intensity map, the chart axis
/// helpers, and the breakdown bars. Storage is always metric — the UI
/// layer converts to mph at render time via `LocaleService`. Don't
/// localise the boundaries here; the boundary VALUES drive the bucket
/// math and must stay in km/h.
enum SpeedBucket {
  /// 0 ≤ s < 40 km/h
  walking,

  /// 40 ≤ s < 80 km/h
  cruising,

  /// 80 ≤ s < 120 km/h
  fast,

  /// 120 ≤ s km/h
  highway;

  /// Inclusive lower bound (km/h).
  double get minKmh => switch (this) {
        walking => 0,
        cruising => 40,
        fast => 80,
        highway => 120,
      };

  /// Exclusive upper bound (km/h); null for the open-ended top bucket.
  double? get maxKmh => switch (this) {
        walking => 40,
        cruising => 80,
        fast => 120,
        highway => null,
      };

  Color get color => switch (this) {
        walking => AppColors.red,
        cruising => AppColors.orange,
        fast => AppColors.green,
        highway => AppColors.teal,
      };

  /// Classifies a single speed sample. Anything negative or NaN falls
  /// into the `walking` bucket (it's the lowest — a no-op rather than
  /// a crash).
  static SpeedBucket from(double speedKmh) {
    if (speedKmh.isNaN || speedKmh < 40) return SpeedBucket.walking;
    if (speedKmh < 80) return SpeedBucket.cruising;
    if (speedKmh < 120) return SpeedBucket.fast;
    return SpeedBucket.highway;
  }
}
