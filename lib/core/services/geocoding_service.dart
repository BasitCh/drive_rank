import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:injectable/injectable.dart';

/// Reverse-geocodes a lat/lng into a short, human-readable place name
/// for the trip card footer (e.g. "Bahawalpur District, Pakistan").
///
/// Uses the platform's on-device geocoder (Play services on Android,
/// CoreLocation on iOS) — no network API key, no paid service. Every
/// call is best-effort: on failure or timeout this returns null and
/// the caller falls back to showing the date alone, never a
/// placeholder or error string.
@lazySingleton
class GeocodingService {
  GeocodingService();

  static const Duration _timeout = Duration(seconds: 5);

  Future<String?> placeName(double lat, double lng) async {
    try {
      final placemarks = await geocoding
          .placemarkFromCoordinates(lat, lng)
          .timeout(_timeout);
      if (placemarks.isEmpty) return null;
      return _format(placemarks.first);
    } catch (e) {
      if (kDebugMode) debugPrint('[GeocodingService] lookup failed: $e');
      return null;
    }
  }

  /// Prefers a district/region-level name over the raw locality so the
  /// footer reads like "Bahawalpur District, Pakistan" rather than a
  /// street address. Falls back progressively; returns null only when
  /// every field the placemark offers is blank.
  String? _format(geocoding.Placemark p) {
    final region = _firstNonEmpty([
      p.subAdministrativeArea,
      p.administrativeArea,
      p.locality,
    ]);
    final country = _firstNonEmpty([p.country]);
    final parts = [
      if (region != null) region,
      if (country != null) country,
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
