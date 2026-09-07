import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_settlement.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/usecases/settle_challenge.dart';
import 'package:flutter_test/flutter_test.dart';

/// The boundary, encoded.
///
/// A challenge's competition ends at `endAt`; its result is final only
/// at `endAt + kChallengeFinalizationGrace`. Declaring a winner at
/// `endAt` while the rules still permit writes is how two devices end up
/// reporting different winners depending on when they looked, so every
/// test here names which of the two moments it is about.
void main() {
  const settle = SettleChallenge();

  // Window closes Sunday midnight; the result is final at 06:00 Monday.
  final endAt = DateTime(2026, 9, 14);
  final finalAt = endAt.add(kChallengeFinalizationGrace);

  Challenge challenge({
    ChallengeStatus status = ChallengeStatus.active,
    double targetValue = 100,
  }) => Challenge(
    id: 'challenge-1',
    creatorUid: 'me',
    opponentUid: 'them',
    metric: CompetitionMetric.distance,
    targetValue: targetValue,
    period: LeaderboardPeriod.weekly,
    startAt: DateTime(2026, 9, 7),
    endAt: endAt,
    status: status,
    createdAt: DateTime(2026, 9, 7),
    updatedAt: DateTime(2026, 9, 7),
  );

  ChallengeSettlement at(
    DateTime when, {
    double mine = 100,
    double? theirs = 90,
    ChallengeStatus status = ChallengeStatus.active,
  }) => settle(
    challenge: challenge(status: status),
    mine: mine,
    theirs: theirs,
    now: when,
  );

  group('while the window is open', () {
    final midWeek = DateTime(2026, 9, 10, 12);

    test('ahead reads as leading, not won — nothing is decided yet', () {
      final result = at(midWeek, mine: 120, theirs: 80);
      expect(result.outcome, ChallengeOutcome.leading);
      expect(result.isFinal, isFalse);
    });

    test('behind reads as trailing', () {
      expect(at(midWeek, mine: 80, theirs: 120).outcome,
          ChallengeOutcome.trailing);
    });

    test('level reads as tied', () {
      expect(at(midWeek, mine: 100, theirs: 100).outcome,
          ChallengeOutcome.tied);
    });

    test('an opponent who has not published yet reads as behind on a '
        'live scoreboard — the label says LEADING, which claims nothing '
        'about a result', () {
      expect(at(midWeek, mine: 50, theirs: null).outcome,
          ChallengeOutcome.leading);
    });

    test('and reports how long until the figures freeze', () {
      final result = at(midWeek);
      expect(result.finalAt, finalAt);
      expect(result.remainingUntilFinal(midWeek), isNotNull);
    });
  });

  group('during the finalization grace', () {
    test('at endAt exactly, the result is NOT final — the competition is '
        'over but the figures can still legally move', () {
      final result = at(endAt, mine: 100, theirs: 90);
      expect(result.outcome, ChallengeOutcome.finalizing);
      expect(result.isFinal, isFalse);
    });

    test('one second before the freeze it is still not final', () {
      final result = at(finalAt.subtract(const Duration(seconds: 1)));
      expect(result.outcome, ChallengeOutcome.finalizing);
    });

    test('no winner is named however far ahead the viewer is', () {
      expect(
        at(endAt.add(const Duration(hours: 1)), mine: 9999, theirs: 1).outcome,
        ChallengeOutcome.finalizing,
      );
    });

    test('nor is a missing opponent figure treated as undecided yet — '
        'they still have time to publish', () {
      expect(
        at(endAt.add(const Duration(hours: 1)), theirs: null).outcome,
        ChallengeOutcome.finalizing,
      );
    });
  });

  group('once the figures are frozen', () {
    test('at the freeze itself the result is final', () {
      final result = at(finalAt, mine: 100, theirs: 90);
      expect(result.outcome, ChallengeOutcome.won);
      expect(result.isFinal, isTrue);
      expect(result.remainingUntilFinal(finalAt), isNull);
    });

    test('more is a win, less is a loss', () {
      expect(at(finalAt, mine: 120, theirs: 80).outcome,
          ChallengeOutcome.won);
      expect(at(finalAt, mine: 80, theirs: 120).outcome,
          ChallengeOutcome.lost);
    });

    test('level is a draw, never a win', () {
      expect(at(finalAt, mine: 100, theirs: 100).outcome,
          ChallengeOutcome.drew);
    });

    test('an opponent who never published leaves it undecided — absent '
        'is not zero, so a silent opponent does not hand the viewer a '
        'win over a figure nobody reported', () {
      final result = at(finalAt, mine: 500, theirs: null);
      expect(result.outcome, ChallengeOutcome.undecided);
      expect(result.isFinal, isTrue);
      expect(result.theirs, isNull);
    });
  });

  group('a challenge nobody accepted', () {
    test('settles as expired, not undecided — acceptance is refused once '
        'the window closes, so it is permanently dead, and telling the '
        'viewer their opponent went quiet would be a different and '
        'wrong story', () {
      final result = at(finalAt, status: ChallengeStatus.pending);
      expect(result.outcome, ChallengeOutcome.expired);
      expect(result.isFinal, isTrue);
    });

    test('is expired from the moment the window closes, without waiting '
        'out a grace there is nothing to finalize', () {
      expect(
        at(endAt, status: ChallengeStatus.pending).outcome,
        ChallengeOutcome.expired,
      );
    });

    test('but is still just pending while the window is open — it can '
        'yet be accepted', () {
      final result = at(
        DateTime(2026, 9, 10),
        status: ChallengeStatus.pending,
      );
      expect(result.outcome, isNot(ChallengeOutcome.expired));
    });
  });

  group('what the trophies key on', () {
    test('every finished contest counts as having taken part — a loss, '
        'a draw and an unanswered challenge all did', () {
      for (final outcome in [
        ChallengeOutcome.won,
        ChallengeOutcome.lost,
        ChallengeOutcome.drew,
        ChallengeOutcome.undecided,
      ]) {
        expect(outcome.isFinishedContest, isTrue, reason: '$outcome');
      }
    });

    test('an expired challenge is not participation — an invitation that '
        'lapsed is not a contest', () {
      expect(ChallengeOutcome.expired.isFinishedContest, isFalse);
      expect(ChallengeOutcome.expired.isFinal, isTrue);
    });

    test('nothing provisional counts, so no trophy can be awarded before '
        'the figures freeze', () {
      for (final outcome in [
        ChallengeOutcome.leading,
        ChallengeOutcome.trailing,
        ChallengeOutcome.tied,
        ChallengeOutcome.finalizing,
      ]) {
        expect(outcome.isFinishedContest, isFalse, reason: '$outcome');
        expect(outcome.isFinal, isFalse, reason: '$outcome');
      }
    });
  });

  test('the whole sequence the boundary exists for: ahead at the close, '
      'overtaken by an honest late publish during the grace, and both '
      'devices agree on the loser afterwards', () {
    final c = challenge();

    // 23:00 Sunday — the viewer is ahead, but nothing is declared.
    final open = settle(
      challenge: c,
      mine: 100,
      theirs: 90,
      now: endAt.subtract(const Duration(hours: 1)),
    );
    expect(open.outcome, ChallengeOutcome.leading);

    // Midnight: the window closes. Still no winner, even though the
    // viewer is ahead on the figures as they stand.
    final closing = settle(challenge: c, mine: 100, theirs: 90, now: endAt);
    expect(closing.outcome, ChallengeOutcome.finalizing);

    // 01:00 — the opponent's genuine last drive publishes and overtakes.
    final overtaken = settle(
      challenge: c,
      mine: 100,
      theirs: 120,
      now: endAt.add(const Duration(hours: 1)),
    );
    expect(overtaken.outcome, ChallengeOutcome.finalizing);

    // 06:00 — frozen. The viewer lost, and every device says so
    // whenever it looks, because the answer is a pure function of the
    // frozen figures and the boundary.
    for (final when in [
      finalAt,
      finalAt.add(const Duration(days: 1)),
      finalAt.add(const Duration(days: 30)),
    ]) {
      final settled = settle(
        challenge: c,
        mine: 100,
        theirs: 120,
        now: when,
      );
      expect(settled.outcome, ChallengeOutcome.lost, reason: '$when');
    }
  });

  test('the grace is six hours', () {
    expect(kChallengeFinalizationGrace, const Duration(hours: 6));
  });
}
