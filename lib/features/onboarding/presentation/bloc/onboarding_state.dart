import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/onboarding/domain/entities/car_make.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:flutter/foundation.dart';

/// Possible states of the live username availability check.
enum UsernameCheckStatus {
  idle,
  tooShort,
  invalidFormat,
  checking,
  available,
  taken,
  error,
}

/// Discrete steps in the onboarding flow. Order drives the progress bar.
///
/// The car-photo step (added in Issue 5) sits between car-pick and the
/// community screen — once the user has picked make + model we offer
/// them the chance to attach an actual car photo before the social
/// proof and the rest of the flow.
enum OnboardingStep {
  splash, // not in the progress bar
  countryAndVehicle,
  car,
  username,
  carPhoto,
  community,
  mapTheme,
  reviews,
  safety,
  locationPermission,
  done;

  /// Progress bar fill ratio (0..1) — splash and done are excluded from
  /// the progress chrome.
  double get progress => switch (this) {
    splash || done => 0,
    countryAndVehicle => 0.11,
    car => 0.22,
    username => 0.33,
    carPhoto => 0.44,
    community => 0.55,
    mapTheme => 0.66,
    reviews => 0.77,
    safety => 0.88,
    locationPermission => 0.95,
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
    required this.carPhotoPath,
    required this.username,
    required this.usernameStatus,
    required this.availableMakes,
    required this.mapTheme,
    required this.safetyAccepted,
    required this.locationStatus,
    required this.completed,
    required this.completionError,
  });

  factory OnboardingState.initial() => const OnboardingState(
    step: OnboardingStep.splash,
    isLoading: false,
    country: null,
    vehicleType: VehicleType.car,
    carMake: null,
    carModel: null,
    carPhotoPath: null,
    username: '',
    usernameStatus: UsernameCheckStatus.idle,
    availableMakes: <CarMake>[],
    mapTheme: MapTheme.regular,
    safetyAccepted: false,
    locationStatus: null,
    completed: false,
    completionError: null,
  );

  final OnboardingStep step;
  final bool isLoading;

  // Accumulated answers.
  final Country? country;
  final VehicleType vehicleType;
  final CarMake? carMake;
  final String? carModel;

  /// Absolute filesystem path to the user's uploaded car photo. Null
  /// until the user picks one in the car-photo onboarding step — the
  /// step is optional (Skip is always allowed).
  final String? carPhotoPath;

  /// Current candidate username (as typed — not normalised).
  final String username;

  /// Outcome of the live availability check against Firestore (or the
  /// preview repo). Drives the inline suffix icon + helper text.
  final UsernameCheckStatus usernameStatus;

  final List<CarMake> availableMakes;
  final MapTheme mapTheme;
  final bool safetyAccepted;
  final LocationPermissionStatus? locationStatus;
  final bool completed;

  /// Set when the atomic username reservation fails on safety-step
  /// submit (race condition or network error). The safety page reads
  /// it to surface an inline retry message and the user is sent back
  /// to the username step.
  final String? completionError;

  /// Returns true if the current step's primary CTA should be enabled.
  bool get canAdvance => switch (step) {
    OnboardingStep.splash => true,
    OnboardingStep.countryAndVehicle => country != null,
    OnboardingStep.car => carMake != null && carModel != null,
    OnboardingStep.username => usernameStatus == UsernameCheckStatus.available,
    OnboardingStep.carPhoto => true, // Skip is always valid.
    OnboardingStep.community => true,
    OnboardingStep.mapTheme => true,
    OnboardingStep.reviews => true,
    OnboardingStep.safety => safetyAccepted,
    // Disclosure step always advances — both Continue (request perm)
    // and Skip (defer until first trip start) are valid exits.
    OnboardingStep.locationPermission => true,
    OnboardingStep.done => false,
  };

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? isLoading,
    Country? country,
    VehicleType? vehicleType,
    CarMake? carMake,
    bool clearCarMake = false,
    String? carModel,
    bool clearCarModel = false,
    String? carPhotoPath,
    bool clearCarPhotoPath = false,
    String? username,
    UsernameCheckStatus? usernameStatus,
    List<CarMake>? availableMakes,
    MapTheme? mapTheme,
    bool? safetyAccepted,
    LocationPermissionStatus? locationStatus,
    bool clearLocationStatus = false,
    bool? completed,
    String? completionError,
    bool clearCompletionError = false,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      country: country ?? this.country,
      vehicleType: vehicleType ?? this.vehicleType,
      carMake: clearCarMake ? null : (carMake ?? this.carMake),
      carModel: clearCarModel ? null : (carModel ?? this.carModel),
      carPhotoPath: clearCarPhotoPath
          ? null
          : (carPhotoPath ?? this.carPhotoPath),
      username: username ?? this.username,
      usernameStatus: usernameStatus ?? this.usernameStatus,
      availableMakes: availableMakes ?? this.availableMakes,
      mapTheme: mapTheme ?? this.mapTheme,
      safetyAccepted: safetyAccepted ?? this.safetyAccepted,
      locationStatus: clearLocationStatus
          ? null
          : (locationStatus ?? this.locationStatus),
      completed: completed ?? this.completed,
      completionError: clearCompletionError
          ? null
          : (completionError ?? this.completionError),
    );
  }
}
