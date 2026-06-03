import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Resolves a *device-bound* identifier that survives app reinstall on
/// the same device. Used as the Firestore key for the free-trip
/// counter — see `FreeTripCounterService`.
///
/// Implementation:
/// - **Android**: `Settings.Secure.ANDROID_ID`. Scoped per app-signing-
///   key + device + user; stable across uninstall/reinstall of the
///   same signed app. Changes on factory reset and on user switch.
/// - **iOS**: `identifierForVendor`. Stable as long as *any* app from
///   the same vendor (i.e. ours) is installed. If the user uninstalls
///   every DriveRank build and reinstalls, iOS issues a fresh ID — so
///   the iOS guarantee is weaker than Android's.
///
/// The raw ID never leaves the device — we hash it (sha256) before
/// using it as a Firestore key. That way:
/// - the cloud can't link two users by inspecting raw vendor IDs;
/// - the key is a fixed-length string safe for path segments;
/// - even our own logs are safe to surface.
@lazySingleton
class DeviceIdentityService {
  DeviceIdentityService() : _plugin = DeviceInfoPlugin();
  @visibleForTesting
  DeviceIdentityService.withPlugin(this._plugin);

  final DeviceInfoPlugin _plugin;
  String? _cachedHash;

  /// Returns a stable sha256 hash of the device ID. Cached for the
  /// process lifetime — the underlying ID doesn't change while the
  /// app is running.
  ///
  /// Returns `null` only if the platform refuses to provide an ID
  /// (e.g. iOS simulator with privacy settings locked down, or a
  /// non-mobile platform we don't support).
  Future<String?> deviceIdHash() async {
    if (_cachedHash != null) return _cachedHash;
    try {
      final raw = await _readRawId();
      if (raw == null || raw.isEmpty) return null;
      final digest = sha256.convert(utf8.encode(raw));
      return _cachedHash = digest.toString();
    } catch (e) {
      if (kDebugMode) debugPrint('[DeviceIdentity] resolve failed: $e');
      return null;
    }
  }

  Future<String?> _readRawId() async {
    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      return info.id; // Settings.Secure.ANDROID_ID
    }
    if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      return info.identifierForVendor;
    }
    return null;
  }
}
