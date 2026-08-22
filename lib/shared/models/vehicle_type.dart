import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:flutter/material.dart' show IconData, Icons;

enum VehicleType {
  car,
  motorbike;

  String get id => name;

  String get label => switch (this) {
    VehicleType.car => AppStrings.vehicleCar,
    VehicleType.motorbike => AppStrings.vehicleMotorbike,
  };

  IconData get icon => switch (this) {
    VehicleType.car => Icons.directions_car_filled_rounded,
    VehicleType.motorbike => Icons.motorcycle_rounded,
  };

  static VehicleType fromId(String id) =>
      VehicleType.values.firstWhere((t) => t.id == id, orElse: () => car);
}
