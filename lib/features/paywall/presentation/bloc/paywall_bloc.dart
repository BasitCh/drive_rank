import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/paywall_service.dart';
import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/features/paywall/domain/entities/paywall_offering.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@immutable
sealed class PaywallEvent {
  const PaywallEvent();
}

class PaywallStarted extends PaywallEvent {
  const PaywallStarted();
}

class PaywallPackageSelected extends PaywallEvent {
  const PaywallPackageSelected(this.period);
  final PaywallPeriod period;
}

class PaywallFeatureScrolled extends PaywallEvent {
  const PaywallFeatureScrolled(this.index);
  final int index;
}

class PaywallPurchaseRequested extends PaywallEvent {
  const PaywallPurchaseRequested();
}

class PaywallRestoreRequested extends PaywallEvent {
  const PaywallRestoreRequested();
}

enum PaywallStatus { loading, ready, purchasing, success, error }

@immutable
class PaywallSnapshot {
  const PaywallSnapshot({
    required this.bestTopSpeedKmh,
    required this.freeTripsUsed,
    required this.freeTripLimit,
  });

  final double bestTopSpeedKmh;
  final int freeTripsUsed;
  final int freeTripLimit;
}

@immutable
class PaywallState {
  const PaywallState({
    required this.status,
    required this.offering,
    required this.selected,
    required this.featureIndex,
    required this.snapshot,
    required this.errorMessage,
  });

  factory PaywallState.initial() => const PaywallState(
    status: PaywallStatus.loading,
    offering: null,
    selected: PaywallPeriod.annual,
    featureIndex: 0,
    snapshot: null,
    errorMessage: null,
  );

  final PaywallStatus status;
  final PaywallOffering? offering;
  final PaywallPeriod selected;
  final int featureIndex;
  final PaywallSnapshot? snapshot;
  final String? errorMessage;

  PaywallPackage? get selectedPackage {
    final o = offering;
    if (o == null) return null;
    return selected == PaywallPeriod.annual ? o.annual : o.monthly;
  }

  PaywallState copyWith({
    PaywallStatus? status,
    PaywallOffering? offering,
    PaywallPeriod? selected,
    int? featureIndex,
    PaywallSnapshot? snapshot,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaywallState(
      status: status ?? this.status,
      offering: offering ?? this.offering,
      selected: selected ?? this.selected,
      featureIndex: featureIndex ?? this.featureIndex,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@injectable
class PaywallBloc extends Bloc<PaywallEvent, PaywallState> {
  PaywallBloc(this._paywall, this._settings, this._trips, this._telemetry)
    : super(PaywallState.initial()) {
    on<PaywallStarted>(_onStarted);
    on<PaywallPackageSelected>(_onSelected);
    on<PaywallFeatureScrolled>(_onScroll);
    on<PaywallPurchaseRequested>(_onPurchase);
    on<PaywallRestoreRequested>(_onRestore);
  }

  final PaywallService _paywall;
  final UserSettingsRepository _settings;
  final TripRepository _trips;
  final TelemetryService _telemetry;

  Future<void> _onStarted(
    PaywallStarted event,
    Emitter<PaywallState> emit,
  ) async {
    final offering = await _paywall.loadOffering();
    final settings = await _settings.read();
    final best = await _trips.getPersonalBest(uid: settings.uid);
    emit(
      state.copyWith(
        status: offering == null
            ? PaywallStatus.error
            : PaywallStatus.ready,
        offering: offering,
        snapshot: PaywallSnapshot(
          bestTopSpeedKmh: best?.topSpeedKmh ?? 0,
          freeTripsUsed: settings.freeTripsUsed,
          freeTripLimit: _freeTripLimit(settings),
        ),
      ),
    );
    await _telemetry.track(TelemetryEvents.paywallViewed);
  }

  void _onSelected(
    PaywallPackageSelected event,
    Emitter<PaywallState> emit,
  ) {
    emit(state.copyWith(selected: event.period));
  }

  void _onScroll(
    PaywallFeatureScrolled event,
    Emitter<PaywallState> emit,
  ) {
    emit(state.copyWith(featureIndex: event.index));
  }

  Future<void> _onPurchase(
    PaywallPurchaseRequested event,
    Emitter<PaywallState> emit,
  ) async {
    final pkg = state.selectedPackage;
    if (pkg == null) return;
    emit(state.copyWith(status: PaywallStatus.purchasing, clearError: true));

    final sku = pkg.id;
    await _telemetry.track(
      TelemetryEvents.paywallPurchaseStarted,
      properties: <String, Object?>{'sku': sku},
    );
    final result = await _paywall.purchase(pkg);
    switch (result) {
      case PurchaseResult.granted:
        await _settings.patch(_proGrantedPatch());
        await _telemetry.track(
          TelemetryEvents.paywallPurchaseSucceeded,
          properties: <String, Object?>{'sku': sku},
        );
        emit(state.copyWith(status: PaywallStatus.success));
      case PurchaseResult.cancelled:
        await _telemetry.track(
          TelemetryEvents.paywallPurchaseFailed,
          properties: <String, Object?>{'sku': sku, 'result': 'cancelled'},
        );
        emit(state.copyWith(status: PaywallStatus.ready));
      case PurchaseResult.failed:
        await _telemetry.track(
          TelemetryEvents.paywallPurchaseFailed,
          properties: <String, Object?>{'sku': sku, 'result': 'failed'},
        );
        emit(
          state.copyWith(
            status: PaywallStatus.error,
            errorMessage: 'Purchase failed — please try again.',
          ),
        );
    }
  }

  Future<void> _onRestore(
    PaywallRestoreRequested event,
    Emitter<PaywallState> emit,
  ) async {
    final restored = await _paywall.restorePurchases();
    if (restored) {
      await _settings.patch(_proGrantedPatch());
      await _telemetry.track(TelemetryEvents.paywallRestored);
      emit(state.copyWith(status: PaywallStatus.success));
    }
  }

  // ---- helpers --------------------------------------------------------

  /// Single source of truth for the free-trip limit — declared once in
  /// AppConstants so changes there propagate to every screen that reads
  /// the limit (tracking idle counter, paywall sub-copy, etc).
  int _freeTripLimit(UserSettingsRow _) => AppConstants.freeTripLimit;

  /// Builds the companion that flips the user to Pro. Kept here so both
  /// purchase and restore paths can't diverge.
  UserSettingsCompanion _proGrantedPatch() =>
      const UserSettingsCompanion(isPro: Value(true));
}
