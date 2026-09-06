import 'dart:async';

import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/data/services/friends_sync_service.dart';
import 'package:drive_rank/features/social/data/services/social_directory.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/friend.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/domain/entities/invite_code.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@immutable
sealed class FriendsEvent {
  const FriendsEvent();
}

class FriendsStarted extends FriendsEvent {
  const FriendsStarted();
}

/// Pull-to-refresh, and the post-action refresh.
class FriendsRefreshed extends FriendsEvent {
  const FriendsRefreshed();
}

class FriendsLookupRequested extends FriendsEvent {
  const FriendsLookupRequested(this.query, {required this.byCode});
  final String query;
  final bool byCode;
}

class FriendsLookupCleared extends FriendsEvent {
  const FriendsLookupCleared();
}

class FriendsRequestSent extends FriendsEvent {
  const FriendsRequestSent(this.toUid);
  final String toUid;
}

class FriendsRequestAnswered extends FriendsEvent {
  const FriendsRequestAnswered(this.request, {required this.accept});
  final FriendRequest request;
  final bool accept;
}

class FriendsRemoved extends FriendsEvent {
  const FriendsRemoved(this.friendUid);
  final String friendUid;
}

/// How a lookup ended. Distinct states rather than a nullable result,
/// because "searching", "nothing there" and "found somebody" all need
/// different copy and the difference matters to the user.
enum LookupStatus { idle, searching, notFound, found, isSelf, alreadyFriend }

@immutable
class FriendsState {
  const FriendsState({
    required this.isLoading,
    this.uid = '',
    this.inviteCode = '',
    this.canBeFoundByName = false,
    this.friends = const [],
    this.friendProfiles = const {},
    this.incoming = const [],
    this.lookupStatus = LookupStatus.idle,
    this.lookupResult,
    this.sentTo = const {},
    this.error,
  });

  factory FriendsState.initial() => const FriendsState(isLoading: true);

  final bool isLoading;
  final String uid;

  /// This account's shareable code, derived from the uid.
  final String inviteCode;

  /// False when the username was never reserved — the account works
  /// normally but cannot be found by name, so the page says to share
  /// the code instead.
  final bool canBeFoundByName;

  final List<Friend> friends;

  /// Published profiles for the friends above, when we have them.
  /// Missing is normal: a friend who hasn't driven yet has no mirror.
  final Map<String, CompetitionMirror> friendProfiles;

  /// Requests waiting on this user's answer.
  final List<FriendRequest> incoming;

  final LookupStatus lookupStatus;
  final CompetitionMirror? lookupResult;

  /// Uids this session has already asked, so the button can say so
  /// without waiting for a sync round-trip.
  final Set<String> sentTo;

  final String? error;

  FriendsState copyWith({
    bool? isLoading,
    String? uid,
    String? inviteCode,
    bool? canBeFoundByName,
    List<Friend>? friends,
    Map<String, CompetitionMirror>? friendProfiles,
    List<FriendRequest>? incoming,
    LookupStatus? lookupStatus,
    CompetitionMirror? lookupResult,
    Set<String>? sentTo,
    String? error,
    bool clearLookup = false,
    bool clearError = false,
  }) => FriendsState(
    isLoading: isLoading ?? this.isLoading,
    uid: uid ?? this.uid,
    inviteCode: inviteCode ?? this.inviteCode,
    canBeFoundByName: canBeFoundByName ?? this.canBeFoundByName,
    friends: friends ?? this.friends,
    friendProfiles: friendProfiles ?? this.friendProfiles,
    incoming: incoming ?? this.incoming,
    lookupStatus: clearLookup
        ? LookupStatus.idle
        : (lookupStatus ?? this.lookupStatus),
    lookupResult: clearLookup ? null : (lookupResult ?? this.lookupResult),
    sentTo: sentTo ?? this.sentTo,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Drives the friends page.
///
/// Reads come from Drift and writes go to both — the local tables are
/// what the UI watches, so the list stays reactive and works offline,
/// while the shared collections are what the other person's device sees.
@injectable
class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  FriendsBloc(this._settings, this._social, this._directory, this._sync)
    : super(FriendsState.initial()) {
    on<FriendsStarted>(_onStarted);
    on<FriendsRefreshed>(_onRefreshed);
    on<FriendsLookupRequested>(_onLookup);
    on<FriendsLookupCleared>(_onLookupCleared);
    on<FriendsRequestSent>(_onRequestSent);
    on<FriendsRequestAnswered>(_onRequestAnswered);
    on<FriendsRemoved>(_onRemoved);
  }

  final UserSettingsRepository _settings;
  final SocialRepository _social;
  final SocialDirectory _directory;
  final FriendsSyncService _sync;

  StreamSubscription<List<Friend>>? _friendsSub;
  StreamSubscription<List<FriendRequest>>? _requestsSub;

  Future<void> _onStarted(
    FriendsStarted event,
    Emitter<FriendsState> emit,
  ) async {
    final row = await _settings.read();
    emit(
      state.copyWith(
        uid: row.uid,
        inviteCode: inviteCodeFor(row.uid),
        canBeFoundByName: row.usernameClaimed,
      ),
    );

    await _friendsSub?.cancel();
    _friendsSub = _social
        .watchFriends(row.uid)
        .listen((_) => add(const FriendsRefreshed()));

    await _requestsSub?.cancel();
    _requestsSub = _social
        .watchIncomingRequests(row.uid)
        .listen((_) => add(const FriendsRefreshed()));

    // Pull anything other people's devices did while this one was
    // closed, then show whatever is local either way — a failed sync
    // must not leave the page empty when Drift already has friends.
    await _sync.syncNow();
    add(const FriendsRefreshed());
  }

  Future<void> _onRefreshed(
    FriendsRefreshed event,
    Emitter<FriendsState> emit,
  ) async {
    final uid = state.uid.isEmpty ? (await _settings.read()).uid : state.uid;
    final friends = await _social.getFriends(uid);
    final requests = await _social.watchIncomingRequests(uid).first;
    final pending = requests
        .where((r) => r.status == FriendRequestStatus.pending)
        .toList();

    // Profiles are best-effort decoration: a friend with no published
    // mirror still belongs in the list, under their local record.
    final profiles = <String, CompetitionMirror>{...state.friendProfiles};
    for (final friend in friends) {
      if (profiles.containsKey(friend.friendUid)) continue;
      final profile = await _directory.profileFor(friend.friendUid);
      if (profile != null) profiles[friend.friendUid] = profile;
    }

    emit(
      state.copyWith(
        isLoading: false,
        friends: friends,
        friendProfiles: profiles,
        incoming: pending,
      ),
    );
  }

  Future<void> _onLookup(
    FriendsLookupRequested event,
    Emitter<FriendsState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(clearLookup: true));
      return;
    }

