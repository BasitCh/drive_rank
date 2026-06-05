import 'package:drive_rank/features/onboarding/domain/entities/car_make.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';

/// Source of vehicle make/model data.
///
/// V1 reads from the bundled `assets/data/{car,motorbike}_makes.json`.
/// Later, a remote implementation (Firestore) can override the local list —
/// the UI doesn't need to change.
// ignore: one_member_abstracts
abstract class CarRepository {
  /// All makes for [vehicleType], sorted so the user's locally-popular
  /// makes come first. When the picker is on the car step this returns
  /// cars; when the user has switched to motorbike it returns motorbikes.
  Future<List<CarMake>> getMakes({
    required String countryCode,
    required VehicleType vehicleType,
  });
}
