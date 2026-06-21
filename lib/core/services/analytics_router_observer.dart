import 'dart:async';

import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:flutter/widgets.dart';

/// `NavigatorObserver` that fires a `screen_view` telemetry event each
/// time the user lands on a new route.
///
/// Wired into `GoRouter.observers` so go_router's pushReplacement / push /
/// pop transitions all funnel through here. Firebase Analytics's
/// `setCurrentScreen` API is deprecated; we use a plain `track()` call
/// against `TelemetryEvents.screenView` instead, which keeps the same
/// schema in both Console (dev) and Firebase (prod) backends.
///
/// Anonymous routes (no name) are skipped — those are usually transient
/// modal sheets we don't want polluting the screen-view funnel.
///
/// Takes a `telemetryLookup` callback rather than a [TelemetryService]
/// directly. The router is registered as an eager singleton in DI, which
/// constructs before [TelemetryService] is registered — resolving it at
/// observer-construction time would crash the whole boot. Calling
/// `telemetryLookup()` lazily at event-time hits getIt only after all
/// registrations are complete.
class AnalyticsRouterObserver extends NavigatorObserver {
  AnalyticsRouterObserver(this._telemetryLookup);

  final TelemetryService? Function() _telemetryLookup;

  String? _lastScreen;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _emit(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _emit(previousRoute);
  }

  void _emit(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    if (name == _lastScreen) return;
    final previous = _lastScreen;
    _lastScreen = name;
    final telemetry = _telemetryLookup();
    if (telemetry == null) return;
    unawaited(
      telemetry.track(
        TelemetryEvents.screenView,
        properties: <String, Object?>{
          'screen_name': name,
          if (previous != null) 'previous_screen': previous,
        },
      ),
    );
  }
}
