import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

/// Frozen snapshot of an in-progress trip — what we persist between
/// the bloc and disk. Contains both bloc-private state (`startedAt`)
/// and the public stats so a fresh process can resume without losing
/// distance / duration / polyline.
@immutable
class ActiveTripSnapshot {
  const ActiveTripSnapshot({
    required this.startedAt,
    required this.stats,
    required this.wasPaused,
  });

  final DateTime startedAt;
  final LiveTripStats stats;

  /// True if the trip was paused when the snapshot was written. Drives
  /// whether the bloc restores to `paused` (true) or `idle-ish` paused
  /// (false — i.e. the process died while the trip was active). Either
  /// way the user lands in the paused surface and taps Resume to
  /// continue; we never auto-restart GPS without an explicit user
  /// action.
  final bool wasPaused;

  Map<String, dynamic> toMap() => {
    'schemaVersion': 1,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'wasPaused': wasPaused,
    'stats': _statsToMap(stats),
  };

  static ActiveTripSnapshot? fromMap(Map<String, dynamic> raw) {
    if (raw['schemaVersion'] != 1) return null;
    final startedAtMs = raw['startedAt'] as int?;
    final statsRaw = raw['stats'] as Map<String, dynamic>?;
    if (startedAtMs == null || statsRaw == null) return null;
    return ActiveTripSnapshot(
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs),
      wasPaused: (raw['wasPaused'] as bool?) ?? false,
      stats: _statsFromMap(statsRaw),
    );
  }
}

Map<String, dynamic> _statsToMap(LiveTripStats s) => {
  'currentSpeedKmh': s.currentSpeedKmh,
  'maxSpeedKmh': s.maxSpeedKmh,
  'avgSpeedKmh': s.avgSpeedKmh,
  'distanceKm': s.distanceKm,
  'durationSeconds': s.durationSeconds,
  'maxGforce': s.maxGforce,
  'hardCornersCount': s.hardCornersCount,
  'hardBrakesCount': s.hardBrakesCount,
  'lastPoint': s.lastPoint == null ? null : _pointToMap(s.lastPoint!),
  'points': [for (final p in s.points) _pointToMap(p)],
};

LiveTripStats _statsFromMap(Map<String, dynamic> m) {
  final lastPointRaw = m['lastPoint'];
  final pointsRaw = (m['points'] as List?) ?? const <dynamic>[];
  return LiveTripStats(
    currentSpeedKmh: (m['currentSpeedKmh'] as num?)?.toDouble() ?? 0,
    maxSpeedKmh: (m['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
    avgSpeedKmh: (m['avgSpeedKmh'] as num?)?.toDouble() ?? 0,
    distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0,
    durationSeconds: (m['durationSeconds'] as num?)?.toInt() ?? 0,
    maxGforce: (m['maxGforce'] as num?)?.toDouble() ?? 0,
    hardCornersCount: (m['hardCornersCount'] as num?)?.toInt() ?? 0,
    hardBrakesCount: (m['hardBrakesCount'] as num?)?.toInt() ?? 0,
    lastPoint: lastPointRaw is Map<String, dynamic>
        ? _pointFromMap(lastPointRaw)
        : null,
    points: [
      for (final raw in pointsRaw)
        if (raw is Map<String, dynamic>) _pointFromMap(raw),
    ],
  );
}

Map<String, dynamic> _pointToMap(TripPoint p) => {
  'lat': p.lat,
  'lng': p.lng,
  'speedKmh': p.speedKmh,
  'accuracyMeters': p.accuracyMeters,
  'ts': p.timestamp.millisecondsSinceEpoch,
};

TripPoint _pointFromMap(Map<String, dynamic> m) => TripPoint(
  lat: (m['lat'] as num).toDouble(),
  lng: (m['lng'] as num).toDouble(),
  speedKmh: (m['speedKmh'] as num).toDouble(),
  accuracyMeters: (m['accuracyMeters'] as num).toDouble(),
  timestamp: DateTime.fromMillisecondsSinceEpoch(m['ts'] as int),
);

/// Persists the in-progress trip to a single JSON file in the app's
/// documents directory. The bloc writes on every state change so a
/// process kill / phone reboot / app force-stop never loses more than
/// the most recent unflushed update.
///
/// File is removed when the trip ends normally (saved to Drift); a
/// lingering file means a previous session was interrupted and the
/// bloc should restore it on the next launch.
@lazySingleton
class ActiveTripStore {
  ActiveTripStore();

  static const _fileName = 'live_trip.json';

  // Single in-flight write — every save() coalesces with any prior
  // pending write so we don't pile up futures on fast tick rates.
  Future<void>? _pendingWrite;
  ActiveTripSnapshot? _queued;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Write the snapshot to disk. Multiple rapid calls coalesce — the
  /// most recent snapshot wins.
  Future<void> save(ActiveTripSnapshot snapshot) {
    _queued = snapshot;
    if (_pendingWrite != null) return _pendingWrite!;
    _pendingWrite = _drainQueue();
    return _pendingWrite!;
  }

  Future<void> _drainQueue() async {
    try {
      while (_queued != null) {
        final next = _queued!;
        _queued = null;
        try {
          final file = await _file();
          await file.writeAsString(jsonEncode(next.toMap()), flush: false);
        } catch (e) {
          if (kDebugMode) debugPrint('[ActiveTripStore] save failed: $e');
        }
      }
    } finally {
      _pendingWrite = null;
    }
  }

  /// Read the persisted snapshot, or null if the file doesn't exist /
  /// is corrupt.
  Future<ActiveTripSnapshot?> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      final raw = await file.readAsString();
      if (raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return ActiveTripSnapshot.fromMap(json);
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveTripStore] load failed: $e');
      return null;
    }
  }

  /// Delete the snapshot file — call after the trip is persisted to
  /// Drift or explicitly discarded.
  Future<void> clear() async {
    _queued = null;
    try {
      final file = await _file();
      if (file.existsSync()) await file.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[ActiveTripStore] clear failed: $e');
    }
  }
}
