import 'package:drive_rank/shared/models/car_category.dart';
import 'package:flutter/foundation.dart';

/// A car manufacturer loaded from `assets/data/car_makes.json`.
///
/// `popularIn` is a set of ISO 3166-1 alpha-2 country codes where this make
/// is in the top sellers. The car picker uses it to sort locally-popular
/// makes to the top of the list without permanently pinning any country.
@immutable
class CarMake {
  const CarMake({
    required this.id,
    required this.name,
    required this.category,
    required this.popularIn,
    required this.models,
  });

  factory CarMake.fromJson(Map<String, dynamic> json) => CarMake(
    id: json['id'] as String,
    name: json['name'] as String,
    category: CarCategory.fromId(json['category'] as String?),
    popularIn: <String>{
      for (final c in (json['popularIn'] as List<dynamic>? ?? <dynamic>[]))
        c as String,
    },
    models: <String>[
      for (final m in (json['models'] as List<dynamic>? ?? <dynamic>[]))
        m as String,
    ],
  );

  final String id;
  final String name;
  final CarCategory category;
  final Set<String> popularIn;
  final List<String> models;

  /// True if this make is locally popular in the given country code.
  bool isPopularIn(String countryCode) => popularIn.contains(countryCode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CarMake && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
