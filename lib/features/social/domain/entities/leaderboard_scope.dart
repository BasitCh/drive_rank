import 'package:drive_rank/core/constants/app_strings.dart';

/// Who the board ranks the viewer against.
///
/// A *scope*, not a surface — the same podium, rows, rank card and
/// compare sheet with a different population in them. That's why it sits
/// beside metric and period as a third selector rather than becoming a
/// fourth tab next to Targets and Trophies: those two are personal
/// surfaces where "global or friends" would mean nothing, and a screen
/// with two rows of controls that switch different levels of thing is
/// how a screen becomes unreadable.
enum LeaderboardScope {
  /// The viewer against the fixed benchmark ladder.
  global,

  /// The viewer against the people they actually added.
  friends;

  String get label => switch (this) {
    global => AppStrings.rankingsScopeGlobal,
    friends => AppStrings.rankingsScopeFriends,
  };
}
