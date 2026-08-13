/// Which personal-best metric a record celebration is for — selects
/// the copy and which `LocaleService` formatter renders the value.
/// Lives here (not in `retention_notification_service.dart`) purely so
/// `RetentionNotificationCopy` doesn't have to import the service file
/// just for this enum.
enum RecordCelebrationKind { speed, distance }

/// Pure notification-copy builders for `RetentionNotificationService` —
/// no I/O, no `LocaleService`/DB access. The service formats
/// locale-aware values (speed/distance strings) and passes them in
/// already-rendered; these functions only assemble the surrounding
/// sentence. Split out specifically so the actual notification text is
/// unit-testable without standing up the plugin/DB/permission stack.
class RetentionNotificationCopy {
  const RetentionNotificationCopy._();

  static String personalRecordBody({
    required RecordCelebrationKind kind,
    required String valueLabel,
  }) {
    return kind == RecordCelebrationKind.speed
        ? 'You just hit a new top speed: $valueLabel. Check out your drive.'
        : 'You just drove your longest trip yet: $valueLabel.';
  }

  /// [distanceLabel] is already locale-formatted (e.g. "127 km" or
  /// "79 mi") — this only handles the trip/record-count pluralisation
  /// and assembly, which doesn't depend on locale.
  static String weeklyRecapBody({
    required int tripCount,
    required String distanceLabel,
    required int recordCount,
  }) {
    final tripsLabel = tripCount == 1 ? 'trip' : 'trips';
    final recordsSuffix = recordCount > 0
        ? ' · $recordCount personal record${recordCount == 1 ? '' : 's'}'
        : '';
    return '$tripCount $tripsLabel · $distanceLabel$recordsSuffix';
  }
}
