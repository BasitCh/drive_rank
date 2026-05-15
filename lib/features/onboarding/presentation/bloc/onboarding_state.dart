import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/onboarding/domain/entities/car_make.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:flutter/foundation.dart';

/// Discrete steps in the 7-screen onboarding flow. Order matches the
/// HTML mock's progress bar (20% → 40% → 55% → 70% → 85% → 95%).
enum OnboardingStep {
  splash, // not in the progress bar
  countryAndVehicle,
  car,
  community,
  mapTheme,
  reviews,
  safety,
  done;

  /// Progress bar fill ratio (0..1) — splash and done are excluded from
  /// the progress chrome.
  double get progress => switch (this) {
    splash || done => 0,
    countryAndVehicle => 0.20,
    car => 0.40,
    community => 0.55,
    mapTheme => 0.70,
    reviews => 0.85,
    safety => 0.95,
  };

  bool get showsProgressChrome => this != splash && this != done;
}

@immutable
class OnboardingState {
  const OnboardingState({
    required this.step,
    required this.isLoading,
    required this.country,
    required this.vehicleType,
    required this.carMake,
    required this.carModel,
    required this.availableMakes,
    required this.mapTheme,
    required this.safetyAccepted,
    required this.locationStatus,
    required this.completed,
  });

  factory OnboardingState.initial() => const OnboardingState(
    step: OnboardingStep.splash,
    isLoading: false,
    country: null,
    vehicleType: VehicleType.car,
    carMake: null,
    carModel: null,
    availableMakes: <CarMake>[],
    mapTheme: MapTheme.regular,
    safetyAccepted: false,
    locationStatus: null,
    completed: false,
  );

  final OnboardingStep step;
  final bool isLoading;

  // Accumulated answers.
  final Country? country;
  final VehicleType vehicleType;
  final CarMake? carMake;
  final String? carModel;
  final List<CarMake> availableMakes;
  final MapTheme mapTheme;
  final bool safetyAccepted;
  final LocationPermissionStatus? locationStatus;
  final bool completed;

  /// Returns true if the current step's primary CTA should be enabled.
  bool get canAdvance => switch (step) {
    OnboardingStep.splash => true,
    OnboardingStep.countryAndVehicle => country != null,
    OnboardingStep.car => carMake != null && carModel != null,
    OnboardingStep.community => true,
    OnboardingStep.mapTheme => true,
    OnboardingStep.reviews => true,
    OnboardingStep.safety => safetyAccepted,
    OnboardingStep.done => false,
  };

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? isLoading,
    Country? country,
    VehicleType? vehicleType,
    CarMake? carMake,
    String? carModel,
    bool clearCarModel = false,
    List<CarMake>? availableMakes,
    MapTheme? mapTheme,
    bool? safetyAccepted,
    LocationPermissionStatus? locationStatus,
    bool clearLocationStatus = false,
    bool? completed,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      country: country ?? this.country,
      vehicleType: vehicleType ?? this.vehicleType,
      carMake: carMake ?? this.carMake,
      carModel: clearCarModel ? null : (carModel ?? this.carModel),
      availableMakes: availableMakes ?? this.availableMakes,
      mapTheme: mapTheme ?? this.mapTheme,
      safetyAccepted: safetyAccepted ?? this.safetyAccepted,
      locationStatus: clearLocationStatus
          ? null
          : (locationStatus ?? this.locationStatus),
      completed: completed ?? this.completed,
    );
  }
}
