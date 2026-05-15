import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

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

  LocationPermissionStatus _map(LocationPermission p) => switch (p) {
    LocationPermission.always => LocationPermissionStatus.grantedAlways,
    LocationPermission.whileInUse => LocationPermissionStatus.granted,
    LocationPermission.denied => LocationPermissionStatus.denied,
    LocationPermission.deniedForever =>
      LocationPermissionStatus.deniedForever,
    LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
  };
}
