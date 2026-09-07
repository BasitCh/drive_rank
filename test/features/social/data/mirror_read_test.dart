import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drive_rank/features/social/data/services/social_directory.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading somebody else's published document.
///
/// Every claim here is a claim the board then ranks a real person on, so
/// each one is about what the app is entitled to conclude from a field
/// that isn't there.
void main() {
  const distanceWeekly = 'distance_weekly';
  final now = DateTime(2026, 9, 6, 12);

  test('carries the identity fields a friend row renders with', () {
    final mirror = mirrorFromFirestore('bob-uid', {
      'username': 'bob',
      'carMake': 'Toyota',
      'carModel': 'Corolla',
      'countryCode': 'PK',
      'inviteCode': 'CODE1234',
    });

    expect(mirror.uid, 'bob-uid');
    expect(mirror.username, 'bob');
    expect(mirror.carMake, 'Toyota');
    expect(mirror.carModel, 'Corolla');
    expect(mirror.countryCode, 'PK');
    expect(mirror.inviteCode, 'CODE1234');
  });

  test('a published figure reads back as that figure', () {
    final mirror = mirrorFromFirestore('bob-uid', {distanceWeekly: 412.5});
    expect(
      mirror.hasTotalFor(CompetitionMetric.distance, LeaderboardPeriod.weekly),
      isTrue,
    );
    expect(
      mirror.totalFor(CompetitionMetric.distance, LeaderboardPeriod.weekly),
      412.5,
    );
  });

  test('an absent metric is absent, not zero — the reader used to coerce '
      'it and put a friend whose document predates the field at the '
      'bottom of the board as though they had sat still all week', () {
    final mirror = mirrorFromFirestore('bob-uid', {'username': 'bob'});

    expect(
      mirror.hasTotalFor(CompetitionMetric.distance, LeaderboardPeriod.weekly),
      isFalse,
    );
    // Display still gets a number; ranking consults hasTotalFor.
    expect(
      mirror.totalFor(CompetitionMetric.distance, LeaderboardPeriod.weekly),
      0,
    );
  });

  test('a published zero is present and is zero — somebody who really '
      'drove nothing said so', () {
    final mirror = mirrorFromFirestore('bob-uid', {distanceWeekly: 0});
    expect(
      mirror.hasTotalFor(CompetitionMetric.distance, LeaderboardPeriod.weekly),
      isTrue,
    );
    expect(
      mirror.totalFor(CompetitionMetric.distance, LeaderboardPeriod.weekly),
      0,
    );
  });

  test('an int reads back as a double, since Firestore may store either',
      () {
    final mirror = mirrorFromFirestore('bob-uid', {distanceWeekly: 300});
    expect(
      mirror.totalFor(CompetitionMetric.distance, LeaderboardPeriod.weekly),
      300.0,
    );
  });

  group('freshness', () {
    test('a mirror read carries its publication time', () {
      final published = DateTime(2026, 9, 5, 8);
      final mirror = mirrorFromFirestore('bob-uid', {
        'updatedAt': Timestamp.fromDate(published),
      });
      expect(mirror.updatedAt, published);
    });

    test('a figure inside the window is not stale', () {
      final mirror = mirrorFromFirestore('bob-uid', {
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      });
      expect(mirror.isStaleAt(now), isFalse);
    });

    test('a figure outside it is', () {
      final mirror = mirrorFromFirestore('bob-uid', {
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      });
      expect(mirror.isStaleAt(now), isTrue);
      expect(mirror.ageAt(now), const Duration(days: 5));
    });

    test('two days is the boundary, and two days exactly is still fresh — '
        'publishing happens a few times a day, so one quiet day is '
        'ordinary', () {
      expect(CompetitionMirror.staleAfter, const Duration(days: 2));

      final onTheLine = mirrorFromFirestore('bob-uid', {
        'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      });
      expect(onTheLine.isStaleAt(now), isFalse);

      final justOver = mirrorFromFirestore('bob-uid', {
        'updatedAt': Timestamp.fromDate(
          now.subtract(const Duration(days: 2, minutes: 1)),
        ),
      });
      expect(justOver.isStaleAt(now), isTrue);
    });

    test('a document with no timestamp is undated rather than fresh — '
        'reading a missing field as "now" would make an ancient document '
        'look like it arrived this second', () {
      final mirror = mirrorFromFirestore('bob-uid', {'username': 'bob'});
      expect(mirror.updatedAt, isNull);
      expect(mirror.ageAt(now), isNull);
      // And an undated figure is not accused of being stale either: the
      // app doesn't know, and saying so would be a guess.
      expect(mirror.isStaleAt(now), isFalse);
    });
  });
}
