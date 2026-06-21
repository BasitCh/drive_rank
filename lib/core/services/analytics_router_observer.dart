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
class AnalyticsRouterObserver extends NavigatorObserver {
  AnalyticsRouterObserver(this._telemetry);

  final TelemetryService _telemetry;

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
    unawaited(
      _telemetry.track(
        TelemetryEvents.screenView,
        properties: <String, Object?>{
          'screen_name': name,
          if (previous != null) 'previous_screen': previous,
        },
      ),
    );
  }
}
