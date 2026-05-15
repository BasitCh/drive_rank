import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/onboarding/domain/repositories/car_repository.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// State machine for the 7-step onboarding flow.
///
/// On `OnboardingStarted` we seed defaults from the device locale and load
/// the car list sorted for the user's country. Every selection event writes
/// progressively to `UserSettings`, so a process kill mid-flow doesn't lose
/// previous answers — onboarding picks up where the user left off.
@injectable
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(this._cars, this._settings, this._locale, this._permissions)
    : super(OnboardingState.initial()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingStepNext>(_onNext);
    on<OnboardingStepBack>(_onBack);
    on<OnboardingCountrySelected>(_onCountry);
    on<OnboardingVehicleTypeSelected>(_onVehicle);
    on<OnboardingCarMakeSelected>(_onMake);
    on<OnboardingCarModelSelected>(_onModel);
    on<OnboardingMapThemeSelected>(_onMapTheme);
    on<OnboardingSafetyToggled>(_onSafety);
    on<OnboardingLocationPermissionRequested>(_onRequestPermission);
    on<OnboardingLocationPermissionResolved>(_onPermissionResolved);
  }

  final CarRepository _cars;
  final UserSettingsRepository _settings;
  final LocaleService _locale;
  final PermissionService _permissions;

  Future<void> _onStarted(
    OnboardingStarted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _settings.ensureExists();
    final row = await _settings.read();
    final detectedCountry =
        countryFromCode(row.country ?? _locale.countryCode) ??
        countryFromCode(_locale.countryCode);

    final makes = await _cars.getMakes(
      countryCode: detectedCountry?.code ?? _locale.countryCode,
    );

    emit(
      state.copyWith(
        isLoading: false,
        country: detectedCountry,
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

    if (next == OnboardingStep.done) {
      await _settings.markOnboardingComplete();
      emit(state.copyWith(step: next, completed: true));
      return;
    }
    emit(state.copyWith(step: next));
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
    final makes = await _cars.getMakes(countryCode: event.country.code);
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
    emit(state.copyWith(vehicleType: event.vehicleType));
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

  Future<void> _onMapTheme(
    OnboardingMapThemeSelected event,
    Emitter<OnboardingState> emit,
  ) async {
    await _settings.setMapTheme(event.theme);
    emit(state.copyWith(mapTheme: event.theme));
  }

  void _onSafety(
    OnboardingSafetyToggled event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(safetyAccepted: event.accepted));
  }

  Future<void> _onRequestPermission(
    OnboardingLocationPermissionRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final status = await _permissions.requestLocation();
    add(OnboardingLocationPermissionResolved(status));
  }

  void _onPermissionResolved(
    OnboardingLocationPermissionResolved event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(locationStatus: event.status));
  }
}
