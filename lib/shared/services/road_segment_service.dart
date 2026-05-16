import 'dart:convert';

import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/models/road_segment.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';

/// Loads `assets/data/road_segments.json` once and detects which segments
/// a trip overlaps. The trip → segment match is via bbox intersection — a
/// trip is tagged with a segment if any portion of the route lies inside
/// the segment box.
///
/// Future Firestore remote-config (Session 5) can override or extend this
/// list without an app release.
@lazySingleton
class RoadSegmentService {
  RoadSegmentService();

  List<RoadSegment>? _cache;

  Future<List<RoadSegment>> all() async {
    return _cache ??= await _loadFromAsset();
  }

  /// Segments belonging to a specific country. Cheap — runs over the cached
  /// list. Used to populate the leaderboard's country-filtered segment tabs.
  Future<List<RoadSegment>> forCountry(String countryCode) async {
    final list = await all();
    return list.where((s) => s.country == countryCode).toList();
  }

  /// Returns every segment whose bbox overlaps the trip's bbox. Order is
  /// stable (matches the source JSON order).
  Future<List<RoadSegment>> detectFromTrip(List<TripPoint> points) async {
    if (points.isEmpty) return const <RoadSegment>[];

    var minLat = points.first.lat;
    var maxLat = points.first.lat;
    var minLng = points.first.lng;
    var maxLng = points.first.lng;
    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    final list = await all();
    return list
        .where(
          (s) => s.overlapsBbox(
            minLat: minLat,
            maxLat: maxLat,
            minLng: minLng,
            maxLng: maxLng,
          ),
        )
        .toList();
  }

  Future<List<RoadSegment>> _loadFromAsset() async {
    final raw = await rootBundle.loadString('assets/data/road_segments.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['segments'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(RoadSegment.fromJson)
        .toList();
  }
}