    emit(
      state.copyWith(
        lookupStatus: LookupStatus.searching,
        clearError: true,
      ),
    );

    final uid = event.byCode
        ? await _directory.uidForInviteCode(normaliseInviteCode(query))
        : await _directory.uidForUsername(query);

    if (uid == null) {
      emit(state.copyWith(lookupStatus: LookupStatus.notFound));
      return;
    }
    if (uid == state.uid) {
      // Sharing your own code with yourself is a common accident, and
      // "no matches" would be a confusing thing to say about it.
      emit(state.copyWith(lookupStatus: LookupStatus.isSelf));
      return;
    }
    if (await _social.areFriends(state.uid, uid)) {
      final profile = await _directory.profileFor(uid);
      emit(
        state.copyWith(
          lookupStatus: LookupStatus.alreadyFriend,
          lookupResult: profile,
        ),
      );
      return;
    }

    final profile = await _directory.profileFor(uid);
    emit(
      state.copyWith(
        lookupStatus: profile == null
            ? LookupStatus.notFound
            : LookupStatus.found,
        lookupResult: profile,
      ),
    );
  }

  void _onLookupCleared(
    FriendsLookupCleared event,
    Emitter<FriendsState> emit,
  ) {
    emit(state.copyWith(clearLookup: true, clearError: true));
  }

  Future<void> _onRequestSent(
    FriendsRequestSent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await _social.sendFriendRequest(fromUid: state.uid, toUid: event.toUid);
      await _directory.sendRequest(fromUid: state.uid, toUid: event.toUid);
      emit(state.copyWith(sentTo: {...state.sentTo, event.toUid}));
    } catch (e) {
      // The repository throws a StateError carrying the reason — a
      // crossed request, or already friends. Its message is the most
      // useful thing to show.
      emit(
        state.copyWith(
          error: e is StateError ? e.message : AppStrings.friendsSendFailed,
        ),
      );
    }
  }

  Future<void> _onRequestAnswered(
    FriendsRequestAnswered event,
    Emitter<FriendsState> emit,
  ) async {
    final request = event.request;
    final response = event.accept
        ? FriendRequestStatus.accepted
        : FriendRequestStatus.declined;
    try {
      // Local first: it is the source the UI reads, and the transaction
      // there is what guarantees an accept cannot exist without its
      // friendship.
      await _social.respondToFriendRequest(
        requestId: request.id,
        response: response,
      );
      await _directory.respondToRequest(
        fromUid: request.fromUid,
        toUid: request.toUid,
        response: response,
      );
      if (event.accept) {
        await _directory.createFriendship(a: request.fromUid, b: request.toUid);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Friends] answering failed: $e');
      emit(state.copyWith(error: AppStrings.friendsSendFailed));
    }
    add(const FriendsRefreshed());
  }

  Future<void> _onRemoved(
    FriendsRemoved event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await _social.removeFriend(
        ownerUid: state.uid,
        friendUid: event.friendUid,
      );
      await _directory.deleteFriendship(a: state.uid, b: event.friendUid);
    } catch (e) {
      if (kDebugMode) debugPrint('[Friends] remove failed: $e');
    }
    add(const FriendsRefreshed());
  }

  @override
  Future<void> close() async {
    await _friendsSub?.cancel();
    await _requestsSub?.cancel();
    return super.close();
  }
}
