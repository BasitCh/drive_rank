import 'dart:async';

import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/shared/models/friend_models.dart';
import 'package:drive_rank/shared/repositories/friends_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

// ---- Events ----------------------------------------------------------------

@immutable
sealed class FriendsEvent {
  const FriendsEvent();
}

class FriendsStarted extends FriendsEvent {
  const FriendsStarted();
}

class FriendsSearchChanged extends FriendsEvent {
  const FriendsSearchChanged(this.query);
  final String query;
}

class FriendsSendRequest extends FriendsEvent {
  const FriendsSendRequest(this.toUid);
  final String toUid;
}

class FriendsAcceptRequest extends FriendsEvent {
  const FriendsAcceptRequest(this.requestId);
  final String requestId;
}

class FriendsDeclineRequest extends FriendsEvent {
  const FriendsDeclineRequest(this.requestId);
  final String requestId;
}

class _FriendsIncomingArrived extends FriendsEvent {
  const _FriendsIncomingArrived(this.list);
  final List<IncomingFriendRequest> list;
}

class _FriendsListArrived extends FriendsEvent {
  const _FriendsListArrived(this.list);
  final List<Friend> list;
}

class _FriendsSearchResolved extends FriendsEvent {
  const _FriendsSearchResolved(this.query, this.results);
  final String query;
  final List<FriendSearchResult> results;
}

// ---- State -----------------------------------------------------------------

enum FriendsSearchState { idle, tooShort, searching, ready, empty, error }

@immutable
class FriendsState {
  const FriendsState({
    required this.incoming,
    required this.friends,
    required this.searchQuery,
    required this.searchState,
    required this.searchResults,
    required this.lastErrorMessage,
  });

  factory FriendsState.initial() => const FriendsState(
    incoming: <IncomingFriendRequest>[],
    friends: <Friend>[],
    searchQuery: '',
    searchState: FriendsSearchState.idle,
    searchResults: <FriendSearchResult>[],
    lastErrorMessage: null,
  );

  final List<IncomingFriendRequest> incoming;
  final List<Friend> friends;
  final String searchQuery;
  final FriendsSearchState searchState;
  final List<FriendSearchResult> searchResults;
  final String? lastErrorMessage;

  /// Notification-badge count for the profile tab.
  int get pendingRequestsCount => incoming.length;

  FriendsState copyWith({
    List<IncomingFriendRequest>? incoming,
    List<Friend>? friends,
    String? searchQuery,
    FriendsSearchState? searchState,
    List<FriendSearchResult>? searchResults,
    String? lastErrorMessage,
    bool clearError = false,
  }) {
    return FriendsState(
      incoming: incoming ?? this.incoming,
      friends: friends ?? this.friends,
      searchQuery: searchQuery ?? this.searchQuery,
      searchState: searchState ?? this.searchState,
      searchResults: searchResults ?? this.searchResults,
      lastErrorMessage: clearError
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }
}

// ---- Bloc ------------------------------------------------------------------

/// Centralised friends-feature state.
///
/// Subscribed once at the top of the app shell so the bottom-nav badge,
/// the profile-screen request list, and the leaderboard's Friends tab
/// all read from the same source. Username search is debounced 350 ms
/// so we don't hammer Firestore on every keystroke.
@lazySingleton
class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  FriendsBloc(this._repo, this._settings, this._auth)
    : super(FriendsState.initial()) {
    on<FriendsStarted>(_onStarted);
    on<FriendsSearchChanged>(_onSearchChanged);
    on<FriendsSendRequest>(_onSendRequest);
    on<FriendsAcceptRequest>(_onAccept);
    on<FriendsDeclineRequest>(_onDecline);
    on<_FriendsIncomingArrived>(_onIncomingArrived);
    on<_FriendsListArrived>(_onListArrived);
    on<_FriendsSearchResolved>(_onSearchResolved);
  }

  final FriendsRepository _repo;
  final UserSettingsRepository _settings;
  final AuthService _auth;

  StreamSubscription<List<IncomingFriendRequest>>? _incomingSub;
  StreamSubscription<List<Friend>>? _friendsSub;
  Timer? _searchDebounce;
  int _searchSeq = 0;

