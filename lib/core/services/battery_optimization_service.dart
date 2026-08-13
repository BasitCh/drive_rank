import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps Android's REQUEST_IGNORE_BATTERY_OPTIMIZATIONS flow so the
/// rest of the app doesn't have to know about platform plumbing.
///
/// Granting this whitelist is what gives DriveRank's foreground service
/// the best shot at surviving long trips on aggressive OEM ROMs
/// (Xiaomi MIUI / Oppo ColorOS / etc) — once whitelisted, the system
/// won't push the app into a Doze bucket while a trip is recording.
///
/// iOS / web / desktop: no-op.
@lazySingleton
class BatteryOptimizationService {
  const BatteryOptimizationService();

  /// True if the system has already granted DriveRank an exemption.
  /// Used by the OEM advice sheet to skip the prompt when the user
  /// already turned it on.
  Future<bool> isIgnoringOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BatteryOpt] status check failed: $e');
      }
      return false;
    }
  }

  /// Surfaces the system whitelist sheet. The user can accept (returns
  /// granted) or deny (returns denied). We never re-prompt aggressively —
  /// the OEM advice sheet calls this at most once per install per
  /// `oemAdviceShown` flag.
  Future<bool> requestIgnoreOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BatteryOpt] request failed: $e');
      }
      return false;
    }
  }
}
