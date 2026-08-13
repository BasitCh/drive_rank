import 'dart:async';
import 'dart:math' as math;

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:injectable/injectable.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Streams a continuous g-force reading derived from the user
/// accelerometer.
///
/// `userAccelerometerEventStream` has gravity factored out at the
/// platform layer, so `sqrt(x² + y² + z²) / g` is the net linear
/// force on the vehicle in g's.
///
/// Three noise filters live here — they need to run at the source
/// because a single-frame spike from a phone drop or a MEMS sensor
/// glitch was pinning `maxGforce` at physically impossible values
/// (12+ g on tester screenshots) and turning one real cornering
/// event into hundreds of counted transitions in `TrackingBloc`.
///
///   1. **Noise ceiling** — samples above `gForceNoiseCeiling` (3 g)
///      are dropped entirely. Aggressive road driving peaks around
///      1.5 g; anything higher is a phone impact, not the vehicle.
///   2. **Exponential moving average** — `α = 0.35` smooths the
///      ±0.1 g white-noise floor without lagging behind real corners.
///   3. **Rate cap** — sensors_plus's `samplingPeriod` is a hint, not
///      a cap. On many Android drivers the raw stream fires at 100 Hz+
///      which was the mechanism behind 10 000+ counted "corners" on
///      short trips. We explicitly throttle to `gForceMaxOutputHz`
///      before publishing.
@singleton
class SensorService {
  SensorService();

  StreamSubscription<UserAccelerometerEvent>? _sub;
  final StreamController<double> _gforceController =
      StreamController<double>.broadcast();

  /// Smoothed real-time g-force stream. Values are >= 0 and bounded by
  /// `AppConstants.gForceNoiseCeiling`.
  Stream<double> get gforce => _gforceController.stream;

  bool get isRunning => _sub != null;

  static const double _gravity = 9.80665;

  /// EMA state — reset on each `start()` so a fresh trip doesn't
  /// inherit the previous trip's tail reading.
  double _emaG = 0;

  /// Wallclock of the last sample we forwarded downstream. Used for
  /// the rate cap.
  DateTime _lastEmitted = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> start() async {
    if (_sub != null) return;
    _emaG = 0;
    _lastEmitted = DateTime.fromMillisecondsSinceEpoch(0);

    const minInterval = Duration(
      milliseconds: 1000 ~/ AppConstants.gForceMaxOutputHz,
    );

    _sub =
        userAccelerometerEventStream(
          // Nominal request — real cadence varies by device. We enforce
          // the cap ourselves via the wallclock check below.
          samplingPeriod: const Duration(milliseconds: 100),
        ).listen(
          (e) {
            final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
            final rawG = magnitude / _gravity;

            // 1. Noise ceiling — an impact / phone drop shows up as a
            //    single-sample spike. Drop it entirely so it can't
            //    contaminate the EMA or the peak.
            if (rawG.isNaN ||
                rawG < 0 ||
                rawG > AppConstants.gForceNoiseCeiling) {
              return;
            }

            // 2. EMA smoothing.
            _emaG =
                AppConstants.gForceEmaAlpha * rawG +
                (1 - AppConstants.gForceEmaAlpha) * _emaG;

            // 3. Rate cap — enforce the 10 Hz maximum publish rate.
            final now = DateTime.now();
            if (now.difference(_lastEmitted) < minInterval) return;
            _lastEmitted = now;
            _gforceController.add(_emaG);
          },
          onError: (_) {
            /* sensor missing — silently ignore */
          },
        );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stop();
    await _gforceController.close();
  }
}
