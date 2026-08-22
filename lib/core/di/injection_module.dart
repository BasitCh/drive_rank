import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/push_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:injectable/injectable.dart';

/// Module that registers the dev-default versions of every service
/// that has a "real" production swap-in. Bootstrap overrides these
/// after Firebase / OneSignal init when their config is present.
///
/// AuthService, PushService, and TelemetryService are still used for
/// per-install identity, push notifications, and analytics.
@module
abstract class InjectionModule {
  @LazySingleton(as: AuthService)
  AnonymousAuthService anonymousAuth() => AnonymousAuthService();

  @LazySingleton(as: TelemetryService)
  ConsoleTelemetryService consoleTelemetry() => ConsoleTelemetryService();

  @LazySingleton(as: PushService)
  NoopPushService noopPush() => NoopPushService();

  // `OemBatteryAdvisor`'s constructor takes an optional `DeviceInfoPlugin`
  // (for test injection, defaulting to a real one if omitted) — but
  // injectable's generator resolves every constructor parameter through
  // GetIt regardless, so without this registration `getIt<OemBatteryAdvisor>()`
  // threw on every trip start (caught by its call site, so never visible
  // to the user, but noisy in logs on every single trip).
  @lazySingleton
  DeviceInfoPlugin deviceInfoPlugin() => DeviceInfoPlugin();

  // `NetworkInfo` (used by `SyncManager` for the "just came back online"
  // trigger) needs a `Connectivity` instance — connectivity_plus doesn't
  // register itself. Same reasoning as `DeviceInfoPlugin` above: without
  // this, `SyncManager` (an eager `@singleton`) fails to construct at
  // all during `configureDependencies()`.
  @lazySingleton
  Connectivity connectivity() => Connectivity();
}