  Future<void> _onStarted(
    FriendsStarted event,
    Emitter<FriendsState> emit,
  ) async {
    final uid = _auth.currentUser.uid;
    await _incomingSub?.cancel();
    await _friendsSub?.cancel();
    _incomingSub = _repo.watchIncomingRequests(uid: uid).listen(
      (list) => add(_FriendsIncomingArrived(list)),
    );
    _friendsSub = _repo.watchFriends(uid: uid).listen(
      (list) => add(_FriendsListArrived(list)),
    );
  }

  void _onIncomingArrived(
    _FriendsIncomingArrived event,
    Emitter<FriendsState> emit,
  ) {
    emit(state.copyWith(incoming: event.list));
  }

  void _onListArrived(
    _FriendsListArrived event,
    Emitter<FriendsState> emit,
  ) {
    emit(state.copyWith(friends: event.list));
  }

  Future<void> _onSearchChanged(
    FriendsSearchChanged event,
    Emitter<FriendsState> emit,
  ) async {
    final query = event.query.trim();
    final seq = ++_searchSeq;
    if (query.length < 3) {
      _searchDebounce?.cancel();
      emit(
        state.copyWith(
          searchQuery: event.query,
          searchState: query.isEmpty
              ? FriendsSearchState.idle
              : FriendsSearchState.tooShort,
          searchResults: const <FriendSearchResult>[],
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        searchQuery: event.query,
        searchState: FriendsSearchState.searching,
      ),
    );
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final myUid = _auth.currentUser.uid;
        final results = await _repo.searchByUsernamePrefix(
          prefix: query,
          myUid: myUid,
        );
        if (seq != _searchSeq) return;
        if (isClosed) return;
        add(_FriendsSearchResolved(query, results));
      } catch (_) {
        if (seq != _searchSeq) return;
        if (isClosed) return;
        add(_FriendsSearchResolved(query, const <FriendSearchResult>[]));
      }
    });
  }

  void _onSearchResolved(
    _FriendsSearchResolved event,
    Emitter<FriendsState> emit,
  ) {
    if (event.query != state.searchQuery.trim()) return;
    emit(
      state.copyWith(
        searchResults: event.results,
        searchState: event.results.isEmpty
            ? FriendsSearchState.empty
            : FriendsSearchState.ready,
      ),
    );
  }

  Future<void> _onSendRequest(
    FriendsSendRequest event,
    Emitter<FriendsState> emit,
  ) async {
    final settings = await _settings.read();
    final result = await _repo.sendRequest(
      fromUid: _auth.currentUser.uid,
      fromUsername: settings.username,
      toUid: event.toUid,
    );
    if (result == FriendOperationResult.failed) {
      emit(state.copyWith(lastErrorMessage: 'send-failed'));
      return;
    }
    // Optimistically flip the Add button for that uid to "Sent" without
    // waiting for a re-search.
    emit(
      state.copyWith(
        searchResults: state.searchResults
            .map(
              (r) =>
                  r.uid == event.toUid ? r.copyWith(requestSent: true) : r,
            )
            .toList(),
      ),
    );
  }

  Future<void> _onAccept(
    FriendsAcceptRequest event,
    Emitter<FriendsState> emit,
  ) async {
    final settings = await _settings.read();
    await _repo.acceptRequest(
      requestId: event.requestId,
      myUid: _auth.currentUser.uid,
      myUsername: settings.username,
    );
    // Optimistic removal — the Firestore listener will re-confirm.
    emit(
      state.copyWith(
        incoming: state.incoming
            .where((r) => r.id != event.requestId)
            .toList(),
      ),
    );
  }

  Future<void> _onDecline(
    FriendsDeclineRequest event,
    Emitter<FriendsState> emit,
  ) async {
    await _repo.declineRequest(
      requestId: event.requestId,
      myUid: _auth.currentUser.uid,
    );
    emit(
      state.copyWith(
        incoming: state.incoming
            .where((r) => r.id != event.requestId)
            .toList(),
      ),
    );
  }

  @override
  Future<void> close() async {
    _searchDebounce?.cancel();
    await _incomingSub?.cancel();
    await _friendsSub?.cancel();
    return super.close();
  }
}
