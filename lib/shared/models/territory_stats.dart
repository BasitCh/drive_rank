import 'package:flutter/foundation.dart';

/// "Territory Conquered" summary — every hex cell (see `HexGridService`)
/// the user has ever driven through, across all trips.
@immutable
class TerritoryStats {
  const TerritoryStats({
    required this.cellCount,
    required this.areaKm2,
    required this.percentOfEarth,
    this.percentOfCountry,
    this.cellIds = const <String>[],
  });

  factory TerritoryStats.empty() => const TerritoryStats(
    cellCount: 0,
    areaKm2: 0,
    percentOfEarth: 0,
  );

  final int cellCount;
  final double areaKm2;
  final double percentOfEarth;

  /// Null when the user's country isn't in `kCountryAreaKm2` — the UI
  /// hides the chip rather than showing a wrong number.
  final double? percentOfCountry;

  /// The visited cell ids — only populated when the full set is needed
  /// (the Territory map page), left empty for the lightweight summary
  /// used on the Profile card.
  final List<String> cellIds;
}
