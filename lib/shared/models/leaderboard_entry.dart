import 'package:flutter/foundation.dart';

/// One row in any leaderboard board — global, country, road segment, or
/// friends. The rank is 1-indexed and assigned at fetch time.
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.carName,
    required this.topSpeedKmh,
    required this.country,
    required this.rank,
    this.isYou = false,
  });

  final String uid;
  final String username;
  final String carName;
  final double topSpeedKmh;
  final String country;
  final int rank;
  final bool isYou;

  LeaderboardEntry copyWith({int? rank, bool? isYou}) => LeaderboardEntry(
    uid: uid,
    username: username,
    carName: carName,
    topSpeedKmh: topSpeedKmh,
    country: country,
    rank: rank ?? this.rank,
    isYou: isYou ?? this.isYou,
  );
}

/// The scope a leaderboard query is over.
@immutable
sealed class LeaderboardScope {
  const LeaderboardScope();

  String get id;
  String get label;
}

class LeaderboardScopeGlobal extends LeaderboardScope {
  const LeaderboardScopeGlobal();
  @override
  String get id => 'global';
  @override
  String get label => 'Global';
}

class LeaderboardScopeCountry extends LeaderboardScope {
  const LeaderboardScopeCountry(this.countryCode);
  final String countryCode;
  @override
  String get id => 'country_$countryCode';
  @override
  String get label => countryCode;
}

class LeaderboardScopeSegment extends LeaderboardScope {
  const LeaderboardScopeSegment(this.segmentId, this.segmentName);
  final String segmentId;
  final String segmentName;
  @override
  String get id => 'segment_$segmentId';
  @override
  String get label => segmentName;
}

class LeaderboardScopeFriends extends LeaderboardScope {
  const LeaderboardScopeFriends();
  @override
  String get id => 'friends';
  @override
  String get label => 'Friends';
}
