import 'dart:async';
import 'dart:math' as math;

import 'package:injectable/injectable.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Streams a continuous g-force reading derived from the user accelerometer.
///
/// `userAccelerometerEventStream` already has gravity factored out, so the
/// magnitude of the (x, y, z) vector is the net lateral/longitudinal/vertical
/// force on the vehicle in m/s². Dividing by g gives a g-force value.
@singleton
class SensorService {
  SensorService();

  StreamSubscription<UserAccelerometerEvent>? _sub;
  final StreamController<double> _gforceController =
      StreamController<double>.broadcast();

  /// Real-time g-force stream — magnitude only, always >= 0.
  Stream<double> get gforce => _gforceController.stream;

  bool get isRunning => _sub != null;

  static const double _gravity = 9.80665;

  Future<void> start() async {
    if (_sub != null) return;
    _sub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen(
      (e) {
        final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        _gforceController.add(magnitude / _gravity);
      },
      onError: (_) {/* sensor missing — silently ignore */},
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
