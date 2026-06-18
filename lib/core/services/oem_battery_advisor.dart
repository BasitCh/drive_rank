import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Detects whether the device's manufacturer is in the well-known
/// "aggressively kills background services" club so we can warn the
/// user during their first trip.
///
/// The bottom sheet that shows on top of this signal points them at
/// the OEM-specific battery whitelist screen. Without that whitelist
/// our foreground service still gets shut down within ~10 minutes of
/// screen-off on Xiaomi MIUI / Huawei EMUI / Oppo ColorOS / Vivo
/// FuntouchOS / Realme UI — and the trip silently dies.
///
/// dontkillmyapp.com keeps a community-maintained list; this one
/// captures the brands most common in DriveRank's Pakistan/India/SE
/// Asia market.
@lazySingleton
class OemBatteryAdvisor {
  OemBatteryAdvisor([DeviceInfoPlugin? plugin])
      : _info = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _info;

  static const Set<String> _knownKillers = {
    'xiaomi',
    'redmi',
    'poco',
    'oppo',
    'oneplus',
    'realme',
    'vivo',
    'iqoo',
    'huawei',
    'honor',
    'samsung',
    'meizu',
    'asus',
    'tecno',
    'infinix',
  };

  /// Returns true if this device's manufacturer is in [_knownKillers].
  /// Best-effort — returns false on platforms where we can't read the
  /// info (iOS / web / desktop / device_info_plus error).
  Future<bool> isLikelyKiller() async {
    if (!Platform.isAndroid) return false;
    try {
      final android = await _info.androidInfo;
      final manufacturer = android.manufacturer.toLowerCase();
      final brand = android.brand.toLowerCase();
      return _knownKillers.contains(manufacturer) ||
          _knownKillers.contains(brand);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OemBatteryAdvisor] info read failed: $e');
      }
      return false;
    }
  }
}
