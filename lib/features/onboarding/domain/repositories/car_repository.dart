import 'package:drive_rank/features/onboarding/domain/entities/car_make.dart';

/// Source of car make/model data.
///
/// V1 reads from the bundled `assets/data/car_makes.json`. Later, a remote
/// implementation (Firestore) can override the local list — the UI doesn't
/// need to change.
// ignore: one_member_abstracts
abstract class CarRepository {
  /// All makes, sorted so the user's locally-popular makes come first.
  Future<List<CarMake>> getMakes({required String countryCode});
}
