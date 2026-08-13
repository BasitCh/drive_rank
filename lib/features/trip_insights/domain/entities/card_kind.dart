import 'package:drive_rank/core/services/telemetry_service.dart';

/// Discriminates which social card the bloc is loading / sharing for.
///
/// Both Performance and Journey cards share the same data path
/// (`InsightsRepository` → `InsightsBundle`) but report split funnel
/// telemetry so we can compare Performance-vs-Journey engagement and
/// spot capture failures per surface. The bloc reads `viewedEvent`,
/// `sharedEvent`, `exportedEvent` to emit the right event name without
/// branching at every call site.
enum CardKind {
  performance,
  journey;

  String get viewedEvent => switch (this) {
    performance => TelemetryEvents.performanceCardViewed,
    journey => TelemetryEvents.journeyCardViewed,
  };

  String get sharedEvent => switch (this) {
    performance => TelemetryEvents.performanceCardShared,
    journey => TelemetryEvents.journeyCardShared,
  };

  String get exportedEvent => switch (this) {
    performance => TelemetryEvents.performanceCardExported,
    journey => TelemetryEvents.journeyCardExported,
  };
}
