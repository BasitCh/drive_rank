import 'package:drive_rank/shared/models/leaderboard_entry.dart';
import 'package:drive_rank/shared/models/road_segment.dart';
import 'package:drive_rank/shared/repositories/leaderboard_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/road_segment_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@immutable
sealed class LeaderboardEvent {
  const LeaderboardEvent();
}

class LeaderboardStarted extends LeaderboardEvent {
  const LeaderboardStarted();
}

class LeaderboardScopeSelected extends LeaderboardEvent {
  const LeaderboardScopeSelected(this.scope);
  final LeaderboardScope scope;
}

enum LeaderboardStatus { loading, ready, error }

@immutable
class LeaderboardState {
  const LeaderboardState({
    required this.status,
    required this.availableScopes,
    required this.activeScope,
    required this.entries,
    required this.currentUserEntry,
    required this.errorMessage,
  });

  factory LeaderboardState.initial() => const LeaderboardState(
    status: LeaderboardStatus.loading,
    availableScopes: <LeaderboardScope>[
      LeaderboardScopeFriends(),
      LeaderboardScopeGlobal(),
    ],
    activeScope: LeaderboardScopeFriends(),
    entries: <LeaderboardEntry>[],
    currentUserEntry: null,
    errorMessage: null,
  );

  final LeaderboardStatus status;
  final List<LeaderboardScope> availableScopes;
  final LeaderboardScope activeScope;
  final List<LeaderboardEntry> entries;

  /// Set only when the current user has a leaderboard entry but isn't
  /// in the visible top-N — drives the sticky-footer row.
  final LeaderboardEntry? currentUserEntry;

  final String? errorMessage;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    List<LeaderboardScope>? availableScopes,
    LeaderboardScope? activeScope,
    List<LeaderboardEntry>? entries,
    LeaderboardEntry? currentUserEntry,
    bool clearCurrentUserEntry = false,
    String? errorMessage,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      availableScopes: availableScopes ?? this.availableScopes,
      activeScope: activeScope ?? this.activeScope,
      entries: entries ?? this.entries,
      currentUserEntry: clearCurrentUserEntry
          ? null
          : (currentUserEntry ?? this.currentUserEntry),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@injectable
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  LeaderboardBloc(this._repo, this._segments, this._settings)
    : super(LeaderboardState.initial()) {
    on<LeaderboardStarted>(_onStarted);
    on<LeaderboardScopeSelected>(_onScopeSelected);
  }

  final LeaderboardRepository _repo;
  final RoadSegmentService _segments;
  final UserSettingsRepository _settings;

  Future<void> _onStarted(
    LeaderboardStarted event,
    Emitter<LeaderboardState> emit,
  ) async {
    final settings = await _settings.read();
    final country = settings.country ?? 'US';
    final segments = await _segments.forCountry(country);

    // Tab order matches the mock: Friends → Global → segments → country.
    final scopes = <LeaderboardScope>[
      const LeaderboardScopeFriends(),
      const LeaderboardScopeGlobal(),
      for (final s in segments.take(4)) _scopeFor(s),
      LeaderboardScopeCountry(country),
    ];

    // Default to Global on first open — Friends needs friends connected
    // first and Global has the most data immediately.
    const initialScope = LeaderboardScopeGlobal();
    final entries = await _repo.getEntries(scope: initialScope);
    final stickyFooter = await _resolveSticky(initialScope, entries);

    emit(
      state.copyWith(
        status: LeaderboardStatus.ready,
        availableScopes: scopes,
        activeScope: initialScope,
        entries: entries,
        currentUserEntry: stickyFooter,
        clearCurrentUserEntry: stickyFooter == null,
      ),
    );
  }

  /// Fetches the user's own entry for the active scope only when they
  /// aren't already in the visible list — that's what populates the
  /// sticky footer at the bottom of the leaderboard.
  Future<LeaderboardEntry?> _resolveSticky(
    LeaderboardScope scope,
    List<LeaderboardEntry> entries,
  ) async {
    if (entries.any((e) => e.isYou)) return null;
    return _repo.getCurrentUserEntry(scope: scope);
  }

  Future<void> _onScopeSelected(
    LeaderboardScopeSelected event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LeaderboardStatus.loading,
        activeScope: event.scope,
      ),
    );
    final entries = await _repo.getEntries(scope: event.scope);
    final stickyFooter = await _resolveSticky(event.scope, entries);
    emit(
      state.copyWith(
        status: LeaderboardStatus.ready,
        entries: entries,
        currentUserEntry: stickyFooter,
        clearCurrentUserEntry: stickyFooter == null,
      ),
    );
  }

  static LeaderboardScope _scopeFor(RoadSegment s) =>
      LeaderboardScopeSegment(s.id, s.name);
}
