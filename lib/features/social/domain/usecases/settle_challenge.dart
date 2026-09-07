import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/challenge_settlement.dart';
import 'package:injectable/injectable.dart';

/// Reads a result out of two independently-owned figures.
///
/// **No winner is ever stored.** The whole design of this phase turns on
/// that: a challenge record holds each participant's own self-reported
/// progress and immutable terms, so "who won" is a *reading* of two
/// numbers rather than a verdict somebody wrote. A `winnerUid` field
/// would be a document whose contents decide another person's loss, and
/// one client could forge it while the other could only disagree.
///
/// Because this is a pure function of the two figures and the boundary,
/// every device reaches the same answer whenever it looks — including
/// one that was offline for the whole finalization grace.
///
/// The trust model is 4c's, unchanged: the figures are self-reported and
/// nothing client-side can make them true. That is acceptable at
/// friends scale with nothing at stake, and **only** there. The moment a
/// challenge carries a prize, a payment or public standing, progress has
/// to come from a server-authoritative path.
@injectable
class SettleChallenge {
  const SettleChallenge();

  /// [mine] is the viewer's figure, recomputed from their own trips.
  /// [theirs] is what the opponent published, or null if they published
  /// nothing — **null is not zero**.
  ChallengeSettlement call({
    required Challenge challenge,
    required double mine,
    required double? theirs,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final finalAt = challenge.endAt.add(kChallengeFinalizationGrace);

    return ChallengeSettlement(
      outcome: _outcome(challenge: challenge, at: at, mine: mine, theirs: theirs),
      mine: mine,
      theirs: theirs,
      finalAt: finalAt,
    );
  }

  ChallengeOutcome _outcome({
    required Challenge challenge,
    required DateTime at,
    required double mine,
    required double? theirs,
  }) {
    // Never accepted, and — since acceptance is refused once the window
    // has closed — never acceptable again. There was no contest.
    final closed = !at.isBefore(challenge.endAt);
    if (closed && challenge.status == ChallengeStatus.pending) {
      return ChallengeOutcome.expired;
    }

    if (!closed) {
      // Provisional. Compared against zero rather than skipped when the
      // opponent hasn't published: while the window is open, "they have
      // nothing yet" is a fair reading of a live scoreboard, and the
      // label says LEADING rather than WON.
      final them = theirs ?? 0;
      if (mine > them) return ChallengeOutcome.leading;
      if (mine < them) return ChallengeOutcome.trailing;
      return ChallengeOutcome.tied;
    }

    // The window has closed but the figures can still legally move, so
    // there is nothing to declare. Naming a winner here is the exact
    // bug this state exists to prevent.
    if (at.isBefore(challenge.endAt.add(kChallengeFinalizationGrace))) {
      return ChallengeOutcome.finalizing;
    }

    // Final. Absent is not zero: an opponent who published nothing at
    // all leaves no result, rather than losing 0 to whatever the viewer
    // drove.
    if (theirs == null) return ChallengeOutcome.undecided;
    if (mine > theirs) return ChallengeOutcome.won;
    if (mine < theirs) return ChallengeOutcome.lost;
    return ChallengeOutcome.drew;
  }
}
