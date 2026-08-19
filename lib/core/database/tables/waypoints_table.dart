import 'package:drift/drift.dart';

import 'package:drive_rank/core/database/tables/trips_table.dart';

/// One row per GPS sample inside a trip. Persisted live during tracking so
/// a process kill never loses the route. The Kalman-filtered position is
/// stored, not raw GPS.
@DataClassName('WaypointRow')
class Waypoints extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get tripId =>
      integer().references(Trips, #id, onDelete: KeyAction.cascade)();

  RealColumn get lat => real()();
  RealColumn get lng => real()();

  /// Instantaneous speed at this waypoint (km/h, metric).
  RealColumn get speedKmh => real()();

  /// Reported GPS accuracy in metres (lower is better).
  RealColumn get accuracyMeters => real()();

  /// Altitude above sea level in metres. Null when the fix's reported
  /// altitude accuracy was too poor to trust — see
  /// `GpsService._reliableAltitude`.
  RealColumn get altitudeMeters => real().nullable()();

  DateTimeColumn get timestamp => dateTime()();
}
