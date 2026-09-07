import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_settlement.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/usecases/get_challenges.dart';
import 'package:drive_rank/features/social/presentation/widgets/challenge_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The card is where a wrong finalization boundary would be most
/// visible: one that named a winner the moment the window closed would
/// contradict itself hours later, when an honest late figure landed. So
/// these pin that the copy maps one-to-one onto `ChallengeOutcome`, and
/// especially that **nothing names a winner while finalizing**.
void main() {
  final endAt = DateTime(2026, 9, 14);

  Challenge challenge({
    ChallengeStatus status = ChallengeStatus.active,
  }) => Challenge(
    id: 'c1',
    creatorUid: 'me',
    opponentUid: 'them',
    metric: CompetitionMetric.distance,
    targetValue: 100,
    period: LeaderboardPeriod.weekly,
    startAt: DateTime(2026, 9, 10),
    endAt: endAt,
    status: status,
    createdAt: DateTime(2026, 9, 10),
    updatedAt: DateTime(2026, 9, 10),
  );

  ChallengeView view({
    required ChallengeOutcome outcome,
    double mine = 420,
    double? theirs = 385,
    bool isMine = true,
    ChallengeStatus status = ChallengeStatus.active,
  }) => ChallengeView(
    challenge: challenge(status: status),
    settlement: ChallengeSettlement(
      outcome: outcome,
      mine: mine,
      theirs: theirs,
      finalAt: endAt.add(kChallengeFinalizationGrace),
    ),
    opponentUid: 'them',
    isMine: isMine,
  );

  Future<void> pump(
    WidgetTester tester,
    ChallengeView v, {
    VoidCallback? onAccept,
    VoidCallback? onDecline,
    VoidCallback? onWithdraw,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChallengeCard(
            view: v,
            metricLabel: 'Distance · This week',
            formatValue: (value) => '${value.round()} km',
            deadlineLabel: 'Ends Sunday',
            remainingLabel: '5 hours',
            onAccept: onAccept,
            onDecline: onDecline,
            onWithdraw: onWithdraw,
          ),
        ),
      ),
    );
  }

  group('while there is driving to come', () {
    testWidgets('shows both figures and who is ahead, without claiming a '
        'result', (tester) async {
      await pump(tester, view(outcome: ChallengeOutcome.leading));

      expect(find.text('420 km'), findsOneWidget);
      expect(find.text('385 km'), findsOneWidget);
      expect(find.text(AppStrings.challengeLeading), findsOneWidget);
      expect(find.text('Ends Sunday'), findsOneWidget);
      expect(find.text(AppStrings.challengeWon), findsNothing);
    });

    testWidgets('says behind when behind, and level when level',
        (tester) async {
      await pump(tester, view(outcome: ChallengeOutcome.trailing));
      expect(find.text(AppStrings.challengeTrailing), findsOneWidget);

      await pump(tester, view(outcome: ChallengeOutcome.tied));
      expect(find.text(AppStrings.challengeTied), findsOneWidget);
    });
  });

  group('while finalizing', () {
    testWidgets('names NO winner, however far ahead — the figures can '
        'still legally move, and a card that declared one here would '
        'contradict itself when an honest late publish landed',
        (tester) async {
      await pump(
        tester,
        view(outcome: ChallengeOutcome.finalizing, mine: 9999, theirs: 1),
      );

      expect(find.text(AppStrings.challengeFinalizing), findsOneWidget);
      for (final claim in [
        AppStrings.challengeWon,
        AppStrings.challengeLost,
        AppStrings.challengeDrew,
        AppStrings.challengeLeading,
      ]) {
        expect(find.text(claim), findsNothing, reason: claim);
      }
    });

    testWidgets('counts down to the freeze, not to the deadline — they '
        'are different moments and the card must not blur them',
        (tester) async {
      await pump(tester, view(outcome: ChallengeOutcome.finalizing));
      expect(
        find.text(AppStrings.challengeFinalIn('5 hours')),
        findsOneWidget,
      );
      expect(find.text('Ends Sunday'), findsNothing);
    });
  });

  group('once frozen', () {
    testWidgets('declares the result', (tester) async {
      await pump(tester, view(outcome: ChallengeOutcome.won));
      expect(find.text(AppStrings.challengeWon), findsOneWidget);

      await pump(tester, view(outcome: ChallengeOutcome.lost));
      expect(find.text(AppStrings.challengeLost), findsOneWidget);

      await pump(tester, view(outcome: ChallengeOutcome.drew));
      expect(find.text(AppStrings.challengeDrew), findsOneWidget);
    });

    testWidgets('an opponent who never published shows a dash rather '
        'than a zero, and no result — absent is not a figure of zero',
        (tester) async {
      await pump(
        tester,
        view(outcome: ChallengeOutcome.undecided, theirs: null),
      );

      expect(find.text(AppStrings.challengeUndecided), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0 km'), findsNothing);
      expect(find.text(AppStrings.challengeWon), findsNothing);
    });

    testWidgets('a challenge nobody accepted says it never started, '
        'which is a different story from being ignored', (tester) async {
      await pump(
        tester,
        view(
          outcome: ChallengeOutcome.expired,
          theirs: null,
          status: ChallengeStatus.pending,
        ),
      );
      expect(find.text(AppStrings.challengeExpired), findsOneWidget);
      expect(find.text(AppStrings.challengeUndecided), findsNothing);
    });
  });

  group('answering', () {
    testWidgets('one waiting on the viewer offers both answers, and '
        'reports which was chosen', (tester) async {
      var accepted = false;
      var declined = false;
      await pump(
        tester,
        view(
          outcome: ChallengeOutcome.tied,
          isMine: false,
          status: ChallengeStatus.pending,
          mine: 0,
          theirs: 0,
        ),
        onAccept: () => accepted = true,
        onDecline: () => declined = true,
      );

      expect(find.text(AppStrings.challengeAccept), findsOneWidget);
      await tester.tap(find.text(AppStrings.challengeDecline));
      expect(declined, isTrue);
      await tester.tap(find.text(AppStrings.challengeAccept));
      expect(accepted, isTrue);
    });

    testWidgets('one the viewer sent offers withdraw and no answers — '
        'accepting your own challenge is not a thing', (tester) async {
      var withdrawn = false;
      await pump(
        tester,
        view(
          outcome: ChallengeOutcome.tied,
          status: ChallengeStatus.pending,
          mine: 0,
          theirs: 0,
        ),
        onWithdraw: () => withdrawn = true,
      );

      expect(find.text(AppStrings.challengeAccept), findsNothing);
      expect(find.text(AppStrings.challengeAwaitingReply), findsOneWidget);
      await tester.tap(find.text(AppStrings.challengeWithdraw));
      expect(withdrawn, isTrue);
    });
  });
}
