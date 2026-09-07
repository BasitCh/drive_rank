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

/// Re-reads what the page shows.
///
/// [fromCloud] distinguishes the two callers: a pull-to-refresh must
/// actually reach Firestore, while the many internal refreshes that
/// follow a local write only need to re-read Drift — the write is
/// already there, and a network round-trip per action would make every
/// tap feel slow.
class FriendsRefreshed extends FriendsEvent {
  const FriendsRefreshed({this.fromCloud = false});
  final bool fromCloud;
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

/// Withdraws a request the viewer sent and that hasn't been answered.
class FriendsRequestCancelled extends FriendsEvent {
  const FriendsRequestCancelled(this.toUid);
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
/// What the lookup found, and therefore what the sheet may offer.
///
/// [requestSent] and [requestReceived] exist because the sheet used to
/// know neither: an outstanding request left it showing a live ADD
/// button that the repository then refused, and since a sent request
/// appears nowhere in the app, there was no way to see it, withdraw it,
/// or get past it. The lookup answers the question the button was
/// guessing at.
enum LookupStatus {
  idle,
  searching,
  notFound,
  found,
  isSelf,
  alreadyFriend,

  /// The viewer already asked this person, and they haven't answered.
  requestSent,

  /// This person already asked the viewer — the answer is on the
  /// Friends screen, and asking back would cross the two requests.
  requestReceived,

  /// Asking is not possible from this side: they declined an earlier
  /// request and nothing has superseded it. They can still add the
  /// viewer, which is the one thing worth saying.
  theyMustAsk,
}

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
    this.outgoing = const [],
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

  /// Requests the viewer sent and nobody has answered.
  ///
  /// Shown on the page, which it wasn't: a sent request existed only in
  /// Firestore and in a set that died with the sheet, so the sender had
  /// no way to see it, no way to withdraw it, and no way past the guard
  /// that then refused to send it again.
  final List<FriendRequest> outgoing;

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
    List<FriendRequest>? outgoing,
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
    outgoing: outgoing ?? this.outgoing,
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
    on<FriendsRequestCancelled>(_onRequestCancelled);
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
    // …and keep listening, so a request that arrives while this page is
    // open shows up without closing and reopening it.
    await _sync.start();
    // Two awaits stand between here and the event above, and leaving
    // the page inside them closed the bloc — `add` on a closed bloc
    // throws, so opening Friends and going straight back crashed.
    if (isClosed) return;
    add(const FriendsRefreshed());
  }

