import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/domain/entities/competition_eligibility.dart';
import 'package:drive_rank/features/social/domain/entities/rank_change.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/get_targets.dart';
import 'package:drive_rank/features/social/domain/usecases/get_trip_rank_change.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@immutable
sealed class TripSocialEvent {
  const TripSocialEvent();
}

class TripSocialLoaded extends TripSocialEvent {
  const TripSocialLoaded(this.tripId);
  final int tripId;
}

@immutable
class TripSocialState {
  const TripSocialState({
    this.isLoading = true,
    this.rankChange,
    this.completedTargets = const [],
    this.activeTargets = const [],
    this.unlockedTrophies = const [],
    this.eligibility,
  });

  final bool isLoading;

  /// Movement this trip caused, or null when it moved nothing.
  final RankChange? rankChange;

  /// Targets finished on or after this trip.
  final List<Target> completedTargets;

  /// Targets still running, for the progress line.
  final List<Target> activeTargets;

  /// Trophies unlocked around this trip.
  final List<Trophy> unlockedTrophies;

  /// Null when the trip predates the competition engine, which reads as
  /// eligible — see the `trip_eligibility` table's doc.
  final CompetitionEligibility? eligibility;

  bool get isIneligible => eligibility != null && !eligibility!.eligible;

  /// Whether the card has anything worth showing. An ineligible trip
  /// counts: saying so is more useful than silence.
  bool get hasContent =>
      isIneligible ||
      rankChange != null ||
      completedTargets.isNotEmpty ||
      unlockedTrophies.isNotEmpty ||
      activeTargets.isNotEmpty;

  TripSocialState copyWith({
    bool? isLoading,
    RankChange? rankChange,
    List<Target>? completedTargets,
    List<Target>? activeTargets,
    List<Trophy>? unlockedTrophies,
    CompetitionEligibility? eligibility,
  }) => TripSocialState(
    isLoading: isLoading ?? this.isLoading,
    rankChange: rankChange ?? this.rankChange,
    completedTargets: completedTargets ?? this.completedTargets,
    activeTargets: activeTargets ?? this.activeTargets,
    unlockedTrophies: unlockedTrophies ?? this.unlockedTrophies,
    eligibility: eligibility ?? this.eligibility,
  );
}

/// The competition side of one trip, for the Trip Summary card.
///
/// A separate bloc rather than an extension of `TripSummaryBloc`, for
/// the same reason `InsightsBloc` was added alongside it: the existing
/// loader is a straight-line one-shot read, and bolting a second
/// subsystem onto it would put this feature's failures in the path of
/// the page rendering at all.
///
/// Everything is keyed off the trip id and recomputed, so a trip opened
/// from History months later reconstructs the same answer. That's why it
/// re-reads rather than consuming the `CompetitionUpdate` the tracking
/// bloc produces once and discards.
@injectable
class TripSocialBloc extends Bloc<TripSocialEvent, TripSocialState> {
  TripSocialBloc(
    this._trips,
    this._settings,
    this._social,
    this._getRankChange,
    this._getTargets,
  ) : super(const TripSocialState()) {
    on<TripSocialLoaded>(_onLoaded);
  }

  final TripRepository _trips;
  final UserSettingsRepository _settings;
  final SocialRepository _social;
  final GetTripRankChange _getRankChange;
  final GetTargets _getTargets;

  Future<void> _onLoaded(
    TripSocialLoaded event,
    Emitter<TripSocialState> emit,
  ) async {
    final trip = await _trips.getById(event.tripId);
    if (trip == null) {
      // The trip was deleted while the page was open. Nothing to say,
      // and certainly nothing to crash over.
      emit(const TripSocialState(isLoading: false));
      return;
    }

    final settings = await _settings.read();
    final displayName = settings.username.isEmpty
        ? AppStrings.rankingsYouFallback
        : settings.username;

    final eligibility = await _social.getTripEligibility(event.tripId);

    // An ineligible trip moved nothing and progressed nothing, so don't
    // ask — the answers would all be "no" and the card says why instead.
    if (eligibility != null && !eligibility.eligible) {
      if (isClosed) return;
      emit(TripSocialState(isLoading: false, eligibility: eligibility));
      return;
    }

    final rankChange = await _getRankChange(
      tripId: event.tripId,
      uid: trip.uid,
      displayName: displayName,
    );
    final targets = await _getTargets(uid: trip.uid);
    final trophies = await _social.getTrophies(trip.uid);

    // Trophies and completions are tied to the trip by time: anything
    // stamped at or after this trip started is something this drive is
    // responsible for. Cheaper and more robust than threading trip ids
    // through the award path, and it degrades to "shows nothing" rather
    // than to a wrong claim.
    final since = trip.startedAt;
    if (isClosed) return;
    emit(
      TripSocialState(
        isLoading: false,
        rankChange: rankChange,
        eligibility: eligibility,
        completedTargets: targets
            .where(
              (t) => t.completedAt != null && !t.completedAt!.isBefore(since),
            )
            .toList(),
        activeTargets: targets.where((t) => !t.isComplete).toList(),
        unlockedTrophies: trophies
            .where((t) => !t.unlockedAt.isBefore(since))
            .toList(),
      ),
    );
  }
}
