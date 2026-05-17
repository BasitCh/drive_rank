/// Runtime tuning constants for DriveRank.
///
/// Values that aren't visual tokens (colors/text/spacing) and aren't strings —
/// thresholds, intervals, feature limits. Anything a non-engineer might want
/// to tune lives here.
class AppConstants {
  const AppConstants._();

  // ---- Free tier ----
  /// Free trips before the paywall is shown. DriveRank's free tier is
  /// deliberately smaller than TripRank's so users see the value of pro
  /// faster — the spec calls for 5.
  static const int freeTripLimit = 5;

  // ---- Speed noise filter (Issue 7) ----
  /// Speeds below this (km/h) are clamped to zero — under it, GPS drift
  /// dominates the real motion signal.
  static const double minReliableSpeedKmh = 3;

  /// Reported GPS accuracy worse than this (m) → ignore the speed
  /// reading and clamp to zero. 20m is around the threshold where car
  /// motion stops being resolvable.
  static const double maxReliableAccuracyMeters = 20;

  /// A speed delta greater than this (km/h) between consecutive samples
  /// is a GPS glitch — discard and keep the previous reading.
  static const double maxSpeedDeltaPerSampleKmh = 50;

  // ---- Auto trip detection ----
  /// Speed threshold (km/h) above which a candidate trip start is registered.
  static const double tripStartSpeedKmh = 15;

  /// Seconds of sustained above-threshold speed before a trip is auto-started.
  static const int tripStartDwellSeconds = 10;

  /// Speed threshold (km/h) below which a trip is considered idle.
  static const double tripEndSpeedKmh = 5;

  /// Seconds of sustained below-threshold speed before a trip is auto-ended.
  static const int tripEndDwellSeconds = 60;

  // ---- GPS sampling ----
  /// Position interval (seconds) while driving.
  static const int gpsIntervalActiveSeconds = 1;

  /// Position interval (seconds) while crawling/stationary (battery saving).
  static const int gpsIntervalIdleSeconds = 5;

  /// Minimum accuracy (metres) we feed into the Kalman filter — below this
  /// we treat readings as effectively perfect.
  static const double kalmanMinAccuracy = 1;

  // ---- Stat card export ----
  /// Pixel ratio for stat-card screenshots — 3× looks crisp on social.
  static const double cardExportPixelRatio = 3;

  // ---- Locale ----
  /// Countries that default to imperial units (per ISO 3166-1 alpha-2).
  /// Countries that default to imperial units (mph / mi). Per the spec:
  /// United States, United Kingdom, Myanmar, Liberia. The user can override
  /// in settings either direction — this only seeds the initial default.
  static const Set<String> imperialCountryCodes = {'US', 'GB', 'MM', 'LR'};

  // ---- Conversions ----
  /// Multiplier from km to miles (precise to 6dp).
  static const double kmToMiles = 0.621371;
}
