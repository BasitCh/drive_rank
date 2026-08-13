import 'dart:convert';

import 'package:drive_rank/features/onboarding/domain/entities/car_make.dart';
import 'package:drive_rank/features/onboarding/domain/repositories/car_repository.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';

/// Loads `assets/data/{car,motorbike}_makes.json` and caches each parsed
/// list per [VehicleType]. `getMakes` returns a copy sorted by local
/// popularity so callers can safely mutate it without poisoning the cache.
@LazySingleton(as: CarRepository)
class AssetCarRepository implements CarRepository {
  AssetCarRepository();

  final Map<VehicleType, List<CarMake>> _cacheByType = {};

  static const Map<VehicleType, String> _assetByType = {
    VehicleType.car: 'assets/data/car_makes.json',
    VehicleType.motorbike: 'assets/data/motorbike_makes.json',
  };

  @override
  Future<List<CarMake>> getMakes({
    required String countryCode,
    required VehicleType vehicleType,
  }) async {
    final cache = _cacheByType[vehicleType] ??= await _loadFromAsset(
      vehicleType,
    );
    final sorted = [...cache]
      ..sort((a, b) {
        final aLocal = a.isPopularIn(countryCode) ? 0 : 1;
        final bLocal = b.isPopularIn(countryCode) ? 0 : 1;
        if (aLocal != bLocal) return aLocal.compareTo(bLocal);
        return a.name.compareTo(b.name);
      });
    return sorted;
  }

  Future<List<CarMake>> _loadFromAsset(VehicleType type) async {
    final assetPath = _assetByType[type] ?? _assetByType[VehicleType.car]!;
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final makes = (json['makes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CarMake.fromJson)
        .toList();
    return makes;
  }
}
