import 'dart:async';

import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/onboarding/domain/repositories/car_repository.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/repositories/username_repository.dart';
import 'package:drive_rank/shared/services/public_profile_service.dart';
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
  OnboardingBloc(
    this._cars,
    this._settings,
    this._locale,
    this._permissions,
    this._usernames,
    this._auth,
    this._publicProfile,
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
    on<OnboardingUsernameCheckResolved>(_onUsernameCheckResolved);
    on<OnboardingMapThemeSelected>(_onMapTheme);
    on<OnboardingSafetyToggled>(_onSafety);
    on<OnboardingLocationPermissionRequested>(_onRequestPermission);
    on<OnboardingLocationPermissionResolved>(_onPermissionResolved);
  }

  final CarRepository _cars;
  final UserSettingsRepository _settings;
  final LocaleService _locale;
  final PermissionService _permissions;
  final UsernameRepository _usernames;
  final AuthService _auth;
  final PublicProfileService _publicProfile;

  /// Pending availability check — cancelled on every new keystroke so
  /// the 600 ms debounce doesn't trail multiple Firestore requests.
  Timer? _usernameDebounce;

  /// Monotonic counter that lets us discard the result of a late
  /// in-flight check when the user has typed something newer.
  int _usernameSeq = 0;

  @override
  Future<void> close() {
    _usernameDebounce?.cancel();
    return super.close();
  }

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

    // Atomic username reservation runs when the user advances past the
    // username step — earliest point where we can hold the name before
    // someone else grabs it. If reservation fails (race / network),
    // bounce them back to the username step with an inline error.
    if (state.step == OnboardingStep.username) {
      final result = await _usernames.reserve(
        raw: state.username,
        uid: _auth.currentUser.uid,
      );
      if (result != UsernameReservationResult.reserved) {
        emit(
          state.copyWith(
            usernameStatus: switch (result) {
              UsernameReservationResult.raced => UsernameCheckStatus.taken,
              UsernameReservationResult.tooShort =>
                UsernameCheckStatus.tooShort,
              UsernameReservationResult.invalidFormat =>
                UsernameCheckStatus.invalidFormat,
              _ => UsernameCheckStatus.error,
            },
            completionError: _reservationFailureMessage(result),
          ),
        );
        return;
      }
      // Persist locally so the rest of the app can read it without
      // hitting Firestore. The auth UID is what trip rows key off.
      final cleanUsername = state.username.trim();
      await _settings.setUsername(cleanUsername);

      // Mirror to the public `/users/{uid}` document so the friend
      // search can find this user by usernameLower prefix. No-op when
      // Firebase isn't initialised; failures are logged and swallowed.
      final make = state.carMake;
      await _publicProfile.publish(
        PublicProfilePayload(
          uid: _auth.currentUser.uid,
          username: cleanUsername,
          carMake: make?.name ?? '',
          carModel: state.carModel ?? '',
          carYear: null,
          countryCode: state.country?.code ?? '',
        ),
      );
    }

    if (next == OnboardingStep.done) {
      await _settings.markOnboardingComplete();
      emit(state.copyWith(step: next, completed: true));
      return;
    }
    emit(state.copyWith(step: next, clearCompletionError: true));
  }

  static String? _reservationFailureMessage(UsernameReservationResult r) =>
      switch (r) {
        UsernameReservationResult.reserved => null,
        UsernameReservationResult.raced =>
          'Username was just taken. Pick another.',
        UsernameReservationResult.tooShort => 'Minimum 3 characters.',
        UsernameReservationResult.invalidFormat =>
          'Letters, numbers and underscore only.',
        UsernameReservationResult.error =>
          "Couldn't reserve username — check your connection and try again.",
      };

  Future<void> _onUsernameChanged(
    OnboardingUsernameChanged event,
    Emitter<OnboardingState> emit,
  ) async {
    final raw = event.value;
    final seq = ++_usernameSeq;

    // Synchronous validation runs immediately — no point hitting the
    // network for "ab" or "💩".
    final localCheck = UsernameRules.validate(raw);
    if (localCheck == UsernameAvailability.tooShort) {
      _usernameDebounce?.cancel();
      emit(
        state.copyWith(
          username: raw,
          usernameStatus: UsernameCheckStatus.tooShort,
        ),
      );
      return;
    }
    if (localCheck == UsernameAvailability.invalidFormat) {
      _usernameDebounce?.cancel();
      emit(
        state.copyWith(
          username: raw,
          usernameStatus: UsernameCheckStatus.invalidFormat,
        ),
      );
      return;
    }

    // Optimistically show "checking" while the debounce window runs.
    emit(
      state.copyWith(
        username: raw,
        usernameStatus: UsernameCheckStatus.checking,
      ),
    );
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 600), () async {
      final result = await _usernames.check(raw);
      // Discard if a newer keystroke superseded this check.
      if (seq != _usernameSeq) return;
      if (isClosed) return;
      // Re-emit via add() so the bloc handler runs on the event loop
      // (we're outside the original handler's scope here).
      add(OnboardingUsernameCheckResolved(
        seq,
        switch (result) {
          UsernameAvailability.available => UsernameCheckOutcome.available,
          UsernameAvailability.taken => UsernameCheckOutcome.taken,
          UsernameAvailability.tooShort => UsernameCheckOutcome.tooShort,
          UsernameAvailability.invalidFormat =>
            UsernameCheckOutcome.invalidFormat,
          UsernameAvailability.error => UsernameCheckOutcome.error,
        },
      ));
    });
  }

  void _onUsernameCheckResolved(
    OnboardingUsernameCheckResolved event,
    Emitter<OnboardingState> emit,
  ) {
    if (event.seq != _usernameSeq) return;
    final status = switch (event.status) {
      UsernameCheckOutcome.available => UsernameCheckStatus.available,
      UsernameCheckOutcome.taken => UsernameCheckStatus.taken,
      UsernameCheckOutcome.tooShort => UsernameCheckStatus.tooShort,
      UsernameCheckOutcome.invalidFormat => UsernameCheckStatus.invalidFormat,
      UsernameCheckOutcome.error => UsernameCheckStatus.error,
    };
    emit(state.copyWith(usernameStatus: status));
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
