import 'dart:math' as math;

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/oem_battery_advisor.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:drive_rank/features/tracking/presentation/widgets/live_badge.dart';
import 'package:drive_rank/features/tracking/presentation/widgets/oem_battery_advice_sheet.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

/// Best-effort altitude reading for the idle surface, where GPS isn't
/// streaming yet (tracking hasn't started). Reads the device's cached
/// last-known fix directly — the same source `GpsService` uses for its
/// own cold-start fix — gated behind the same reliability check so a
/// stale/inaccurate fix shows 0 rather than a misleading number.
Future<double> _lastKnownAltitudeOrZero() async {
  try {
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return 0;
    final accuracy = position.altitudeAccuracy;
    if (!accuracy.isFinite ||
        accuracy < 0 ||
        accuracy > AppConstants.maxReliableAltitudeAccuracyMeters) {
      return 0;
    }
    return position.altitude;
  } catch (_) {
    return 0;
  }
}

/// Home / live tracking page.
///
/// GPS never auto-starts. Default state is `TrackingPhase.idle` — the
/// home screen shows a Start Trip button and a "free trips remaining"
/// counter. The live tracking UI only appears once `phase == active`.
class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrackingBloc>(
      // GPS does NOT auto-start. The bloc is created in the idle state
      // and waits for an explicit TrackingStartRequested from the user.
      create: (_) => getIt<TrackingBloc>(),
      child: const _TrackingPageBody(),
    );
  }
}

class _TrackingPageBody extends StatefulWidget {
  const _TrackingPageBody();

  @override
  State<_TrackingPageBody> createState() => _TrackingPageBodyState();
}

