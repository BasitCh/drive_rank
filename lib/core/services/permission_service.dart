import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Outcome of a location permission request.
enum LocationPermissionStatus {
  /// User has granted at-least foreground location.
  granted,

  /// User has granted always-on / background — required for true
  /// foreground-service-backed tracking on Android 10+.
  grantedAlways,

  /// User has declined (one-off).
  denied,

  /// User has selected "never ask again" or revoked from system settings.
  /// The app cannot prompt again; only Settings can recover this.
  deniedForever,

  /// Location services are disabled at the OS level — user must enable
  /// before any permission state is meaningful.
  servicesDisabled,
}

/// Thin wrapper over `geolocator`'s permission API so callers don't depend
/// on geolocator directly and so we can fake it in tests.
@lazySingleton
class PermissionService {
  PermissionService();

  /// Reads the current state without prompting.
  Future<LocationPermissionStatus> currentLocationStatus() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionStatus.servicesDisabled;
    }
    final p = await Geolocator.checkPermission();
    return _map(p);
  }

  /// Prompts the user for foreground location permission.
  ///
  /// On Android, this requests `ACCESS_FINE_LOCATION`. Background tracking
  /// (foreground service) needs `ACCESS_BACKGROUND_LOCATION`, which has its
  /// own separate prompt and must only be requested after foreground is
  /// granted — that flow lives in the future `requestBackground` method.
  Future<LocationPermissionStatus> requestLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionStatus.servicesDisabled;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return _map(p);
  }

  /// Opens the OS settings page so the user can recover from
  /// `deniedForever` or `servicesDisabled` themselves.
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Best-effort notification-permission request — Android's
  /// POST_NOTIFICATIONS and iOS's UNUserNotificationCenter authorization
  /// both go through `permission_handler`'s single cross-platform API.
  ///
  /// Android 13+: surfaces the system runtime dialog if the permission has
  /// never been answered. Older Android: silently granted (no runtime
  /// dialog exists). iOS: surfaces the system dialog once ever — a second
  /// `.request()` after the user has already answered (either way) just
  /// returns the existing status without re-prompting, so it's safe to
  /// call this on every trip start.
  ///
  /// `flutter_local_notifications`' own Darwin init flags
  /// (`requestAlertPermission` etc., see `LocalNotificationsGateway`) are
  /// deliberately left off — this is the single place that asks, so the
  /// prompt fires at a contextual moment (starting a trip) instead of
  /// immediately on cold launch.
  ///
  /// Returns whether the permission is granted *after* the request. We
  /// don't block the trip start on `false` — the live notification just
  /// won't render, but GPS + the foreground service notification still
  /// work (geolocator's own notification doesn't need POST_NOTIFICATIONS
  /// because it's tied to the foreground service).
  Future<bool> requestNotifications() async {
    try {
      final status = await ph.Permission.notification.status;
      if (status.isGranted) return true;
      final result = await ph.Permission.notification.request();
      return result.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PermissionService] notification request failed: $e');
      }
      return false;
    }
  }

  /// Reads the current notification-permission state without prompting
  /// — unlike [requestNotifications], this is safe to call on iOS too
  /// (status reads don't trigger the system dialog on either platform,
  /// only `.request()` does). Used by the retention scheduler to skip
  /// scheduling anything for a user who has notifications off, instead
  /// of finding out only when the OS silently drops the notification.
  Future<bool> currentNotificationStatus() async {
    try {
      final status = await ph.Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PermissionService] notification status read failed: $e');
      }
      return false;
    }
  }

  LocationPermissionStatus _map(LocationPermission p) => switch (p) {
    LocationPermission.always => LocationPermissionStatus.grantedAlways,
    LocationPermission.whileInUse => LocationPermissionStatus.granted,
    LocationPermission.denied => LocationPermissionStatus.denied,
    LocationPermission.deniedForever => LocationPermissionStatus.deniedForever,
    LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
  };
}
