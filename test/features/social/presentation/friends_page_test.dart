import 'package:bloc_test/bloc_test.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/friend.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/presentation/bloc/friends_bloc.dart';
import 'package:drive_rank/features/social/presentation/pages/friends_page.dart';
import 'package:drive_rank/features/social/presentation/widgets/add_friend_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFriendsBloc extends MockBloc<FriendsEvent, FriendsState>
    implements FriendsBloc {}

void main() {
  setUpAll(
    () => registerFallbackValue(const FriendsLookupCleared()),
  );

  late _MockFriendsBloc bloc;

  setUp(() => bloc = _MockFriendsBloc());

  CompetitionMirror mirror({
    String uid = 'bob-uid',
    String username = 'bob',
    String country = 'PK',
  }) => CompetitionMirror(
    uid: uid,
    username: username,
    carMake: 'BMW',
    carModel: 'M3',
    countryCode: country,
    inviteCode: 'BOBB5678',
    totals: const {(CompetitionMetric.distance, LeaderboardPeriod.weekly): 301},
  );

  Friend friendTo(String uid) => Friend(
    id: 'pair',
    ownerUid: 'me-uid',
    friendUid: uid,
    status: 'active',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  FriendRequest requestTo(String uid) => FriendRequest(
    id: 'me-uid_$uid',
    fromUid: 'me-uid',
    toUid: uid,
    status: FriendRequestStatus.pending,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  FriendRequest requestFrom(String uid) => FriendRequest(
    id: '${uid}_me-uid',
    fromUid: uid,
    toUid: 'me-uid',
    status: FriendRequestStatus.pending,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<void> pumpSheet(WidgetTester tester, FriendsState state) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<FriendsBloc>.value(
            value: bloc,
            child: const AddFriendSheet(),
          ),
        ),
      ),
    );
  }

  group('the add-friend sheet', () {
    testWidgets('offers both ways in, because a code works for people a '
        'username cannot reach', (tester) async {
      await pumpSheet(tester, const FriendsState(isLoading: false));

      expect(find.text(AppStrings.friendsAddTitle), findsOneWidget);
      expect(find.text('CODE'), findsOneWidget);
      expect(find.text('USERNAME'), findsOneWidget);
    });

    testWidgets('says nothing at all before a search', (tester) async {
      await pumpSheet(tester, const FriendsState(isLoading: false));
      expect(find.text(AppStrings.friendsSearchNoResults), findsNothing);
      expect(find.text(AppStrings.friendsAddButton), findsNothing);
    });

    testWidgets('reports a miss plainly', (tester) async {
      await pumpSheet(
        tester,
        const FriendsState(
          isLoading: false,
          lookupStatus: LookupStatus.notFound,
        ),
      );
      expect(find.text(AppStrings.friendsSearchNoResults), findsOneWidget);
    });

    testWidgets('recognises your own code rather than calling it a miss — '
        'sharing a code with yourself is a common accident',
        (tester) async {
      await pumpSheet(
        tester,
        const FriendsState(isLoading: false, lookupStatus: LookupStatus.isSelf),
      );
      expect(find.text(AppStrings.friendsSelfCode), findsOneWidget);
      expect(find.text(AppStrings.friendsSearchNoResults), findsNothing);
    });

    testWidgets('shows who it found, with an actionable Add', (tester) async {
      await pumpSheet(
        tester,
        FriendsState(
          isLoading: false,
          lookupStatus: LookupStatus.found,
          lookupResult: mirror(),
        ),
      );

      expect(find.text('bob'), findsOneWidget);
      // Country, car and code, so ten people called "bob" are
      // distinguishable from each other.
      expect(find.textContaining('Pakistan'), findsOneWidget);
      expect(find.textContaining('BMW M3'), findsOneWidget);
      expect(find.textContaining('BOBB5678'), findsOneWidget);
      await tester.tap(find.text(AppStrings.friendsAddButton.toUpperCase()));
      // Captured rather than compared: the events are plain classes
      // without equality, so two instances of the same request are
      // never `==`.
      final sent = verify(() => bloc.add(captureAny())).captured;
      expect(
        sent.single,
        isA<FriendsRequestSent>().having((e) => e.toUid, 'toUid', 'bob-uid'),
      );
    });

    testWidgets('a request already sent offers the one thing left to do '
        'with it — withdraw it. It used to show an inert button, and '
        'looking the person up again showed a live ADD that the '
        'repository refused, so a sent request was a dead end nobody '
        'could see or undo', (tester) async {
      await pumpSheet(
        tester,
        FriendsState(
          isLoading: false,
          lookupStatus: LookupStatus.requestSent,
          lookupResult: mirror(),
        ),
      );

      expect(find.text(AppStrings.friendsAwaitingReply), findsOneWidget);
      expect(
        find.text(AppStrings.friendsAddButton.toUpperCase()),
        findsNothing,
      );

      await tester.tap(
        find.text(AppStrings.friendsCancelButton.toUpperCase()),
      );
      final events = verify(() => bloc.add(captureAny())).captured;
      expect(
        events.single,
        isA<FriendsRequestCancelled>().having(
          (e) => e.toUid,
          'toUid',
          'bob-uid',
        ),
      );
    });

    testWidgets('a request sent from this very sheet reads the same way, '
        'without waiting for another lookup', (tester) async {
      await pumpSheet(
        tester,
        FriendsState(
          isLoading: false,
          lookupStatus: LookupStatus.found,
          lookupResult: mirror(),
          sentTo: const {'bob-uid'},
        ),
      );
      expect(find.text(AppStrings.friendsAwaitingReply), findsOneWidget);
      expect(
        find.text(AppStrings.friendsCancelButton.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('when they asked first, the sheet says so and stays inert — '
        'asking back would cross the two requests, and the answer to '
        'theirs lives on the Friends screen', (tester) async {
      await pumpSheet(
        tester,
        FriendsState(
          isLoading: false,
          lookupStatus: LookupStatus.requestReceived,
          lookupResult: mirror(),
        ),
      );

      expect(find.text(AppStrings.friendsTheyAskedFirst), findsOneWidget);
      await tester.tap(find.text(AppStrings.friendsSentButton.toUpperCase()));
      verifyNever(() => bloc.add(any(that: isA<FriendsRequestSent>())));
      verifyNever(() => bloc.add(any(that: isA<FriendsRequestCancelled>())));
    });

    testWidgets('an existing friend is labelled as one', (tester) async {
      await pumpSheet(
        tester,
        FriendsState(
          isLoading: false,
          lookupStatus: LookupStatus.alreadyFriend,
          lookupResult: mirror(),
        ),
      );
      expect(
        find.text(AppStrings.friendsAddedButton.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('a failure shows the reason the repository gave, not a '
        'generic apology', (tester) async {
      await pumpSheet(
        tester,
        const FriendsState(
          isLoading: false,
          error: 'They have already sent you a request — accept it.',
        ),
      );
      expect(
        find.text('They have already sent you a request — accept it.'),
        findsOneWidget,
      );
    });
  });

  group('the friends page', () {
    Future<void> pumpPage(WidgetTester tester, FriendsState state) {
      when(() => bloc.state).thenReturn(state);
      return tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FriendsBloc>.value(
            value: bloc,
            child: const FriendsPage.forTesting(),
          ),
        ),
      );
    }

    testWidgets('leads with your own code, because sharing it is the one '
        'thing that works for everybody', (tester) async {
      await pumpPage(
        tester,
        const FriendsState(
          isLoading: false,
          uid: 'me-uid',
          inviteCode: 'ABCD1234',
          canBeFoundByName: true,
        ),
      );

      expect(find.text('ABCD1234'), findsOneWidget);
      expect(find.text(AppStrings.friendsYourCodeLabel), findsOneWidget);
    });

    testWidgets('says so when the account cannot be found by name — '
        'otherwise they would wonder why nobody finds them',
        (tester) async {
      await pumpPage(
        tester,
        const FriendsState(
          isLoading: false,
          inviteCode: 'ABCD1234',
          canBeFoundByName: false,
        ),
      );
      expect(find.text(AppStrings.friendsUnsearchableNotice), findsOneWidget);
    });

    testWidgets('hides that notice once the name is reserved',
        (tester) async {
      await pumpPage(
        tester,
        const FriendsState(
          isLoading: false,
          inviteCode: 'ABCD1234',
          canBeFoundByName: true,
        ),
      );
      expect(find.text(AppStrings.friendsUnsearchableNotice), findsNothing);
    });

    testWidgets('explains the empty state rather than showing a bare list',
        (tester) async {
      await pumpPage(
        tester,
        const FriendsState(isLoading: false, inviteCode: 'ABCD1234'),
      );
      expect(find.text(AppStrings.friendsEmptyTitle), findsOneWidget);
      expect(
        find.text(AppStrings.friendsIncomingTitle.toUpperCase()),
        findsNothing,
      );
    });

    testWidgets('lists a request the viewer sent, with the one action '
        'they have over it — it used to appear nowhere at all, so the '
        'only person who could withdraw it could not see it',
        (tester) async {
      await pumpPage(
        tester,
        FriendsState(
          isLoading: false,
          uid: 'me-uid',
          outgoing: [requestTo('bob-uid')],
          friendProfiles: {'bob-uid': mirror()},
        ),
      );

      expect(
        find.text(AppStrings.friendsSentTitle.toUpperCase()),
        findsOneWidget,
      );
      // Named from their published profile, not shown as a raw uid.
      expect(find.textContaining('bob'), findsOneWidget);
      expect(find.textContaining('bob-uid'), findsNothing);

      await tester.tap(find.text(AppStrings.friendsCancelButton));
      final events = verify(() => bloc.add(captureAny())).captured;
      expect(
        events.whereType<FriendsRequestCancelled>().single.toUid,
        'bob-uid',
      );
    });

    testWidgets('names an incoming request from the sender profile — a '
        'request the viewer cannot attribute is one they cannot answer',
        (tester) async {
      await pumpPage(
        tester,
        FriendsState(
          isLoading: false,
          uid: 'me-uid',
          incoming: [requestFrom('bob-uid')],
          friendProfiles: {'bob-uid': mirror()},
        ),
      );

      expect(find.textContaining('bob'), findsOneWidget);
      expect(find.textContaining('bob-uid'), findsNothing);
    });

    testWidgets('shows an incoming request with both answers', (tester) async {
      await pumpPage(
        tester,
        FriendsState(
          isLoading: false,
          uid: 'me-uid',
          inviteCode: 'ABCD1234',
          incoming: [requestFrom('bob-uid')],
        ),
      );

      expect(
        find.text(AppStrings.friendsIncomingTitle.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(AppStrings.friendsAccept), findsOneWidget);
      expect(find.text(AppStrings.friendsDecline), findsOneWidget);

      await tester.tap(find.text(AppStrings.friendsAccept));
      final answered = verify(() => bloc.add(captureAny())).captured;
      expect(
        answered.single,
        isA<FriendsRequestAnswered>().having((e) => e.accept, 'accept', true),
      );
    });

    testWidgets('lists a friend under their published name and car',
        (tester) async {
      await pumpPage(
        tester,
        FriendsState(
          isLoading: false,
          uid: 'me-uid',
          inviteCode: 'ABCD1234',
          friends: [friendTo('bob-uid')],
          friendProfiles: {'bob-uid': mirror()},
        ),
      );

      expect(find.text('bob'), findsOneWidget);
      expect(find.textContaining('Pakistan'), findsOneWidget);
      expect(find.textContaining('BOBB5678'), findsOneWidget);
      expect(find.text(AppStrings.friendsEmptyTitle), findsNothing);
    });

    testWidgets('still lists a friend who has never published — a friend '
        'with no drives yet is still a friend', (tester) async {
      await pumpPage(
        tester,
        FriendsState(
          isLoading: false,
          uid: 'me-uid',
          inviteCode: 'ABCD1234',
          friends: [friendTo('bob-uid')],
        ),
      );

      expect(find.text('bob-uid'), findsOneWidget);
      expect(find.text(AppStrings.friendsEmptyTitle), findsNothing);
    });
  });
}