class _TrackingPageBodyState extends State<_TrackingPageBody>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns from system Settings (e.g. after flipping
    // location on), passively re-read the OS state so the gate steps
    // aside without requiring another tap.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<TrackingBloc>().add(const TrackingPermissionRechecked());
    }
  }

  // Within-session guard so even if Drift's persisted flag write hasn't
  // landed yet (it's fire-and-forget), a second active-phase transition
  // in the same session doesn't double-show the sheet.
  bool _oemAdviceCheckedThisSession = false;

  /// Fires the [OemBatteryAdviceSheet] iff this device is on a known
  /// battery-killer OEM list AND we haven't shown the sheet before.
  /// Marks the persisted `UserSettings.oemAdviceShown` flag after a
  /// successful show so the prompt never repeats.
  Future<void> _maybeShowOemAdvice(BuildContext context) async {
    if (_oemAdviceCheckedThisSession) return;
    _oemAdviceCheckedThisSession = true;
    try {
      final settings = await getIt<UserSettingsRepository>().read();
      if (settings.oemAdviceShown) return;
      final isKiller = await getIt<OemBatteryAdvisor>().isLikelyKiller();
      if (!isKiller) return;
      if (!context.mounted) return;
      await OemBatteryAdviceSheet.show(context);
      // Mark seen regardless of which button was tapped — the user
      // chose what to do with the advice and we don't want to keep
      // nagging on every trip start.
      await getIt<UserSettingsRepository>().markOemAdviceShown();
    } catch (_) {
      // Best-effort UX hint — never block a trip on this.
    }
  }

  /// Surfaces the in-trip Prominent Disclosure modal. Returns `true` if
  /// the user tapped Continue (proceed to the system permission flow),
  /// `false` if they tapped Not now (defer). Either choice acks the
  /// disclosure in TrackingBloc — Google's policy is satisfied by the
  /// disclosure being shown, not by the user accepting.
  Future<bool?> _showLocationDisclosureSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _LocationDisclosureSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocConsumer<TrackingBloc, TrackingState>(
          listenWhen: (a, b) =>
              a.phase != b.phase || a.completedTripId != b.completedTripId,
          listener: (context, state) async {
            // First Start tap without an onboarding-acked disclosure →
            // surface the in-trip Prominent Disclosure modal. Result
            // round-trips back into the bloc; user can't reach the
            // system permission dialog until they've seen this.
            //
            // Handled FIRST so the modal opens off a fresh BuildContext
            // — none of the other branches above can have awaited yet.
            if (state.phase == TrackingPhase.needsLocationDisclosure) {
              final proceed = await _showLocationDisclosureSheet(context);
              if (!context.mounted) return;
              context.read<TrackingBloc>().add(
                TrackingDisclosureResolved(proceed: proceed ?? false),
              );
              return;
            }
            // Trip saved successfully → push summary → optionally paywall.
            if (state.phase == TrackingPhase.idle &&
                state.completedTripId != null) {
              final tripId = state.completedTripId!;
              final paywallDue = state.shouldShowPaywall;
              await context.push(RouteNames.tripSummaryFor(tripId));
              if (paywallDue && context.mounted) {
                await context.push(RouteNames.paywall);
              }
              if (context.mounted) {
                context.read<TrackingBloc>().add(const TrackingReset());
              }
            }
            // First successful entry into the active phase from this
            // device → fire the OEM battery-killer advice sheet if the
            // manufacturer is on the known-killer list and we haven't
            // shown it before. Marked persistently so it never repeats.
            if (state.phase == TrackingPhase.active && context.mounted) {
              await _maybeShowOemAdvice(context);
            }
            // Trip ended under the user's minimum length → discarded,
            // not saved. Toast instead of silently vanishing.
            if (state.phase == TrackingPhase.idle &&
                state.discardedTripDistanceKm != null &&
                context.mounted) {
              final locale = getIt<LocaleService>();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppStrings.trackingTripTooShort(
                      locale.formatDistance(state.discardedTripDistanceKm!),
                    ),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return switch (state.phase) {
              TrackingPhase.permissionDenied => _PermissionGate(state: state),
              TrackingPhase.error => _ErrorSurface(state: state),
              TrackingPhase.starting ||
              TrackingPhase.stopping => _TransientSurface(phase: state.phase),
              TrackingPhase.active ||
              TrackingPhase.paused => _ActiveSurface(state: state),
              // The modal sits on top of the idle surface so the user
              // sees the home screen behind it — no jarring blackout.
              TrackingPhase.idle ||
              TrackingPhase.needsLocationDisclosure => const _IdleSurface(),
            };
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Idle — the home screen before any trip starts.
// ---------------------------------------------------------------------------

class _IdleSurface extends StatelessWidget {
  const _IdleSurface();

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return StreamBuilder<UserSettingsRow>(
      stream: getIt<UserSettingsRepository>().watch(),
      builder: (context, snap) {
        final settings = snap.data;
        final isPro = settings?.isPro ?? false;
        final used = settings?.freeTripsUsed ?? 0;
        const limit = AppConstants.freeTripLimit;
        final remaining = (limit - used).clamp(0, limit);
        final isLast = !isPro && remaining == 1;
        final isExhausted = !isPro && remaining == 0;

        // Mirror the active-trip layout so the idle surface fills the
        // full screen the same way the live page does — same header,
        // same hero, same 6-stat grid (all placeholders), then a teal
        // Start Trip CTA where End Trip would normally sit.
        //
        // On short Android phones (small foldables, older 720p Samsungs)
        // this column overflowed and the Start Trip CTA sat below the
        // viewport, unreachable. LayoutBuilder + minHeight + Intrinsic
        // Height keeps the intended "spread to fill" look on tall
        // phones AND makes it scrollable when the content doesn't fit.
        return LayoutBuilder(
          builder: (context, viewport) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const _Header(showLiveBadge: false),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: _SpeedHero(
                          speedKmh: 0,
                          locale: locale,
                          hasFix: false,
                          idleLabel: AppStrings.homeReadyToDriveTagline,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg - 2,
                        ),
                        // Trip hasn't started — GPS isn't streaming yet, so
                        // this reads the device's last-known fix directly
                        // (same reliability gate GpsService applies) to
                        // show a real altitude instead of a dead zero.
                        child: FutureBuilder<double>(
                          future: _lastKnownAltitudeOrZero(),
                          builder: (context, snap) {
                            return _StatGrid2x3(
                              locale: locale,
                              altitudeMeters: snap.data ?? 0,
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg - 2,
                        ),
                        child: _StartTripButton(
                          isExhausted: isExhausted,
                          onTap: () => _onStart(context, isExhausted),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: _FreeTripsLabel(
                          isPro: isPro,
                          remaining: remaining,
                          total: limit,
                          isLast: isLast,
                          isExhausted: isExhausted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onStart(BuildContext context, bool isExhausted) {
    if (isExhausted) {
      context.push(RouteNames.paywall);
      return;
    }
    context.read<TrackingBloc>().add(const TrackingStartRequested());
  }
}

/// 2×3 stat grid matching the reference exactly: Avg Speed / Top Speed,
/// Distance / Altitude, Duration / Stopped. Shared between the idle
/// surface (all fields null → dashes) and the active surface (real,
/// live-updating values) so the visual jump on Start → live is zero.
class _StatGrid2x3 extends StatelessWidget {
  const _StatGrid2x3({
    required this.locale,
    this.avgSpeedKmh = 0,
    this.topSpeedKmh = 0,
    this.distanceKm = 0,
    this.altitudeMeters = 0,
    this.durationSeconds = 0,
    this.stoppedSeconds = 0,
  });

  final LocaleService locale;
  final double avgSpeedKmh;
  final double topSpeedKmh;
  final double distanceKm;
  final double altitudeMeters;
  final int durationSeconds;
  final int stoppedSeconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PlainStat(
                value: locale.formatSpeedValue(avgSpeedKmh),
                label:
                    '${AppStrings.trackingAvgSpeed} '
                    '${locale.speedUnitLabel}',
              ),
            ),
            Expanded(
              child: _PlainStat(
                value: locale.formatSpeedValue(topSpeedKmh),
                label:
                    '${AppStrings.trackingMaxSpeed} '
                    '${locale.speedUnitLabel}',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: _PlainStat(
                value: locale.formatDistance(distanceKm, fractionDigits: 2),
                label: AppStrings.trackingDistance,
              ),
            ),
            Expanded(
              child: _PlainStat(
                value: locale.formatElevation(altitudeMeters),
                label: AppStrings.trackingAltitude,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: _PlainStat(
                value: locale.formatDuration(durationSeconds),
                label: AppStrings.trackingDuration,
              ),
            ),
            Expanded(
              child: _PlainStat(
                value: locale.formatDuration(stoppedSeconds),
                label: AppStrings.tripSummaryStoppedTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A single flat label/value pair — no card chrome, matching the
/// reference exactly (plain text directly on the page background,
/// not the boxed `MiniStat` tile used elsewhere in the app).
class _PlainStat extends StatelessWidget {
  const _PlainStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// GPS-signal dots + selected-vehicle glyph, shown directly under the
/// gauge — the small pill from the reference design. Signal strength
/// is derived from the last fix's reported accuracy; all three dots
/// sit dim before the first fix or on the idle surface.
class _SignalVehicleRow extends StatelessWidget {
  const _SignalVehicleRow({
    required this.accuracyMeters,
    required this.vehicleType,
  });

  final double? accuracyMeters;
  final VehicleType vehicleType;

  int get _litDots {
    final accuracy = accuracyMeters;
    if (accuracy == null) return 0;
    if (accuracy <= 10) return 3;
    if (accuracy <= 25) return 2;
    if (accuracy <= AppConstants.maxReliableAccuracyMeters) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final lit = _litDots;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < lit ? AppColors.green : AppColors.border2,
                ),
              ),
              if (i != 2) const SizedBox(width: 6),
            ],
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: AppColors.border),
            const SizedBox(width: 12),
            Text(vehicleType.glyph, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _StartTripButton extends StatelessWidget {
  const _StartTripButton({required this.isExhausted, required this.onTap});

  final bool isExhausted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = isExhausted
        ? AppStrings.homeUpgradeToContinue
        : AppStrings.homeStartTrip;
    return SizedBox(
          width: double.infinity,
          child: Material(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isExhausted
                          ? Icons.lock_outline_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.bg,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(label, style: AppTextStyles.button),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: 100.ms)
        .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

class _FreeTripsLabel extends StatelessWidget {
  const _FreeTripsLabel({
    required this.isPro,
    required this.remaining,
    required this.total,
    required this.isLast,
    required this.isExhausted,
  });

  final bool isPro;
  final int remaining;
  final int total;
  final bool isLast;
  final bool isExhausted;

  @override
  Widget build(BuildContext context) {
    if (isPro) {
      return Text(
        AppStrings.homeProMember,
        style: AppTextStyles.tag.copyWith(color: AppColors.teal),
      );
    }
    final color = isLast || isExhausted
        ? AppColors.orange
        : AppColors.textSecondary;
    final label = isLast
        ? AppStrings.homeLastFreeTripWarning
        : AppStrings.homeFreeTripsRemaining(remaining, total);
    return Text(
      label,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySmall.copyWith(
        color: color,
        fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active — live tracking. Hero number, stat grid, route strip, End Trip.
// ---------------------------------------------------------------------------

class _ActiveSurface extends StatelessWidget {
  const _ActiveSurface({required this.state});

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return StreamBuilder<UserSettingsRow>(
      stream: getIt<UserSettingsRepository>().watch(),
      builder: (context, snap) {
        final stats = state.stats;
        final hasFix = stats.lastPoint != null;

        final isPaused = state.phase == TrackingPhase.paused;
        final showRecoveryBanner =
            state.recoveryStatus == TripRecoveryStatus.interruptedByOs;
        return Column(
          children: [
            _Header(showLiveBadge: !isPaused, showPausedBadge: isPaused),
            if (showRecoveryBanner) const _InterruptionBanner(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _SpeedHero(
                speedKmh: stats.currentSpeedKmh,
                locale: locale,
                hasFix: hasFix,
                idleLabel: isPaused
                    ? AppStrings.trackingPausedSpeedLabel
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg - 2,
              ),
              child: _StatGrid2x3(
                locale: locale,
                avgSpeedKmh: stats.avgSpeedKmh,
                topSpeedKmh: stats.maxSpeedKmh,
                distanceKm: stats.distanceKm,
                altitudeMeters: stats.lastPoint?.altitudeMeters ?? 0,
                durationSeconds: stats.durationSeconds,
                stoppedSeconds: stats.stoppedSeconds,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg - 2,
              ),
              child: _TripControls(
                isPaused: isPaused,
                onPause: () => context.read<TrackingBloc>().add(
                  const TrackingPauseRequested(),
                ),
                onResume: () => context.read<TrackingBloc>().add(
                  const TrackingResumeRequested(),
                ),
                onEnd: () => _confirmEnd(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  Future<void> _confirmEnd(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bg2,
          title: const Text(
            AppStrings.endTripConfirmTitle,
            style: AppTextStyles.headingMedium,
          ),
          content: const Text(
            AppStrings.endTripConfirmBody,
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(AppStrings.endTripConfirmKeepDriving),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(AppStrings.endTripConfirmEnd),
            ),
          ],
        );
      },
    );
    if (confirmed ?? false) {
      if (!context.mounted) return;
      context.read<TrackingBloc>().add(const TrackingStopRequested());
    }
  }
}

class _SpeedHero extends StatelessWidget {
  const _SpeedHero({
    required this.speedKmh,
    required this.locale,
    required this.hasFix,
    this.idleLabel,
  });

  final double speedKmh;
  final LocaleService locale;
  final bool hasFix;

  /// When set, replaces the "KM/H — CURRENT SPEED" subtitle. Used by
  /// the idle surface to show "READY TO DRIVE" instead — same hero
  /// shape, different copy.
  final String? idleLabel;

  @override
  Widget build(BuildContext context) {
    final isIdle = idleLabel != null;
    // We deliberately stopped surfacing a "Waiting for GPS" gate — it
    // confused users with a "broken" feeling on cold-start while the
    // hardware was still warming up. The dial now reads 0 with the
    // normal unit subtitle from the first frame; the cached-fix emit
    // in GpsService.start() drops the gap to ~50 ms anyway.
    final subtitleText = isIdle
        ? idleLabel!
        : '${locale.speedUnitLabel.toUpperCase()}'
              '${AppStrings.trackingCurrentSpeedSuffix}';

    // Now that the route-preview strip and the boxed stat tiles are
    // gone (flat text pairs take much less vertical room), there's
    // headroom for the dial to read as the page's actual centrepiece
    // instead of a shrunken placeholder.
    final diameter = (MediaQuery.sizeOf(context).width * 0.72).clamp(
      230.0,
      285.0,
    );
    final progress = (speedKmh / _GaugeTicksPainter.maxScaleKmh).clamp(
      0.0,
      1.0,
    );

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(diameter, diameter),
            painter: _GaugeTicksPainter(progress: isIdle ? 0 : progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: _SmoothedSpeedNumber(
                  speedKmh: speedKmh,
                  isIdle: isIdle,
                  hasFix: hasFix,
                  locale: locale,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitleText,
                textAlign: TextAlign.center,
                style: AppTextStyles.speedUnit.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints the circular speedometer face — a full ring of tick marks
/// with a teal progress sweep (clockwise from 12 o'clock) showing
/// current speed as a fraction of [maxScaleKmh]. Sits behind the speed
/// number/unit text painted by the caller. Purely decorative — carries
/// no tracking logic of its own, so it can't drift from the real
/// reading.
class _GaugeTicksPainter extends CustomPainter {
  _GaugeTicksPainter({required this.progress});

  /// Full-scale reading for the dial — high enough that ordinary
  /// driving (and typical highway speeds) reads comfortably within the
  /// ring rather than clustering near empty, but not so high (unlike
  /// the 300 km/h physical glitch-filter ceiling) that useful road
  /// speeds barely move the sweep.
  static const double maxScaleKmh = 200;

  /// 0..1 fraction of [maxScaleKmh] currently showing.
  final double progress;

  static const int _tickCount = 72;
  static const double _startAngle = -math.pi / 2; // 12 o'clock

  /// Unlit tick colour — a cool slate-blue rather than the near-invisible
  /// `border2`, so the ring reads as a dense, defined dial face even at
  /// zero speed instead of a sparse scatter of faint dashes.
  static const Color _unlitTick = Color(0xFF4A5568);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.width / 2;
    final faceRadius = outerRadius * 0.86;

    // Dial face — a shade darker than the surrounding page so the
    // ring reads as its own instrument rather than a flat outline.
    canvas
      ..drawCircle(center, faceRadius, Paint()..color = AppColors.bg2)
      // Crisp rim right at the face boundary, framing the tick ring.
      ..drawCircle(
        center,
        faceRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _unlitTick.withValues(alpha: 0.6),
      );

    final tickOuter = outerRadius * 0.98;
    final tickInner = faceRadius;
    final progressAngle = progress * 2 * math.pi;

    for (var i = 0; i < _tickCount; i++) {
      final angle = _startAngle + (i / _tickCount) * 2 * math.pi;
      final lit = (angle - _startAngle) % (2 * math.pi) <= progressAngle;
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * tickInner;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * tickOuter;
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = lit ? AppColors.teal : _unlitTick
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugeTicksPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Eases the displayed speed between successive GPS readings (~1Hz) so
/// the number sweeps like a real analogue speedometer instead of stepping.
/// Falls back to a literal '0' for the idle and pre-fix states — we no
/// longer surface the legacy '--' placeholder because it implied the
/// app was broken while GPS was warming up.
class _SmoothedSpeedNumber extends StatelessWidget {
  const _SmoothedSpeedNumber({
    required this.speedKmh,
    required this.isIdle,
    required this.hasFix,
    required this.locale,
  });

  final double speedKmh;
  final bool isIdle;
  final bool hasFix;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    if (isIdle || !hasFix) {
      return const Text('0', style: AppTextStyles.speedDisplay);
    }
    return TweenAnimationBuilder<double>(
      // TweenAnimationBuilder remembers the previous `end` and tweens
      // from it to the new one — driving the smooth sweep on every
      // reading. Shortened from 220ms → 100ms so the dial catches up
      // to a fast-changing GPS reading well before the next sample
      // lands, trading a little sweep smoothness for responsiveness.
      tween: Tween<double>(end: speedKmh),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) {
        return Text(
          locale.formatSpeedValue(value),
          style: AppTextStyles.speedDisplay,
        );
      },
    );
  }
}

/// Pause / Resume / End controls. Pause and Resume are mutually exclusive
/// (switched on `isPaused`); End is always visible. Both share the rounded-
/// pill shape with End in red and the toggle in card grey so destructive
/// vs reversible actions are visually distinct.
class _TripControls extends StatelessWidget {
  const _TripControls({
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
  });

  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            color: AppColors.card2,
            icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            label: isPaused
                ? AppStrings.trackingResume
                : AppStrings.trackingPause,
            onPressed: isPaused ? onResume : onPause,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PillButton(
            color: AppColors.red,
            icon: Icons.stop_rounded,
            label: AppStrings.trackingEndTrip,
            onPressed: onEnd,
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedBadge extends StatelessWidget {
  const _PausedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: const Text(
        AppStrings.trackingPausedBadge,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.orange,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header (idle / live both use this; live mode adds the pulse badge).
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.showLiveBadge, this.showPausedBadge = false});

  final bool showLiveBadge;
  final bool showPausedBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg + 2,
        AppSpacing.sm,
        AppSpacing.lg + 2,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(AppStrings.appName, style: AppTextStyles.brandLogo),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLiveBadge) ...[
                const LiveBadge(),
                const SizedBox(width: 7),
              ],
              if (showPausedBadge) ...[
                const _PausedBadge(),
                const SizedBox(width: 7),
              ],

              // Container(
              //   width: 28,
              //   height: 28,
              //   decoration: const BoxDecoration(
              //     shape: BoxShape.circle,
              //     gradient: LinearGradient(
              //       colors: [AppColors.teal, AppColors.blue],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //   ),
              //   alignment: Alignment.center,
              //   child: const Text(
              //     'BA',
              //     style: TextStyle(
              //       fontFamily: 'Outfit',
              //       fontSize: 10,
              //       fontWeight: FontWeight.w700,
              //       color: AppColors.bg,
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission gate / error / transient surfaces.
// ---------------------------------------------------------------------------

class _PermissionGate extends StatelessWidget {
  const _PermissionGate({required this.state});

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    final isServicesOff =
        state.permissionStatus == LocationPermissionStatus.servicesDisabled;
    final isPermDeniedForever =
        state.permissionStatus == LocationPermissionStatus.deniedForever;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.teal,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.trackingPermissionDenied,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _onTap(
                context,
                isServicesOff: isServicesOff,
                isPermDeniedForever: isPermDeniedForever,
              ),
              child: Text(
                isServicesOff
                    ? AppStrings.trackingOpenSettings
                    : AppStrings.trackingGrantPermission,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// Routes the gate's tap to the right system surface:
  /// - Services off → system Location Settings (so the user can flip
  ///   the GPS toggle). Just re-prompting permission would do nothing;
  ///   the OS keeps returning `servicesDisabled` until the toggle is on.
  /// - Denied forever → App Settings (the OS won't accept any more
  ///   in-app prompts; only Settings can lift this state).
  /// - Otherwise → re-fire the in-app permission prompt.
  Future<void> _onTap(
    BuildContext context, {
    required bool isServicesOff,
    required bool isPermDeniedForever,
  }) async {
    if (isServicesOff) {
      await getIt<PermissionService>().openLocationSettings();
      return;
    }
    if (isPermDeniedForever) {
      await getIt<PermissionService>().openSettings();
      return;
    }
    if (!context.mounted) return;
    context.read<TrackingBloc>().add(const TrackingPermissionRequested());
  }
}

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface({required this.state});

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.red,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            state.errorMessage ?? AppStrings.errorUnknown,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<TrackingBloc>().add(
                const TrackingStartRequested(),
              ),
              child: const Text(AppStrings.homeRetry),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _TransientSurface extends StatelessWidget {
  const _TransientSurface({required this.phase});

  final TrackingPhase phase;

  @override
  Widget build(BuildContext context) {
    final label = phase == TrackingPhase.starting
        ? AppStrings.homeStartingTrip
        : AppStrings.homeStoppingTrip;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.teal),
          const SizedBox(height: AppSpacing.lg),
          Text(label, style: AppTextStyles.tag),
        ],
      ),
    );
  }
}

/// Recovery banner shown above the speed hero when the bloc restored a
/// trip whose previous session was killed by the OS / a process crash.
///
/// Explains what happened (we're not the bad guys, your phone's
/// battery manager is) and points the user at the existing Resume / End
/// controls in the bottom button row.
class _InterruptionBanner extends StatelessWidget {
  const _InterruptionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.35),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 18),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tracking was interrupted',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your phone closed DriveRank in the background — your '
                  'trip so far is safe. Tap Resume to keep recording, or '
                  'End to save what you have.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background-location Prominent Disclosure modal — Google Play policy.
// ---------------------------------------------------------------------------

/// Bottom sheet shown the first time a user taps Start without having
/// gone through the onboarding location step. Mirrors the disclosure
/// copy from `OnboardingLocationStep` so the user sees consistent text
/// regardless of which surface fires.
///
/// Returns `true` via Navigator.pop when Continue is tapped, `false` on
/// Not now. Caller dispatches `TrackingDisclosureResolved` with the
/// result; the bloc persists the acked flag in both cases.
class _LocationDisclosureSheet extends StatelessWidget {
  const _LocationDisclosureSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(child: Text('📍', style: TextStyle(fontSize: 30))),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              AppStrings.locationDisclosureTitle,
              style: AppTextStyles.headingLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              AppStrings.locationDisclosureSub,
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),
          const _SheetItem(
            emoji: '🛣',
            text: AppStrings.locationDisclosureItem1,
          ),
          const _SheetItem(
            emoji: '🔋',
            text: AppStrings.locationDisclosureItem2,
          ),
          const _SheetItem(
            emoji: '🔒',
            text: AppStrings.locationDisclosureItem3,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.locationDisclosureRevoke,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                AppStrings.locationDisclosureCta,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              AppStrings.locationDisclosureSkip,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  const _SheetItem({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
