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
