import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/onboarding/domain/entities/car_make.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class OnboardingEvent {
  const OnboardingEvent();
}

class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
}

class OnboardingStepNext extends OnboardingEvent {
  const OnboardingStepNext();
}

class OnboardingStepBack extends OnboardingEvent {
  const OnboardingStepBack();
}

class OnboardingCountrySelected extends OnboardingEvent {
  const OnboardingCountrySelected(this.country);
  final Country country;
}

class OnboardingVehicleTypeSelected extends OnboardingEvent {
  const OnboardingVehicleTypeSelected(this.vehicleType);
  final VehicleType vehicleType;
}

class OnboardingCarMakeSelected extends OnboardingEvent {
  const OnboardingCarMakeSelected(this.make);
  final CarMake make;
}

class OnboardingCarModelSelected extends OnboardingEvent {
  const OnboardingCarModelSelected(this.model);
  final String model;
}

/// User finished picking a car photo on the photo-upload step.
/// `path` is the absolute on-device filesystem path returned by
/// image_picker. Persisted to UserSettings.carPhotoPath so the same
/// photo surfaces on the stat card and profile later.
class OnboardingCarPhotoSelected extends OnboardingEvent {
  const OnboardingCarPhotoSelected(this.path);
  final String path;
}

/// User tapped Skip on the car-photo step. Clears any pending photo
/// path back to null — the SVG silhouette is shown instead.
class OnboardingCarPhotoSkipped extends OnboardingEvent {
  const OnboardingCarPhotoSkipped();
}

/// Fired on every TextField change on the username step. The bloc
/// debounces 600 ms before calling out to Firestore, so spamming
/// the field with this event is cheap.
class OnboardingUsernameChanged extends OnboardingEvent {
  const OnboardingUsernameChanged(this.value);
  final String value;
}

/// Internal — fired by the bloc's own debounce timer when a Firestore
/// availability check finishes. Carries a monotonic sequence number so
/// a late-resolving result doesn't overwrite a newer keystroke.
class OnboardingUsernameCheckResolved extends OnboardingEvent {
  const OnboardingUsernameCheckResolved(this.seq, this.status);
  final int seq;

  /// One of the discrete UI states defined by `UsernameCheckStatus` —
  /// kept as a typed enum so the handler doesn't re-do the switch.
  final UsernameCheckOutcome status;
}

/// Outcome marshalling between `UsernameRepository.check` and the
/// bloc's internal resolver event. Mirrors `UsernameAvailability`
/// exactly but lives in the event layer so the bloc files don't leak
/// the repo type to widgets.
enum UsernameCheckOutcome {
  available,
  taken,
  tooShort,
  invalidFormat,
  error,
}

class OnboardingMapThemeSelected extends OnboardingEvent {
  const OnboardingMapThemeSelected(this.theme);
  final MapTheme theme;
}

class OnboardingSafetyToggled extends OnboardingEvent {
  const OnboardingSafetyToggled({required this.accepted});
  final bool accepted;
}

class OnboardingLocationPermissionRequested extends OnboardingEvent {
  const OnboardingLocationPermissionRequested();
}

class OnboardingLocationPermissionResolved extends OnboardingEvent {
  const OnboardingLocationPermissionResolved(this.status);
  final LocationPermissionStatus status;
}
