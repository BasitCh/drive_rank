import 'package:drive_rank/shared/models/leaderboard_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeaderboardScope.id', () {
    test('global has a stable id', () {
      expect(const LeaderboardScopeGlobal().id, 'global');
    });

    test('country id includes the country code', () {
      expect(
        const LeaderboardScopeCountry('PK').id,
        equals('country_PK'),
      );
    });

    test('segment id includes the segment id', () {
      expect(
        const LeaderboardScopeSegment('nurburgring', 'Nürburgring').id,
        equals('segment_nurburgring'),
      );
    });

    test('friends scope has a stable id', () {
      expect(const LeaderboardScopeFriends().id, 'friends');
    });
  });

  group('LeaderboardEntry.copyWith', () {
    const base = LeaderboardEntry(
      uid: 'u1',
      username: 'driver',
      carName: 'Toyota Corolla',
      topSpeedKmh: 142,
      country: 'PK',
      rank: 0,
    );

    test('promoting to rank 1 keeps other fields stable', () {
      final ranked = base.copyWith(rank: 1);
      expect(ranked.rank, 1);
      expect(ranked.uid, base.uid);
      expect(ranked.topSpeedKmh, base.topSpeedKmh);
      expect(ranked.isYou, isFalse);
    });

    test('marking as you keeps rank', () {
      final you = base.copyWith(rank: 12, isYou: true);
      expect(you.isYou, isTrue);
      expect(you.rank, 12);
    });
  });
}