  Future<void> _onRefreshed(
    FriendsRefreshed event,
    Emitter<FriendsState> emit,
  ) async {
    // A pull-to-refresh that only re-read Drift looked like a refresh
    // and fetched nothing — the gesture has to reach the cloud, which
    // is the whole reason someone reaches for it.
    if (event.fromCloud) await _sync.syncNow();
    final uid = state.uid.isEmpty ? (await _settings.read()).uid : state.uid;
    final friends = await _social.getFriends(uid);
    final requests = await _social.watchIncomingRequests(uid).first;
    final pending = requests
        .where((r) => r.status == FriendRequestStatus.pending)
        .toList();
    final friendUids = {for (final f in friends) f.friendUid};
    final sent = (await _social.getOutgoingRequests(uid))
        .where(
          (r) =>
              r.status == FriendRequestStatus.pending &&
              // Somebody who is already a friend cannot also be
              // somebody you are waiting on. Belt to the listener's
              // braces: the request's own status arrives on its own
              // stream, and this makes the list right on the frame the
              // friendship lands even if that status is a beat behind.
              !friendUids.contains(r.toUid),
        )
        .toList();

    // Whoever is on either side of a request is somebody the page has
    // to name, so their profile is fetched like a friend's.
    final counterparties = {
      for (final r in pending) r.fromUid,
      for (final r in sent) r.toUid,
    };

    // Profiles are best-effort decoration: a friend with no published
    // mirror still belongs in the list, under their local record.
    final profiles = <String, CompetitionMirror>{...state.friendProfiles};
    for (final uid in {
      for (final friend in friends) friend.friendUid,
      ...counterparties,
    }) {
      if (profiles.containsKey(uid)) continue;
      final profile = await _directory.profileFor(uid);
      if (profile != null) profiles[uid] = profile;
    }

    emit(
      state.copyWith(
        isLoading: false,
        friends: friends,
        friendProfiles: profiles,
        incoming: pending,
        outgoing: sent,
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
    if (profile == null) {
      emit(state.copyWith(lookupStatus: LookupStatus.notFound));
      return;
    }

    // An outstanding request in either direction. Checked here rather
    // than left to the send path, which could only report it as an
    // error after the user had already committed to the action.
    //
    // Read from the table, not from `state.incoming`: that is filled by
    // a refresh, and the sheet can be open before the first one lands.
    // Every status, not just pending — what has already happened
    // between these two is exactly what decides whether asking is
    // possible.
    final incoming = await _social.getIncomingRequests(state.uid);
    final theyAsked = incoming.any(
      (r) => r.fromUid == uid && r.status == FriendRequestStatus.pending,
    );
    if (theyAsked) {
      emit(
        state.copyWith(
          lookupStatus: LookupStatus.requestReceived,
          lookupResult: profile,
        ),
      );
      return;
    }
    final outgoing = await _social.getOutgoingRequests(state.uid);
    final mine = outgoing.where((r) => r.toUid == uid);
    if (mine.any((r) => r.status == FriendRequestStatus.pending)) {
      emit(
        state.copyWith(
          lookupStatus: LookupStatus.requestSent,
          lookupResult: profile,
        ),
      );
      return;
    }

    // A decline this side cannot write past. It stops being binding
    // once the two have actually been friends — proven by the other
    // direction reaching `accepted` or `ended` — which is the same
    // condition the security rules check before allowing the re-ask.
    // Duplicated here on purpose: the alternative is offering a button
    // whose write the cloud refuses, and reporting that refusal as
    // "try again" when trying again can never work.
    final supersededByFriendship = incoming.any(
      (r) =>
          r.fromUid == uid &&
          (r.status == FriendRequestStatus.accepted ||
              r.status == FriendRequestStatus.ended),
    );
    final declinedByThem = mine.any(
      (r) => r.status == FriendRequestStatus.declined,
    );

    emit(
      state.copyWith(
        lookupStatus: declinedByThem && !supersededByFriendship
            ? LookupStatus.theyMustAsk
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
    final id = friendRequestKey(fromUid: state.uid, toUid: event.toUid);
    try {
      await _social.sendFriendRequest(fromUid: state.uid, toUid: event.toUid);
    } catch (e) {
      // The repository throws a StateError carrying the reason — a
      // crossed request, or already friends. Its message is the most
      // useful thing to show.
      emit(
        state.copyWith(
          error: e is StateError ? e.message : AppStrings.friendsSendFailed,
        ),
      );
      return;
    }

    try {
      await _directory.sendRequest(fromUid: state.uid, toUid: event.toUid);
    } catch (e) {
      // **The local row must not outlive a failed remote write.** A
      // local `pending` with nothing behind it is invisible to the
      // person it was addressed to, blocks every later attempt to ask
      // them, and cannot be withdrawn — there is no remote document to
      // withdraw. That trap is what a real device was found in. Undo
      // the local half and report the failure honestly.
      if (kDebugMode) debugPrint('[Friends] remote send failed: $e');
      try {
        await _social.cancelFriendRequest(id, byUid: state.uid);
      } catch (rollback) {
        if (kDebugMode) debugPrint('[Friends] rollback failed: $rollback');
      }
      emit(state.copyWith(error: AppStrings.friendsSendFailed));
      return;
    }

    emit(
      state.copyWith(
        // The status, not just the set: it is what survives the sheet
        // being rebuilt, and what a fresh lookup will find too.
        lookupStatus: state.lookupResult?.uid == event.toUid
            ? LookupStatus.requestSent
            : state.lookupStatus,
        sentTo: {...state.sentTo, event.toUid},
      ),
    );
    add(const FriendsRefreshed());
  }

  /// Withdraws a request the viewer sent.
  ///
  /// The repository and the rules have supported this since 4b and
  /// nothing ever called it, which is what made a sent request
  /// permanent: it was invisible, unanswerable by the sender, and it
  /// blocked every later attempt to add that person.
  Future<void> _onRequestCancelled(
    FriendsRequestCancelled event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      // Local first, as everywhere else here: it is what the UI reads.
      await _social.cancelFriendRequest(
        friendRequestKey(fromUid: state.uid, toUid: event.toUid),
        byUid: state.uid,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Friends] local cancel failed: $e');
      emit(state.copyWith(error: AppStrings.friendsCancelFailed));
      return;
    }

    try {
      await _directory.cancelRequest(fromUid: state.uid, toUid: event.toUid);
    } catch (e) {
      // **Best-effort, and deliberately not an error.** The two ways
      // this fails are a request with no remote document — in which
      // case there is nothing to withdraw and the local row was the
      // whole problem — and being offline, where the next sync pass
      // reconciles from the cloud either way. Reporting "couldn't
      // withdraw" over a local row that *was* withdrawn is what left
      // the withdrawal looking broken while it had in fact worked.
      if (kDebugMode) debugPrint('[Friends] remote cancel skipped: $e');
    }

    // Straight back to a person you can ask, so withdrawing by mistake
    // costs one tap rather than locking the sheet.
    emit(
      state.copyWith(
        lookupStatus: LookupStatus.found,
        sentTo: {...state.sentTo}..remove(event.toUid),
        clearError: true,
      ),
    );
    add(const FriendsRefreshed());
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
    // The live listeners belong to the page's lifetime — a Firestore
    // subscription left running behind a closed screen is a bill and a
    // leak.
    await _sync.stop();
    return super.close();
  }
}
