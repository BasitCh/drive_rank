import 'package:drive_rank/core/database/app_database.dart';

/// The "outbound" half of trip persistence — the SyncManager hands each
/// unsynced [TripRow] to a `RemoteTripSink`, which is responsible for
/// uploading the row (and its waypoints) to the cloud. Returning normally
/// means "stored successfully, mark as synced". Throwing means "retry on
/// the next online tick".
///
/// Two impls registered behind this interface:
///  - [NoopRemoteTripSink] (default) — accepts every trip, does nothing.
///    The local sync flag still flips to true so the queue empties even
///    without a Firestore project configured.
///  - `FirestoreTripSink` — wired when Firestore is available, writes to
///    `users/{uid}/trips/{tripId}`.
// ignore: one_member_abstracts
abstract class RemoteTripSink {
  Future<void> uploadTrip(TripRow trip);
}

class NoopRemoteTripSink implements RemoteTripSink {
  const NoopRemoteTripSink();

  @override
  Future<void> uploadTrip(TripRow trip) async {
    // Successful no-op — trip is marked synced so the queue can drain.
  }
}
