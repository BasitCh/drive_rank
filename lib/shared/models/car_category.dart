/// Visual category of a car make — drives which SVG silhouette the car
/// picker, onboarding hero, and stat card car-tag render.
///
/// Persisted as a lowercase string in `car_makes.json` so the seed data can
/// be hand-edited or remote-pushed (Session-5 Firestore remote config)
/// without a code release.
enum CarCategory {
  sedan,
  suv,
  hatchback,
  pickup,
  sports,
  motorbike,
  defaultCategory;

  String get id => switch (this) {
    CarCategory.defaultCategory => 'default',
    _ => name,
  };

  /// Path to the matching SVG silhouette in `assets/images/cars/`.
  String get svgAssetPath => 'assets/images/cars/$id.svg';

  static CarCategory fromId(String? raw) {
    if (raw == null || raw.isEmpty) return CarCategory.defaultCategory;
    return switch (raw.toLowerCase()) {
      'sedan' => CarCategory.sedan,
      'suv' => CarCategory.suv,
      'hatchback' => CarCategory.hatchback,
      'pickup' => CarCategory.pickup,
      'sports' => CarCategory.sports,
      'motorbike' || 'motorcycle' || 'bike' => CarCategory.motorbike,
      _ => CarCategory.defaultCategory,
    };
  }
}
