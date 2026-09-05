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
abstract class RemoteTripSink {
  Future<void> uploadTrip(TripRow trip);

  /// Removes a trip the user deleted locally from the cloud.
  ///
  /// Returning normally means "gone remotely, drop the tombstone".
  /// Throwing means "retry on the next online tick" — which is why a doc
  /// that is already absent must *not* throw: a delete that partially
  /// succeeded has to be able to finish.
  Future<void> deleteTrip({required String uid, required String remoteId});
}

@LazySingleton(as: RemoteTripSink)
class NoopRemoteTripSink implements RemoteTripSink {
  const NoopRemoteTripSink();

  @override
  Future<void> uploadTrip(TripRow trip) async {
    // Successful no-op — trip is marked synced so the queue can drain.
  }

  @override
  Future<void> deleteTrip({
    required String uid,
    required String remoteId,
  }) async {
    // Nothing was ever uploaded, so there is nothing to remove — and
    // reporting success is what lets the tombstone queue drain.
  }
}
