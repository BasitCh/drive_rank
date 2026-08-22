import 'package:drive_rank/core/database/app_database.dart';
import 'package:injectable/injectable.dart';

/// The "outbound" half of trip persistence — `SyncManager` hands each
/// unsynced [TripRow] to a `RemoteTripSink`, which is responsible for
/// uploading the row (and its waypoints) to the cloud. Returning normally
/// means "stored successfully, mark as synced". Throwing means "retry on
/// the next online tick".
///
/// Two impls registered behind this interface:
///  - [NoopRemoteTripSink] (default, registered below so `SyncManager`'s
///    DI graph always resolves even when Firebase isn't configured) —
///    accepts every trip, does nothing. The local sync flag still flips to
///    true so the queue empties without a Firestore project configured.
///  - `FirestoreTripSink` — swapped in at bootstrap when Firebase is
///    available, writes to `users/{uid}/trips/{remoteId}`.
// ignore: one_member_abstracts
abstract class RemoteTripSink {
  Future<void> uploadTrip(TripRow trip);
}

@LazySingleton(as: RemoteTripSink)
class NoopRemoteTripSink implements RemoteTripSink {
  const NoopRemoteTripSink();

  @override
  Future<void> uploadTrip(TripRow trip) async {
    // Successful no-op — trip is marked synced so the queue can drain.
  }
}
