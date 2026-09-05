import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the honesty of the trophies grid.
///
/// Four of the seven trophies can't be earned yet — three need an
/// opponent and one needs a real ranking. Showing them with no
/// distinction would be telling the user to chase something
/// unreachable, so every type has to declare where it stands.
void main() {
  test('every trophy has a title and a description', () {
    for (final type in TrophyType.values) {
      expect(type.title, isNotEmpty, reason: '${type.name} has no title');
      expect(
        type.description,
        isNotEmpty,
        reason: '${type.name} has no description',
      );
    }
  });

  test('titles and descriptions are unique, so two trophies can never '
      'look like the same one', () {
    final titles = TrophyType.values.map((t) => t.title).toSet();
    final bodies = TrophyType.values.map((t) => t.description).toSet();
    expect(titles, hasLength(TrophyType.values.length));
    expect(bodies, hasLength(TrophyType.values.length));
  });

  test('exactly the three locally computable trophies are earnable now', () {
    final earnable = TrophyType.values.where((t) => t.isEarnableNow).toSet();
    expect(earnable, {
      TrophyType.firstTarget,
      TrophyType.roadWarrior,
      TrophyType.consistent,
    });
  });

  test('every unearnable trophy explains why, and every earnable one '
      'has nothing to explain — adding a trophy without deciding its '
      'earnability fails here', () {
    for (final type in TrophyType.values) {
      if (type.isEarnableNow) {
        expect(
          type.unavailableReason,
          isNull,
          reason: '${type.name} is earnable but claims a blocker',
        );
      } else {
        expect(
          type.unavailableReason,
          isNotNull,
          reason: '${type.name} is unearnable with no reason given',
        );
        expect(type.unavailableReason, isNotEmpty);
      }
    }
  });

  test('the opponent-dependent trophies are the ones blocked on friends', () {
    for (final type in [
      TrophyType.firstChallenge,
      TrophyType.firstWin,
      TrophyType.rivalHunter,
    ]) {
      expect(type.isEarnableNow, isFalse);
      expect(type.unavailableReason, 'Needs friends');
    }
  });

  test('rank climber is blocked on real competitors, not on friends', () {
    expect(TrophyType.rankClimber.isEarnableNow, isFalse);
    expect(TrophyType.rankClimber.unavailableReason, 'Needs more drivers');
  });

  test('fromName round-trips every type and falls back safely', () {
    for (final type in TrophyType.values) {
      expect(TrophyType.fromName(type.name), type);
    }
    expect(TrophyType.fromName('not-a-trophy'), TrophyType.firstTarget);
  });
}
