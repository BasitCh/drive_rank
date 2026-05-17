import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:drive_rank/features/tracking/presentation/widgets/live_badge.dart';
import 'package:drive_rank/features/tracking/presentation/widgets/mini_stat.dart';
import 'package:drive_rank/features/tracking/presentation/widgets/route_strip.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

class _TrackingPageBody extends StatelessWidget {
  const _TrackingPageBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocConsumer<TrackingBloc, TrackingState>(
          listenWhen: (a, b) =>
              a.phase != b.phase ||
              a.completedTripId != b.completedTripId,
          listener: (context, state) async {
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
          },
          builder: (context, state) {
            return switch (state.phase) {
              TrackingPhase.permissionDenied =>
                _PermissionGate(state: state),
              TrackingPhase.error => _ErrorSurface(state: state),
              TrackingPhase.starting ||
              TrackingPhase.stopping =>
                _TransientSurface(phase: state.phase),
              TrackingPhase.active => _ActiveSurface(state: state),
              TrackingPhase.idle => const _IdleSurface(),
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

        return Column(
          children: [
            const _Header(showLiveBadge: false),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            const Icon(
                              Icons.directions_car_rounded,
                              color: AppColors.teal,
                              size: 48,
                            )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .scale(begin: const Offset(0.6, 0.6)),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              AppStrings.homeReadyToDrive,
                              style: AppTextStyles.headingLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Text(
                                AppStrings.homeReadyToDriveSub,
                                style: AppTextStyles.body,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            _StartTripButton(
                              isExhausted: isExhausted,
                              onTap: () => _onStart(context, isExhausted),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _FreeTripsLabel(
                              isPro: isPro,
                              remaining: remaining,
                              total: limit,
                              isLast: isLast,
                              isExhausted: isExhausted,
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
                Text(
                  label,
                  style: AppTextStyles.button,
                ),
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
        final theme = snap.hasData
            ? MapTheme.fromId(snap.data!.selectedMapTheme)
            : MapTheme.regular;
        final stats = state.stats;
        final hasFix = stats.lastPoint != null;

        return Column(
          children: [
            const _Header(showLiveBadge: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: _SpeedHero(
                speedKmh: stats.currentSpeedKmh,
                locale: locale,
                hasFix: hasFix,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg - 2,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: MiniStat(
                            value: locale.formatSpeedValue(stats.maxSpeedKmh),
                            label:
                                '${AppStrings.trackingMaxSpeed} '
                                '${locale.speedUnitLabel}',
                            valueColor: AppColors.teal,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Expanded(
                          child: MiniStat(
                            value: '${stats.maxGforce.toStringAsFixed(1)}g',
                            label: AppStrings.trackingGForce,
                            valueColor: AppColors.orange,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Expanded(
                          child: MiniStat(
                            value: locale.formatDistance(
                              stats.distanceKm,
                              fractionDigits: 1,
                            ),
                            label: AppStrings.trackingDistance,
                            valueColor: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: MiniStat(
                          value: locale.formatDuration(stats.durationSeconds),
                          label: AppStrings.trackingDuration,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Expanded(
                        child: MiniStat(
                          value: locale.formatSpeedValue(stats.avgSpeedKmh),
                          label:
                              '${AppStrings.trackingAvgSpeed} '
                              '${locale.speedUnitLabel}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      const Expanded(
                        child: MiniStat(
                          value: AppStrings.trackingFuelNotConfigured,
                          label: AppStrings.trackingFuelCost,
                          valueColor: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            RouteStrip(theme: theme, points: stats.points),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg - 2,
              ),
              child: _EndTripButton(
                onPressed: () => _confirmEnd(context),
              ),
            ),
            const Spacer(),
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
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.red),
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
  });

  final double speedKmh;
  final LocaleService locale;
  final bool hasFix;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 0,
          child: IgnorePointer(
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.5,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hasFix
                    ? locale.formatSpeedValue(speedKmh)
                    : '--',
                style: AppTextStyles.speedDisplay,
              ),
            ),
            Text(
              hasFix
                  ? '${locale.speedUnitLabel.toUpperCase()}'
                      '${AppStrings.trackingCurrentSpeedSuffix}'
                  : AppStrings.trackingWaitingForGps,
              style: AppTextStyles.speedUnit.copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _EndTripButton extends StatelessWidget {
  const _EndTripButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stop_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  AppStrings.trackingEndTrip,
                  style: TextStyle(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header (idle / live both use this; live mode adds the pulse badge).
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.showLiveBadge});

  final bool showLiveBadge;

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
          const Text(
            AppStrings.appName,
            style: AppTextStyles.brandLogo,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLiveBadge) ...[
                const LiveBadge(),
                const SizedBox(width: 7),
              ],
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.teal, AppColors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'BA',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bg,
                  ),
                ),
              ),
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
    final isServicesOff = state.permissionStatus ==
        LocationPermissionStatus.servicesDisabled;
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
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context
                  .read<TrackingBloc>()
                  .add(const TrackingPermissionRequested()),
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
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context
                  .read<TrackingBloc>()
                  .add(const TrackingStartRequested()),
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
