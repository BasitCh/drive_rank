import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/push_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/shared/services/remote_trip_sink.dart';
import 'package:injectable/injectable.dart';

/// Module that registers the dev-default versions of every service that
/// has a "real" production swap-in. Bootstrap will override these in the
/// container post-init when Firebase / OneSignal config is present.
///
/// Why a module? Injectable expects every binding for an interface to be
/// reachable at generation time. Declaring the previews here lets
/// `flutter pub run build_runner` produce a working DI graph without
/// requiring `firebase_options.dart` to exist yet.
@module
abstract class InjectionModule {
  @lazySingleton
  Connectivity connectivity() => Connectivity();

  @LazySingleton(as: AuthService)
  AnonymousAuthService anonymousAuth() => AnonymousAuthService();

  @LazySingleton(as: TelemetryService)
  ConsoleTelemetryService consoleTelemetry() => ConsoleTelemetryService();

  @LazySingleton(as: PushService)
  NoopPushService noopPush() => NoopPushService();

  @LazySingleton(as: RemoteTripSink)
  NoopRemoteTripSink noopSink() => const NoopRemoteTripSink();
}
