import 'package:flutter/foundation.dart';

/// How long after a challenge's window closes its result can still move.
///
/// **The competition ends at `endAt`. The result becomes final at
/// `endAt + kChallengeFinalizationGrace`. These are different moments
/// and nothing in this codebase may conflate them.**
///
/// The grace exists because a drive taken immediately before `endAt` may
/// need publishing after the competitive window has closed — the trip
/// ends at 23:50, the app is killed before the publish lands, and the
/// figure goes up when the app is next opened. The grace bounds how late
/// that is allowed to be: within six hours of `endAt`, and not a minute
/// more. A reopen after that publishes nothing, by design. That is the
/// price of the result ever being final, and it is written here so
/// nobody later reads the grace as "late publishes accepted
/// indefinitely".
///
/// Declaring a winner at `endAt` while writes were still permitted would
/// let a settled result change after being announced: A leads 100–90 at
/// 23:00, both devices show A winning, then B's genuine last drive
/// publishes 120 at 01:00 and B is actually ahead. Two devices would
/// report different winners depending on when they looked.
///
/// **This value is repeated as a literal in `firestore.rules`**, which
/// cannot import Dart. `challenge_rules_contract_test.dart` parses it
/// back out and asserts the two agree — two boundaries drifting apart is
/// exactly the bug this constant exists to prevent, and a comment would
/// not have caught it.
const Duration kChallengeFinalizationGrace = Duration(hours: 6);

/// Where a head-to-head challenge stands.
///
/// Three phases, and the boundary the security rules enforce is the
/// boundary this reads:
///
/// * before `endAt` — [leading] / [trailing] / [tied], provisional;
/// * `endAt` until `endAt + kChallengeFinalizationGrace` —
///   [finalizing]: the competition is over, the figures may still move,
///   and **no winner is named**;
/// * after that — [won] / [lost] / [drew] / [undecided], final, and
///   frozen by the rules.
///
/// Plus [expired], which is not a phase but a challenge that never
/// happened: still `pending` when its window closed. Since acceptance is
/// refused after `endAt`, such a challenge is permanently dead.
enum ChallengeOutcome {
  /// Ahead, with driving still to come.
  leading,

  /// Behind, with driving still to come.
  trailing,

  /// Level, with driving still to come.
  tied,

  /// The window has closed but the figures are not frozen yet. **Never
  /// name a winner here** — that is the whole reason this state exists.
  finalizing,

  won,
  lost,
  drew,

  /// Final, and there is no result: the challenge was accepted and the
  /// opponent never published a figure.
  ///
  /// Distinct from [expired] on purpose. Absent is not zero — the same
  /// rule the friends board follows — so an opponent who went quiet does
  /// not hand the viewer a win over a figure nobody reported.
  undecided,

  /// Nobody ever accepted it, so there was no competition to settle.
  ///
  /// Distinct from [undecided]: collapsing the two would tell one person
  /// they were ignored when in fact they never answered, or the reverse.
  expired;

  /// Whether the figures behind this are frozen and the answer will not
  /// change. [expired] counts — a challenge nobody accepted is as
  /// settled as anything gets.
  bool get isFinal => switch (this) {
    won || lost || drew || undecided || expired => true,
    leading || trailing || tied || finalizing => false,
  };

  /// Whether the viewer took part in a challenge that reached a result.
  ///
  /// What `firstChallenge` is awarded for: turning up counts, and
  /// winning is a different trophy. [expired] is excluded because
  /// nobody accepted — an invitation that lapsed is not participation.
  bool get isFinishedContest => switch (this) {
    won || lost || drew || undecided => true,
    expired || leading || trailing || tied || finalizing => false,
  };
}

/// The two sides of a challenge, plus what they add up to.
@immutable
class ChallengeSettlement {
  const ChallengeSettlement({
    required this.outcome,
    required this.mine,
    required this.theirs,
    required this.finalAt,
  });

  final ChallengeOutcome outcome;

  /// The viewer's figure. Always known — it is computed from their own
  /// trips.
  final double mine;

  /// The opponent's published figure, or null when they have not
  /// published one. **Null is not zero.**
  final double? theirs;

  /// The moment the result stops being able to change:
  /// `endAt + kChallengeFinalizationGrace`.
  final DateTime finalAt;

  bool get isFinal => outcome.isFinal;

  /// How long until the figures freeze, or null once they have.
  Duration? remainingUntilFinal(DateTime now) =>
      now.isBefore(finalAt) ? finalAt.difference(now) : null;
}
