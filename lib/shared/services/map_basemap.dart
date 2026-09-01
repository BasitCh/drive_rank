import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Resolves which basemap the app's maps (journey replay, territory)
/// should use, based on whether a CARTO Basemaps API key was supplied
/// at build time via `--dart-define=CARTO_API_KEY=...`.
///
/// With a key: CARTO's "Dark Matter" raster tiles — the polished black
/// map that matches the app's dark theme, free up to 5M tile requests/
/// month (see https://carto.com/basemaps/apikey/). Without one: Esri's
/// key-less "World Street Map" as a light-but-functional fallback so
/// the app still renders a real map with no build config at all (e.g.
/// local dev builds that don't pass the define).
class MapBasemap {
  const MapBasemap._({
    required this.urlTemplate,
    required this.additionalOptions,
    required this.isDark,
    required this.backdropColor,
    required this.attributions,
  });

  factory MapBasemap.resolve() {
    const cartoKey = String.fromEnvironment('CARTO_API_KEY');
    if (cartoKey.isEmpty) return _esriStreetMap;
    return const MapBasemap._(
      urlTemplate:
          'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png?key={cartoKey}',
      additionalOptions: {'cartoKey': cartoKey},
      isDark: true,
      // Matches the tiles' own near-black background so there's no
      // colour flash while the first tiles are still loading.
      backdropColor: Color(0xFF0D0D12),
      // CARTO's basemap terms require both attributions to stay
      // visible — see https://carto.com/basemaps/apikey/.
      attributions: [
        TextSourceAttribution('OpenStreetMap'),
        TextSourceAttribution('CARTO'),
      ],
    );
  }

  static const _esriStreetMap = MapBasemap._(
    urlTemplate:
        'https://services.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    additionalOptions: {},
    isDark: false,
    // Approximates the tiles' own light cream background.
    backdropColor: Color(0xFFE0E3C8),
    attributions: [TextSourceAttribution('Esri')],
  );

  final String urlTemplate;
  final Map<String, String> additionalOptions;
  final bool isDark;
  final Color backdropColor;
  final List<TextSourceAttribution> attributions;
}
