import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/tables/trips_table.dart';

/// Trips the user deleted locally that still exist in the cloud.
///
/// Deleting a row from [Trips] used to be the whole delete: the Firestore
/// doc under `users/{uid}/trips/{remoteId}` survived, so the trip came
/// back on the next restore or on a new device. From the user's side the
/// app simply refused to forget something.
///
/// Deleting remotely at the same moment isn't enough either — a delete
/// while offline, or one that fails mid-flight, would leave the same
/// resurrection. So the intent is recorded here and drained by
/// `SyncManager` on the next online tick, exactly like an unsynced
/// upload. Deliberately **not** a soft-delete flag on [Trips]: the local
/// row really is gone, and a tombstone that outlives it can't be mistaken
/// for history.
///
/// Rows are removed once the remote delete succeeds, so this table is
/// empty in the steady state.
@DataClassName('DeletedTripRow')
class DeletedTrips extends Table {
  /// The cloud document id. Primary key, so deleting the same trip twice
  /// (or re-recording a tombstone during a retry) collapses to one row.
  TextColumn get remoteId => text()();

  /// Which account's subcollection holds the doc. Stored rather than read
  /// from the session, because the delete may drain long after a uid
  /// change and must not be re-pointed at whoever is signed in then.
  TextColumn get uid => text()();

  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {remoteId};
}
