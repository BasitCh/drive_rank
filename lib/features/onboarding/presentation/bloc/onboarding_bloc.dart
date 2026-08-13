import 'dart:async';

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/core/services/push_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/features/onboarding/domain/repositories/car_repository.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// State machine for the multi-step onboarding flow.
///
/// On `OnboardingStarted` we seed defaults from the device locale and
/// load the car list sorted for the user's country. Every selection
/// event writes progressively to `UserSettings`, so a process kill
/// mid-flow doesn't lose previous answers — onboarding resumes where
/// the user left off.
///
/// MVP scope: username is local-only. Earlier versions reserved it in
/// Firestore (for the now-removed friends search). The bloc still
/// validates format synchronously so the field disables Continue
/// until the user has typed something legal.
@injectable
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(
    this._cars,
    this._settings,
    this._locale,
    this._permissions,
    this._telemetry,
    this._push,
  ) : super(OnboardingState.initial()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingStepNext>(_onNext);
    on<OnboardingStepBack>(_onBack);
    on<OnboardingCountrySelected>(_onCountry);
    on<OnboardingVehicleTypeSelected>(_onVehicle);
    on<OnboardingCarMakeSelected>(_onMake);
    on<OnboardingCarModelSelected>(_onModel);
    on<OnboardingCarPhotoSelected>(_onCarPhoto);
    on<OnboardingCarPhotoSkipped>(_onCarPhotoSkipped);
    on<OnboardingUsernameChanged>(_onUsernameChanged);
    on<OnboardingMapThemeSelected>(_onMapTheme);
    on<OnboardingSafetyToggled>(_onSafety);
    on<OnboardingLocationPermissionRequested>(_onRequestPermission);
    on<OnboardingLocationPermissionResolved>(_onPermissionResolved);
  }

  final CarRepository _cars;
  final UserSettingsRepository _settings;
  final LocaleService _locale;
  final PermissionService _permissions;
  final TelemetryService _telemetry;
  final PushService _push;

  /// Local format rules used to gate the Continue button on the
  /// username step. Mirrors what the spec calls "minimum 3 characters,
  /// letters / numbers / underscore only".
  static final RegExp _usernameAllowed = RegExp(r'^[A-Za-z0-9_]+$');
  static const int _usernameMinLength = 3;
  static const int _usernameMaxLength = 24;

  Future<void> _onStarted(
    OnboardingStarted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _telemetry.track(TelemetryEvents.onboardingStarted);
    await _settings.ensureExists();
    final row = await _settings.read();
    final detectedCountry =
        countryFromCode(row.country ?? _locale.countryCode) ??
        countryFromCode(_locale.countryCode);

    // Use the persisted vehicle type so a user returning to onboarding
    // sees motorbikes if that's what they had selected previously, not
    // the bloc's default (car).
    final persistedType = VehicleType.fromId(row.vehicleType);
    final makes = await _cars.getMakes(
      countryCode: detectedCountry?.code ?? _locale.countryCode,
      vehicleType: persistedType,
    );

    emit(
      state.copyWith(
        isLoading: false,
        country: detectedCountry,
        vehicleType: persistedType,
        availableMakes: makes,
      ),
    );
  }

  Future<void> _onNext(
    OnboardingStepNext event,
    Emitter<OnboardingState> emit,
  ) async {
    if (!state.canAdvance) return;

    // Sequence of steps in display order.
    const order = OnboardingStep.values;
    final currentIdx = order.indexOf(state.step);
    final next = currentIdx + 1 < order.length
        ? order[currentIdx + 1]
        : OnboardingStep.done;

    // MVP scope: username is local only. No Firestore reservation,
    // no race-condition handling — we just persist the trimmed value
    // when the user advances past the username step.
    if (state.step == OnboardingStep.username) {
      await _settings.setUsername(state.username.trim());
    }

    // Each Continue tap is a step-completed checkpoint — the step name
    // we report is the one the user just left, not the new one. Drives
    // the onboarding funnel chart.
    await _telemetry.track(
      TelemetryEvents.onboardingStepCompleted,
      properties: <String, Object?>{'step_name': state.step.name},
    );

    // The location-permission step persists the disclosure flag on both
    // exit paths (Continue requested it via _onRequestPermission; Skip
    // falls through here). Either way Google's policy requirement —
    // "in-app disclosure shown" — is satisfied for this install.
    if (state.step == OnboardingStep.locationPermission) {
      await _settings.markBgLocationDisclosureAcked();
    }

    if (next == OnboardingStep.done) {
      await _settings.markOnboardingComplete();
      await _telemetry.track(
        TelemetryEvents.onboardingFinished,
        properties: <String, Object?>{
          'country': state.country?.code,
          'vehicle_type': state.vehicleType.id,
          'unit_system': _locale.unitSystem == UnitSystem.imperial
              ? 'imperial'
              : 'metric',
        },
      );
      emit(state.copyWith(step: next, completed: true));
      return;
    }
    emit(state.copyWith(step: next, clearCompletionError: true));
  }

  Future<void> _onUsernameChanged(
    OnboardingUsernameChanged event,
    Emitter<OnboardingState> emit,
  ) async {
    final raw = event.value;
    final trimmed = raw.trim();

    // Synchronous local validation only — earlier versions hit
    // Firestore for uniqueness; that path is gone in MVP.
    final UsernameCheckStatus status;
    if (trimmed.length < _usernameMinLength) {
      status = UsernameCheckStatus.tooShort;
    } else if (trimmed.length > _usernameMaxLength ||
        !_usernameAllowed.hasMatch(trimmed)) {
      status = UsernameCheckStatus.invalidFormat;
    } else {
      status = UsernameCheckStatus.available;
    }
    emit(state.copyWith(username: raw, usernameStatus: status));
  }

  Future<void> _onBack(
    OnboardingStepBack event,
    Emitter<OnboardingState> emit,
  ) async {
    const order = OnboardingStep.values;
    final currentIdx = order.indexOf(state.step);
    if (currentIdx <= 0) return;
    emit(state.copyWith(step: order[currentIdx - 1]));
  }

  Future<void> _onCountry(
    OnboardingCountrySelected event,
    Emitter<OnboardingState> emit,
  ) async {
    await _settings.setCountry(event.country.code);
    unawaited(_push.tag('country', event.country.code));

    // Derive units from the picked country so a Pakistani user on an
    // English-US-locale phone gets km/h after picking Pakistan, etc.
    // We persist to Drift AND swap the registered LocaleService so the
    // UI rebuild in this same session picks up the new units — without
    // the swap, the change wouldn't show until the next launch.
    final newUnit =
        AppConstants.imperialCountryCodes.contains(event.country.code)
        ? UnitSystem.imperial
        : UnitSystem.metric;
    await _settings.setUnitSystem(newUnit);
    final swapped = getIt<LocaleService>().withOverride(newUnit);
    if (getIt.isRegistered<LocaleService>()) {
      await getIt.unregister<LocaleService>();
    }
    getIt.registerLazySingleton<LocaleService>(() => swapped);

    final makes = await _cars.getMakes(
      countryCode: event.country.code,
      vehicleType: state.vehicleType,
    );
    // If the user changes country and their previously-selected make is no
    // longer in the list (shouldn't happen — the list is global), keep the
    // make as-is; we only re-rank.
    emit(state.copyWith(country: event.country, availableMakes: makes));
  }

  Future<void> _onVehicle(
    OnboardingVehicleTypeSelected event,
    Emitter<OnboardingState> emit,
  ) async {
    await _settings.setVehicleType(event.vehicleType);
    unawaited(_push.tag('vehicle_type', event.vehicleType.id));
    // Swapping vehicle types invalidates the picker list (and any
    // previously selected make/model — a Toyota Corolla isn't a
    // motorbike). Reload makes for the new type from the country we
    // already detected, and clear the now-stale make + model so the
    // picker step is forced to re-select.
    final countryCode = state.country?.code ?? _locale.countryCode;
    final makes = await _cars.getMakes(
      countryCode: countryCode,
      vehicleType: event.vehicleType,
    );
    emit(
      state.copyWith(
        vehicleType: event.vehicleType,
        availableMakes: makes,
        clearCarMake: true,
        clearCarModel: true,
      ),
    );
  }

  Future<void> _onMake(
    OnboardingCarMakeSelected event,
    Emitter<OnboardingState> emit,
  ) async {
    // Changing the make invalidates the previously-picked model.
    emit(state.copyWith(carMake: event.make, clearCarModel: true));
  }

  Future<void> _onModel(
    OnboardingCarModelSelected event,
    Emitter<OnboardingState> emit,
  ) async {
    final make = state.carMake;
    if (make == null) return;
    await _settings.setCar(make: make.name, model: event.model);
    emit(state.copyWith(carModel: event.model));
  }

  Future<void> _onCarPhoto(
    OnboardingCarPhotoSelected event,
    Emitter<OnboardingState> emit,
  ) async {
    await _settings.setCarPhotoPath(event.path);
    emit(state.copyWith(carPhotoPath: event.path));
  }

  Future<void> _onCarPhotoSkipped(
    OnboardingCarPhotoSkipped event,
    Emitter<OnboardingState> emit,
  ) async {
    await _settings.setCarPhotoPath(null);
    emit(state.copyWith(clearCarPhotoPath: true));
  }

  Future<void> _onMapTheme(
    OnboardingMapThemeSelected event,
    Emitter<OnboardingState> emit,
  ) async {
    await _settings.setMapTheme(event.theme);
    emit(state.copyWith(mapTheme: event.theme));
  }

  void _onSafety(OnboardingSafetyToggled event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(safetyAccepted: event.accepted));
  }

  Future<void> _onRequestPermission(
    OnboardingLocationPermissionRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    // The Prominent Disclosure has now been surfaced — mark it as
    // acknowledged regardless of how the system permission dialog goes,
    // so TrackingBloc doesn't re-prompt the disclosure on first Start.
    // Google's policy is satisfied by the in-app disclosure existing,
    // not by the OS granting the permission.
    await _settings.markBgLocationDisclosureAcked();
    final status = await _permissions.requestLocation();
    add(OnboardingLocationPermissionResolved(status));
    // Auto-advance to the final step on grant — there's nothing else for
    // the user to do here. On denial we stay so the inline help banner
    // explains the consequence; the user can still tap Skip or Continue
    // again to fall through.
    if (status == LocationPermissionStatus.granted ||
        status == LocationPermissionStatus.grantedAlways) {
      add(const OnboardingStepNext());
    }
  }

  void _onPermissionResolved(
    OnboardingLocationPermissionResolved event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(locationStatus: event.status));
  }
}
