import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/paywall_service.dart';
import 'package:drive_rank/core/services/push_service.dart';
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

/// Dispatched from the error state's Retry action — never leaves the
/// user stuck on an empty paywall with no purchasable options.
class PaywallRetryRequested extends PaywallEvent {
  const PaywallRetryRequested();
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
    for (final p in o.packages) {
      if (p.period == selected) return p;
    }
    return null;
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
  PaywallBloc(
    this._paywall,
    this._settings,
    this._trips,
    this._telemetry,
    this._push,
  ) : super(PaywallState.initial()) {
    on<PaywallStarted>(_onStarted);
    on<PaywallRetryRequested>(_onRetry);
    on<PaywallPackageSelected>(_onSelected);
    on<PaywallFeatureScrolled>(_onScroll);
    on<PaywallPurchaseRequested>(_onPurchase);
    on<PaywallRestoreRequested>(_onRestore);
  }

  final PaywallService _paywall;
  final UserSettingsRepository _settings;
  final TripRepository _trips;
  final TelemetryService _telemetry;
  final PushService _push;

  Future<void> _onStarted(
    PaywallStarted event,
    Emitter<PaywallState> emit,
  ) async {
    await _loadOfferingAndEmit(emit);
    await _telemetry.track(TelemetryEvents.paywallViewed);
  }

  /// Re-runs the same load as [_onStarted] — the retry action shown on
  /// the error state (never leave the user staring at an empty paywall
  /// with no purchasable options and no way forward).
  Future<void> _onRetry(
    PaywallRetryRequested event,
    Emitter<PaywallState> emit,
  ) async {
    emit(state.copyWith(status: PaywallStatus.loading));
    await _loadOfferingAndEmit(emit);
  }

  Future<void> _loadOfferingAndEmit(Emitter<PaywallState> emit) async {
    final offering = await _paywall.loadOffering();
    final settings = await _settings.read();
    final best = await _trips.getPersonalBest(uid: settings.uid);

    if (offering == null) {
      await _telemetry.track(TelemetryEvents.offeringsLoadFailed);
    }

    // Default to the longest-period package (annual, typically) rather
    // than hardcoding PaywallPeriod.annual — an offering that genuinely
    // has no annual package would otherwise leave `selectedPackage`
    // null and the Continue button permanently disabled.
    final sorted = [...?offering?.packages]
      ..sort(
        (a, b) => (b.period.approxMonths ?? -1).compareTo(
          a.period.approxMonths ?? -1,
        ),
      );

    emit(
      state.copyWith(
        status: offering == null ? PaywallStatus.error : PaywallStatus.ready,
        offering: offering,
        selected: sorted.isNotEmpty ? sorted.first.period : state.selected,
        snapshot: PaywallSnapshot(
          bestTopSpeedKmh: best?.topSpeedKmh ?? 0,
          freeTripsUsed: settings.freeTripsUsed,
          freeTripLimit: _freeTripLimit(settings),
        ),
      ),
    );
  }

  void _onSelected(PaywallPackageSelected event, Emitter<PaywallState> emit) {
    emit(state.copyWith(selected: event.period));
  }

  void _onScroll(PaywallFeatureScrolled event, Emitter<PaywallState> emit) {
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
    final (result, reason) = await _paywall.purchase(pkg);
    switch (result) {
      case PurchaseResult.granted:
        await _settings.patch(_proGrantedPatch());
        unawaited(_push.tag('is_pro', 'true'));
        await _telemetry.track(
          TelemetryEvents.paywallPurchaseSucceeded,
          properties: <String, Object?>{'sku': sku},
        );
        emit(state.copyWith(status: PaywallStatus.success));
      case PurchaseResult.cancelled:
        // A cancellation is an expected user choice, not a failure —
        // its own distinct event, not folded into purchase-failed.
        await _telemetry.track(
          TelemetryEvents.paywallPurchaseCancelled,
          properties: <String, Object?>{'sku': sku},
        );
        emit(state.copyWith(status: PaywallStatus.ready));
      case PurchaseResult.failed:
        await _telemetry.track(
          TelemetryEvents.paywallPurchaseFailed,
          properties: <String, Object?>{'sku': sku, 'reason': reason},
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
    emit(state.copyWith(status: PaywallStatus.purchasing, clearError: true));
    final result = await _paywall.restorePurchases();
    // Fail-open/fail-closed logic lives in one place —
    // UserSettingsRepository.applyEntitlementCheck — not re-implemented
    // here; this switch only drives this screen's own UI/telemetry.
    await _settings.applyEntitlementCheck(result);
    switch (result) {
      case ProEntitlementCheck.active:
        unawaited(_push.tag('is_pro', 'true'));
        await _telemetry.track(TelemetryEvents.paywallRestored);
        emit(state.copyWith(status: PaywallStatus.success));
      case ProEntitlementCheck.inactive:
        // A real, checked result — not an error — so it gets its own
        // message rather than the generic "purchase failed" copy.
        emit(
          state.copyWith(
            status: PaywallStatus.error,
            errorMessage: 'No previous purchase found for this account.',
          ),
        );
      case ProEntitlementCheck.unknown:
        // Transient failure — never implied to mean "no subscription."
        // Local isPro is untouched either way; this only affects what
        // the paywall itself shows.
        emit(
          state.copyWith(
            status: PaywallStatus.error,
            errorMessage:
                "Couldn't restore purchases — check your connection and "
                'try again.',
          ),
        );
    }
  }

  // ---- helpers --------------------------------------------------------

  /// Single source of truth for the free-trip limit — the allowance
  /// actually persisted on this user's row (set at creation time), not
  /// a global constant, so existing users keep whatever they were
  /// originally granted even if the default for new installs changes
  /// later. Falls back to the current default only for rows created
  /// before this column existed and somehow still null post-migration.
  int _freeTripLimit(UserSettingsRow row) =>
      row.freeTripLimit ?? AppConstants.defaultFreeTripLimit;

  /// Builds the companion that flips the user to Pro. Kept here so both
  /// purchase and restore paths can't diverge.
  UserSettingsCompanion _proGrantedPatch() =>
      const UserSettingsCompanion(isPro: Value(true));
}
