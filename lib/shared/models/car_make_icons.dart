/// Registry of make ids that have a dedicated per-brand SVG silhouette at
/// `assets/images/makes/{id}.svg`, distinct from the 7 shared
/// category-level silhouettes in `assets/images/cars/` (see
/// `CarCategory.svgAssetPath`).
///
/// Deliberately an explicit, hand-maintained set rather than a runtime
/// "does this asset exist" probe — `flutter_svg`/`vector_graphics` throws
/// (uncaught, no error-builder hook) on a missing asset, so referencing a
/// make id before its file actually exists would crash the app. Add an id
/// here only once `assets/images/makes/{id}.svg` is committed.
///
/// Ids match `assets/data/car_makes.json` / `motorbike_makes.json` exactly
/// (e.g. `toyota`, `land_rover`, `bmw_moto`) — see `CarMake.id`.
const Set<String> makeIdsWithDedicatedIcon = <String>{
  // Cars (37)
  'toyota', 'honda', 'suzuki', 'ford', 'chevrolet', 'bmw', 'mercedes',
  'audi', 'volkswagen', 'hyundai', 'kia', 'nissan', 'mazda', 'subaru',
  'mitsubishi', 'lexus', 'porsche', 'tesla', 'jeep', 'ram', 'dodge', 'gmc',
  'land_rover', 'jaguar', 'volvo', 'peugeot', 'renault', 'fiat', 'skoda',
  'seat', 'mini', 'alfa_romeo', 'mg', 'byd', 'tata', 'mahindra', 'haval',
  // Motorbikes (17)
  'honda_moto', 'yamaha_moto', 'suzuki_moto', 'kawasaki_moto',
  'bajaj_moto', 'hero_moto', 'tvs_moto', 'royal_enfield_moto',
  'harley_davidson_moto', 'ducati_moto', 'bmw_moto', 'ktm_moto',
  'triumph_moto', 'vespa_moto', 'benelli_moto', 'cfmoto_moto',
  'aprilia_moto',
};

/// Path to a make's dedicated SVG, or null if it doesn't have one yet
/// (callers fall back to `CarCategory.svgAssetPath`).
String? makeIconAssetPath(String? makeId) {
  if (makeId == null || !makeIdsWithDedicatedIcon.contains(makeId)) {
    return null;
  }
  return 'assets/images/makes/$makeId.svg';
}
