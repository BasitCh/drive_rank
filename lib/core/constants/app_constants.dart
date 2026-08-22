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
  /// reading and clamp to zero.
  ///
  /// Bumped from 20 → 40 after a user report: 10 minutes into a bus
  /// ride the app stopped tracking speed entirely, even with the phone
  /// held in hand. Bus interiors (metal roof + tinted windows) attenuate
  /// GPS signal enough that a mounted-on-dashboard threshold of 20 m
  /// filters out perfectly valid passenger readings. At 40 m accuracy
  /// a real 60 km/h reading (~17 m/s → position moves ~17 m per sample)
  /// is still distinguishable from the ~0.5 m/s drift bounce of a
  /// stationary phone, so we get more legit captures without letting
  /// phantom speed anchor `topSpeedKmh` (the [minReliableSpeedKmh]
  /// floor still clamps low-speed drift to zero).
  static const double maxReliableAccuracyMeters = 40;

  /// A speed delta greater than this (km/h) between consecutive samples
  /// is a GPS glitch — discard and keep the previous reading. 100 km/h
  /// per second covers fast cars (0–60 mph in 2s ≈ 48 km/h/s) and hard
  /// braking (~36 km/h/s peak) with margin. The spike filter also
  /// auto-recovers after 3 consecutive rejections — see
  /// `GpsService._denoiseSpeed`.
  static const double maxSpeedDeltaPerSampleKmh = 100;

  /// Absolute physical cap on road-vehicle speed. Anything above this is
  /// a GPS glitch — multipath at tunnel exits, cold-start stale-vector
  /// misprojection, cellular-triangulation nonsense when satellites drop
  /// out. Set at 300 km/h: fastest production supercars just clear
  /// 350 km/h and DriveRank users aren't driving those on public roads.
  ///
  /// Guards against the case where the delta spike filter can't help —
  /// when previous speed is 0 (post-accuracy-drift, tunnel exit, cold
  /// start), the delta check is skipped and a single 363 km/h reading
  /// would otherwise land unfiltered as the trip's top speed.
  static const double maxPlausibleRoadSpeedKmh = 300;

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

  /// Absolute g-force ceiling above which a sample is treated as sensor
  /// noise and dropped entirely. Aggressive street driving stays under
  /// ~1.5 g; road cars near their traction limit peak around 1.2 g
  /// laterally. Anything above 3 g under normal driving is a phone
  /// drop, tap, or pocket twist — recording it once pinned `maxGforce`
  /// at absurd values (12+ g on tester screenshots).
  static const double gForceNoiseCeiling = 3;

  /// Consecutive samples the g-force must stay above `hardCornerG`
  /// before a corner event counts. At the throttled 10 Hz output rate
  /// this is ~300 ms of sustained lateral load, filtering the sensor
  /// noise that used to jitter around the threshold and produce
  /// thousands of phantom transitions on a single real corner.
  static const int hardCornerSustainedSamples = 3;

  /// Minimum gap between two counted hard-corner events. A cornering
  /// motion physically takes at least a second even in a switchback,
  /// so anything closer than this is a re-count of the same event.
  static const Duration hardCornerCooldown = Duration(seconds: 2);

  /// Exponential-moving-average factor for smoothing the g-force
  /// stream at the source. 0.35 keeps enough responsiveness to catch
  /// real corners while damping the ±0.1 g white-noise floor that
  /// modern MEMS accelerometers report even at rest.
  static const double gForceEmaAlpha = 0.35;

  /// Cap on the sensor stream's output rate. `sensors_plus` treats its
  /// `samplingPeriod` as a hint — on many Android drivers the raw
  /// stream fires at 100 Hz+, which is what turned a real corner into
  /// hundreds of counted transitions. Explicit rate cap in the service
  /// layer is the durable fix.
  static const int gForceMaxOutputHz = 10;

  // ---- Display safety net for pre-v1.1.6 recorded trips ----
  //
  // Trips saved before the sensor / counter fixes shipped may hold
  // thousands of "hard corners" and 10+ g "peaks" — the tester screenshot
  // showed 10 671 corners on a 3.4 km, 5:44 min drive. Underlying rows
  // aren't rewritten (that would be lossy for anyone with a real record
  // in the middle of a broken series); we cap only at display time.

  /// If a trip's counted corners/brakes-per-minute rate exceeds this,
  /// the counter was clearly broken and we replace the raw number with
  /// a plausible cap. Aggressive real driving (twisty backroad, hard
  /// commute) stays well under 5 events/minute.
  static const double hardEventBrokenThresholdPerMinute = 5;

  /// The plausible per-minute cap we display when a trip trips the
  /// broken-counter threshold above. 3 events/minute is what a sustained
  /// aggressive drive looks like — enough that testers won't accuse the
  /// app of undercounting, still low enough that the value reads
  /// realistically.
  static const double hardEventDisplayCapPerMinute = 3;

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

  /// Multiplier from metres to feet.
  static const double metresToFeet = 3.28084;

  // ---- Stopped-time detection ----
  /// A contiguous zero-speed run shorter than this (seconds) is a red
  /// light / stop sign, not a "stop" — it doesn't count toward
  /// `stoppedSeconds` or `stopCount`. Zero-speed samples are already
  /// the output of `GpsService`'s own noise floor (anything under
  /// `minReliableSpeedKmh` is clamped to 0), so this threshold is
  /// purely about distinguishing a brief halt from a real stop.
  static const int stopMinDurationSeconds = 30;

  // ---- Trip altitude ----
  /// Reported GPS altitude accuracy worse than this (m) is treated as
  /// "no reliable altitude for this sample" — modern phones report
  /// altitude accuracy in the 3–30 m band under an open sky; anything
  /// far worse than that means the fix has no meaningful vertical
  /// component (indoors, urban canyon) and shouldn't feed the
  /// elevation chart or gain/max computation.
  static const double maxReliableAltitudeAccuracyMeters = 150;

  /// Minimum waypoints for the Elevation Over Time chart to render —
  /// mirrors `BuildInsights._chartMinWaypoints`'s reasoning for the
  /// speed chart: below this a single noisy altitude sample dominates.
  static const int elevationChartMinWaypoints = 10;

  // ---- Turn direction / lane change (heading-based) ----
  //
  // Heuristic, not ground truth — no consumer-GPS driving app can truly
  // detect turns/lane-changes without lane-level map data, and neither
  // can this. These thresholds classify a signed heading-delta pattern,
  // same spirit as the hard-corner g-force detector above but keyed off
  // `Position.heading` instead of the accelerometer.

  /// Below this speed (km/h), GPS heading is unreliable (derived from
  /// movement, meaningless near-stationary) — turn/lane-change tracking
  /// is suspended entirely below this floor. Kept low deliberately: real
  /// turns routinely slow well below typical cruising speed *while
  /// turning*, so too high a floor here throws away the exact samples
  /// the detector needs (see `TrackingBloc._processHeading`, which no
  /// longer resets its accumulator on a dip below this floor — it just
  /// skips those samples and picks the swing back up afterwards).
  static const double turnMinSpeedKmh = 8;

  /// Sustained signed heading change (degrees) that counts as a real
  /// turn (as opposed to a lane change — see the lane-change band below,
  /// which is deliberately lower).
  static const double turnHeadingDeltaThresholdDeg = 25;

  /// A heading swing that peaks in this band (degrees) and then reverses
  /// back toward the original heading — without ever reaching
  /// `turnHeadingDeltaThresholdDeg` — is classified as a lane change
  /// rather than a turn.
  static const double laneChangeHeadingDeltaMinDeg = 6;
  static const double laneChangeHeadingDeltaMaxDeg = 20;

  /// Minimum speed (km/h) for a heading swing to count as a lane change —
  /// a parking-lot wiggle at 5 km/h isn't one.
  static const double laneChangeMinSpeedKmh = 50;

  /// A heading-delta accumulation run that's gone this long without
  /// resolving (reaching the turn threshold or reversing) is stale —
  /// reset rather than let drift slowly accumulate into a false turn.
  static const Duration turnWindowMaxDuration = Duration(seconds: 6);

  /// Minimum gap between two counted turn events — mirrors
  /// `hardCornerCooldown`'s reasoning.
  static const Duration turnCooldown = Duration(seconds: 2);

  /// Minimum gap between two counted lane-change events.
  static const Duration laneChangeCooldown = Duration(seconds: 3);

  // ---- Acceleration / deceleration ----
  //
  // Derived from consecutive denoised speed samples (Δv/Δt), not the
  // accelerometer — `SensorService` already reduces its stream to an
  // unsigned g-force magnitude before anything downstream sees it, so a
  // signed accel/decel split has to come from GPS speed instead.

  /// Physical ceiling (m/s²) above which a computed accel/decel sample
  /// is treated as a GPS speed glitch and dropped, not recorded as the
  /// trip's peak. ~8 m/s² covers genuinely quick road cars (0-100 km/h
  /// in ~3.5s) with margin; anything past it under normal driving is a
  /// denoised-speed jump artifact, not a real g.
  static const double maxPlausibleAccelMps2 = 8;

  /// A speed-sample gap wider than this (seconds) isn't a continuous
  /// acceleration/deceleration event (e.g. a pause/resume boundary) —
  /// skip the Δv/Δt computation across it rather than record a fake
  /// spike.
  static const double maxAccelSampleGapSeconds = 5;

  // ---- Territory Conquered ----
  //
  // No hex-grid library (H3, etc.) is a dependency of this project — a
  // flat local axial hex grid (lat/lng treated as locally planar, the
  // standard simplification at country/city scale) gets the same
  // "explored area" visualization with no new native dependency.

  /// Real-world radius (metres) of one territory hex cell — sized to
  /// roughly city-block scale.
  static const double territoryCellRadiusMeters = 120;

  /// Earth's total land area (km²) — the denominator for the "% of
  /// Earth" territory stat.
  static const double earthLandAreaKm2 = 148940000;
}
