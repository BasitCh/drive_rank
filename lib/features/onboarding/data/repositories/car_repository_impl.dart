import 'dart:convert';

import 'package:drive_rank/features/onboarding/domain/entities/car_make.dart';
import 'package:drive_rank/features/onboarding/domain/repositories/car_repository.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';

/// Loads `assets/data/car_makes.json` once and caches the parsed list. The
/// `getMakes` call returns a copy sorted by local popularity so callers can
/// safely mutate it without poisoning the cache.
@LazySingleton(as: CarRepository)
class AssetCarRepository implements CarRepository {
  AssetCarRepository();

  List<CarMake>? _cache;

  @override
  Future<List<CarMake>> getMakes({required String countryCode}) async {
    final cache = _cache ??= await _loadFromAsset();
    final sorted = [...cache]..sort((a, b) {
      final aLocal = a.isPopularIn(countryCode) ? 0 : 1;
      final bLocal = b.isPopularIn(countryCode) ? 0 : 1;
      if (aLocal != bLocal) return aLocal.compareTo(bLocal);
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  Future<List<CarMake>> _loadFromAsset() async {
    final raw = await rootBundle.loadString('assets/data/car_makes.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final makes = (json['makes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CarMake.fromJson)
        .toList();
    return makes;
  }
}
