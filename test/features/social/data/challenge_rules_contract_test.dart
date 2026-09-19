import 'dart:io';

import 'package:drive_rank/features/social/domain/entities/challenge_settlement.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the finalization boundary across two languages.
///
/// A challenge's competition ends at `endAt`; its result is final at
/// `endAt + kChallengeFinalizationGrace`. **The security rules enforce
/// that same boundary as a literal**, because `firestore.rules` cannot
/// import Dart.
///
/// If the two drift apart, nothing fails loudly: the rules keep
/// accepting writes for one duration while `SettleChallenge` declares a
/// winner after another, and a settled result can change after being
/// announced — two devices reporting different winners depending on when
/// they looked. That is the exact bug the three-phase settlement was
/// designed to prevent, and it would sail through every unit test and
/// every emulator test, because each side is internally consistent.
///
/// Same technique as `mirror_rules_contract_test.dart`, for the same
/// reason: a comment asking two files to agree is not a mechanism.
void main() {
  test('the progress freeze in firestore.rules is exactly '
      'kChallengeFinalizationGrace', () {
    final rules = File('firestore.rules').readAsStringSync();

    // The `duration.value(N, 'unit')` added to endAt in the progress
    // write rule — the freeze, and nothing else in that block adds a
    // duration to endAt.
    final match = RegExp(
      r"parent\(\)\.data\.endAt \+ duration\.value\((\d+), '([smhd])'\)",
    ).firstMatch(rules);

    expect(
      match,
      isNotNull,
      reason:
          'the progress freeze has moved or changed shape in '
          'firestore.rules — find it and keep this test honest, because '
          'it is the only thing tying the two boundaries together',
    );

    final amount = int.parse(match!.group(1)!);
    final grace = switch (match.group(2)!) {
      's' => Duration(seconds: amount),
      'm' => Duration(minutes: amount),
      'h' => Duration(hours: amount),
      'd' => Duration(days: amount),
      _ => throw StateError('unhandled duration unit'),
    };

    expect(
      grace,
      kChallengeFinalizationGrace,
      reason:
          'the rules freeze progress after $grace but Dart settles after '
          '$kChallengeFinalizationGrace. A result would be declared while '
          'it could still change, or stay unsettled after it was frozen.',
    );
  });

  test('the rules require acceptance before endAt, so a challenge cannot '
      'be answered after the window it was meant to measure', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(
      rules,
      contains('request.time < existing().endAt'),
      reason: 'the acceptance cutoff has gone; a challenge left pending '
          'could be accepted after its window closed and then have '
          'progress published during the grace',
    );
  });

  test('no rule writes an outcome — the result is derived from two '
      'frozen figures, so any mention of a winner field in the rules '
      'means somebody has started storing verdicts', () {
    final rules = File('firestore.rules').readAsStringSync().toLowerCase();
    // The comments explain that no winner is stored, so look only at
    // what the rules would let through: a field named for a winner.
    expect(rules, isNot(contains("'winneruid'")));
    expect(rules, isNot(contains("'winner'")));
  });
}
