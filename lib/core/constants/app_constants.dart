/// Runtime tuning constants for DriveRank.
///
/// Values that aren't visual tokens (colors/text/spacing) and aren't strings —
/// thresholds, intervals, feature limits. Anything a non-engineer might want
/// to tune lives here.
class AppConstants {
  const AppConstants._();

  // ---- Free tier ----
  /// Free trips before the paywall is shown. DriveRank's free tier is
  /// deliberately tight so users see the value of pro fast — three free
  /// trips is enough to taste the tracker + see one personal best.
  static const int freeTripLimit = 3;

  // ---- Speed noise filter (Issue 7) ----
  /// Speeds below this (km/h) are clamped to zero — under it, GPS drift
  /// dominates the real motion signal. Set to 6 (just above brisk
  /// walking pace) because users reported phantom 5 km/h readings
  /// anchoring `topSpeedKmh` on stationary tests. Real driving spends
  /// effectively no time in the 0–6 km/h band outside of parking
  /// maneuvers, so the loss is minimal.
  static const double minReliableSpeedKmh = 6;

  /// Reported GPS accuracy worse than this (m) → ignore the speed
  /// reading and clamp to zero. 20m is around the threshold where car
  /// motion stops being resolvable.
  static const double maxReliableAccuracyMeters = 20;

  /// A speed delta greater than this (km/h) between consecutive samples
  /// is a GPS glitch — discard and keep the previous reading. 100 km/h
  /// per second covers fast cars (0–60 mph in 2s ≈ 48 km/h/s) and hard
  /// braking (~36 km/h/s peak) with margin. The spike filter also
  /// auto-recovers after 3 consecutive rejections — see
  /// `GpsService._denoiseSpeed`.
  static const double maxSpeedDeltaPerSampleKmh = 100;

  // ---- Driving-event thresholds (hard brake / hard corner) ----
  /// Speed drop (km/h) between consecutive samples that counts as a
  /// hard brake. At the new 1Hz Android sample rate this maps to ~0.4 g
  /// of deceleration — well into "harsh" territory. One increment per
  /// braking event (the counter only steps on the transition).
  static const double hardBrakeDropKmh = 15;

  /// g-force magnitude above which we count a hard cornering event.
  /// Spirited driving stays under 0.4g; > 0.45g is "leaning on it."
  /// One increment per cornering event (debounced by transition).
  static const double hardCornerG = 0.45;

  /// Minimum vehicle speed (km/h) required for a g-force spike to be
  /// counted as a hard corner. Below this, the spike is almost
  /// certainly the user handling the phone — picking it up to check
  /// the speedometer, dropping it in a cup holder, etc — and was the
  /// source of phantom hard-corner counts on stationary tests.
  static const double hardCornerMinSpeedKmh = 10;

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
