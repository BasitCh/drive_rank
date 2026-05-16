import 'package:flutter/foundation.dart';

/// A famous (or just heavily-trafficked) road segment, loaded from
/// `assets/data/road_segments.json` plus future Firestore remote config.
///
/// A trip is tagged with a segment when its waypoint bounding box overlaps
/// the segment's bbox. Segments are how DriveRank populates per-road
/// leaderboards (Nürburgring, Karakoram Highway, M25, etc).
@immutable
class RoadSegment {
  const RoadSegment({
    required this.id,
    required this.name,
    required this.country,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  factory RoadSegment.fromJson(Map<String, dynamic> json) {
    final bbox = (json['bbox'] as Map).cast<String, dynamic>();
    return RoadSegment(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      minLat: (bbox['minLat'] as num).toDouble(),
      maxLat: (bbox['maxLat'] as num).toDouble(),
      minLng: (bbox['minLng'] as num).toDouble(),
      maxLng: (bbox['maxLng'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final String country;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  /// True if [lat]/[lng] falls inside this segment's bounding box.
  bool contains(double lat, double lng) =>
      lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;

  /// True if the two boxes overlap at all — used when matching a trip's
  /// own bbox against a segment, so the trip doesn't need to thread the
  /// needle of a single GPS sample landing inside the box.
  bool overlapsBbox({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) {
    if (maxLat < this.minLat) return false;
    if (minLat > this.maxLat) return false;
    if (maxLng < this.minLng) return false;
    if (minLng > this.maxLng) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is RoadSegment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
