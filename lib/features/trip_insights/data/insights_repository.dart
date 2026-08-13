import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/domain/usecases/build_insights.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:injectable/injectable.dart';

/// Loads everything Trip Insights needs from Drift and hands it to
/// `BuildInsights` for the single precomputation pass.
///
/// One round-trip per page open. The result lives in `InsightsState`
/// and is read by every widget — no further DB hits during rendering.
@lazySingleton
class InsightsRepository {
  InsightsRepository(this._db, this._trips, this._build);

  final AppDatabase _db;
  final TripRepository _trips;
  final BuildInsights _build;

  /// Returns the bundle, or null if the trip id doesn't exist (deleted
  /// out from under the user — surface as a NotFound state).
  Future<InsightsBundle?> load(int tripId) async {
    final trip = await _trips.getById(tripId);
    if (trip == null) return null;

    final waypoints = await _trips.getWaypoints(tripId);
    final otherTrips = await _otherTripsForUid(
      uid: trip.uid,
      excludingTripId: tripId,
    );

    return _build(trip: trip, waypoints: waypoints, otherTrips: otherTrips);
  }

  /// All saved trips for this anonymous install except the one we're
  /// computing insights for. Drift-only — no cloud, no leaderboard.
  Future<List<TripRow>> _otherTripsForUid({
    required String uid,
    required int excludingTripId,
  }) {
    return (_db.select(_db.trips)
          ..where((t) => t.uid.equals(uid) & t.id.equals(excludingTripId).not())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }
}
