import 'package:drive_rank/core/constants/app_strings.dart';

enum VehicleType {
  car,
  motorbike;

  String get id => name;

  String get label => switch (this) {
    VehicleType.car => AppStrings.vehicleCar,
    VehicleType.motorbike => AppStrings.vehicleMotorbike,
  };

  String get glyph => switch (this) {
    VehicleType.car => '🚗',
    VehicleType.motorbike => '🏍️',
  };

  static VehicleType fromId(String id) =>
      VehicleType.values.firstWhere((t) => t.id == id, orElse: () => car);
}
