import 'dart:math' as math;

import 'package:drive_rank/shared/models/leaderboard_entry.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:injectable/injectable.dart';

/// Returns ranked entries for a given scope.
///
/// The v1 implementation is a *seeded mock* that synthesises plausible
/// competitors deterministically from the scope id, then injects the user's
/// own personal-best trip into the list and re-ranks. Session 5 swaps in a
/// Firestore implementation behind the same interface — every UI layer that
/// renders a leaderboard stays unchanged.
// ignore: one_member_abstracts
abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getEntries({
    required LeaderboardScope scope,
    int limit = 50,
  });
}

@LazySingleton(as: LeaderboardRepository)
class MockLeaderboardRepository implements LeaderboardRepository {
  MockLeaderboardRepository(this._trips, this._settings);

  final TripRepository _trips;
  final UserSettingsRepository _settings;

  @override
  Future<List<LeaderboardEntry>> getEntries({
    required LeaderboardScope scope,
    int limit = 50,
  }) async {
    if (scope is LeaderboardScopeFriends) return const <LeaderboardEntry>[];

    final settings = await _settings.read();
    final myCountry = settings.country ?? 'US';
    final myBest = await _trips.getPersonalBest(uid: settings.uid);

    // Synthesise a deterministic pool of competitors for this scope.
    final seeded = _seedPool(scope, myCountry, limit + 10);

    // Merge the user's own best trip in, if they have one.
    final merged = <LeaderboardEntry>[
      ...seeded,
      if (myBest != null && myBest.topSpeedKmh > 0)
        LeaderboardEntry(
          uid: settings.uid,
          username: settings.username.isEmpty ? 'you' : settings.username,
          carName: _carNameFor(settings.carMake, settings.carModel),
          topSpeedKmh: myBest.topSpeedKmh,
          country: settings.country ?? myCountry,
          rank: 0,
          isYou: true,
        ),
    ]..sort((a, b) => b.topSpeedKmh.compareTo(a.topSpeedKmh));

    // Rank from 1 and truncate.
    return List.generate(
      math.min(merged.length, limit),
      (i) => merged[i].copyWith(rank: i + 1),
    );
  }

  /// Deterministic competitor list seeded off the scope id so the rankings
  /// don't churn between visits. Mock pool — the speeds, names, and car
  /// makes are illustrative; the real list comes from Firestore.
  List<LeaderboardEntry> _seedPool(
    LeaderboardScope scope,
    String myCountry,
    int count,
  ) {
    final seed = scope.id.hashCode;
    final rand = math.Random(seed);
    final entries = <LeaderboardEntry>[];

    const names = [
      'zain_r',
      'ali_k',
      'sara_m',
      'omar_m',
      'hamza_r',
      'leila_v',
      'noah_t',
      'mia_s',
      'liam_w',
      'aisha_b',
      'kenji_o',
      'maya_d',
      'rico_p',
      'ines_g',
      'theo_l',
    ];
    const cars = [
      'Toyota Corolla',
      'Honda Civic',
      'BMW M3',
      'Ford Mustang',
      'Suzuki Swift',
      'Tesla Model 3',
      'Hyundai i30',
      'Mazda MX-5',
      'Nissan GT-R',
      'Volkswagen Golf',
    ];

    // Base speed top of the leaderboard depends on scope:
    //   - segments (Stelvio, Nürburgring, …) skew higher
    //   - country a touch above global average
    //   - global gets the widest spread
    final basis = switch (scope) {
      LeaderboardScopeSegment _ => 180.0,
      LeaderboardScopeCountry _ => 165.0,
      LeaderboardScopeGlobal _ => 200.0,
      LeaderboardScopeFriends _ => 140.0,
    };

    for (var i = 0; i < count; i++) {
      final speed = basis - i * 1.5 + rand.nextDouble() * 4 - 2;
      entries.add(
        LeaderboardEntry(
          uid: 'seed_${scope.id}_$i',
          username: names[(i + seed.abs()) % names.length],
          carName: cars[(i * 3 + seed.abs()) % cars.length],
          topSpeedKmh: speed.clamp(60, 250),
          country: scope is LeaderboardScopeCountry
              ? scope.countryCode
              : myCountry,
          rank: 0,
        ),
      );
    }
    return entries;
  }

  String _carNameFor(String make, String model) {
    final m = make.isEmpty ? 'Car' : make;
    return model.isEmpty ? m : '$m $model';
  }
}
