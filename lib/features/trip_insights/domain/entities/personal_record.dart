import 'package:flutter/foundation.dart';

/// Discrete record kinds shown in the Personal Records section.
///
/// Order matters: the first record that fires becomes the trip's "Best
/// Achievement" surfaced in the hero strip. The list itself is rendered
/// in this same order so the most impressive badge is at the top.
enum RecordKind {
  /// Trip's top speed beats every previous trip on this device.
  newPersonalBest,

  /// Longest distance ever — only awarded when current trip ≥ 5 km.
  longestRide,

  /// Best average speed ever — only awarded when current trip ≥ 10 min
  /// (so a 30-second highway sprint can't beat a real commute).
  bestAverageSpeed,

  /// Highest top speed of the calendar month — current trip ≥ 5 min.
  fastestThisMonth,

  /// Catch-all used when no specific badge fires but the trip still
  /// ranks in the user's top-3 by some stat. Keeps the section from
  /// going empty for a strong-but-not-best drive.
  personalRecord;

  String get title => switch (this) {
    newPersonalBest => 'New Personal Best',
    longestRide => 'Longest Ride',
    bestAverageSpeed => 'Best Average Speed',
    fastestThisMonth => 'Fastest This Month',
    personalRecord => 'Personal Record',
  };

  String get emoji => switch (this) {
    newPersonalBest => '🏆',
    longestRide => '🛣',
    bestAverageSpeed => '⚡',
    fastestThisMonth => '📅',
    personalRecord => '⭐',
  };
}

/// One badge displayed in the records list. `valueDisplay` is the
/// pre-formatted value (km/h or mph, with units) so the widget renders
/// without invoking `LocaleService` in its `build` — all formatting
/// happens in the use case.
@immutable
class PersonalRecord {
  const PersonalRecord({required this.kind, required this.valueDisplay});

  final RecordKind kind;
  final String valueDisplay;
}
