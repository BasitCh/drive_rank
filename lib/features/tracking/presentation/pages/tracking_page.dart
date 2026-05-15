import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:drive_rank/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:drive_rank/features/tracking/presentation/widgets/live_badge.dart';
import 'package:drive_rank/features/tracking/presentation/widgets/mini_stat.dart';
import 'package:drive_rank/features/tracking/presentation/widgets/route_strip.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen live tracking page.
///
/// Header: brand wordmark + LIVE badge + avatar.
/// Hero: big BebasNeue speed number with teal radial glow + unit label.
/// Stats: 2 rows of 3 mini-stats (max, g-force, distance / duration, avg,
///        fuel cost).
/// Map: themed route strip with the current polyline.
/// End trip: red pill button.
class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrackingBloc>(
      create: (_) =>
          getIt<TrackingBloc>()..add(const TrackingStarted()),
      child: const _TrackingPageBody(),
    );
  }
}

class _TrackingPageBody extends StatelessWidget {
  const _TrackingPageBody();

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<TrackingBloc, TrackingState>(
          builder: (context, state) {
            return switch (state.phase) {
              TrackingPhase.permissionRequired ||
              TrackingPhase.servicesDisabled => _PermissionGate(state: state),
              _ => _LiveBody(state: state, locale: locale),
            };
          },
        ),
      ),
    );
  }
}

class _LiveBody extends StatelessWidget {
  const _LiveBody({required this.state, required this.locale});

  final TrackingState state;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final isWaiting = state.phase == TrackingPhase.waitingForFix;

    return StreamBuilder(
      stream: getIt<UserSettingsRepository>().watch(),
      builder: (context, snap) {
        final theme = snap.hasData
            ? MapTheme.fromId(snap.data!.selectedMapTheme)
            : MapTheme.regular;

        return Column(
          children: [
            _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 180,
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
                  Column(
                    children: [
                      Text(
                        isWaiting
                            ? '--'
                            : locale.formatSpeedValue(stats.currentSpeedKmh),
                        style: AppTextStyles.speedDisplay,
                      ),
                      const SizedBox(height: 0),
                      Text(
                        isWaiting
                            ? AppStrings.trackingWaitingForGps
                            : '${locale.speedUnitLabel.toUpperCase()}'
                                  '${AppStrings.trackingCurrentSpeedSuffix}',
                        style: AppTextStyles.speedUnit.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                        const SizedBox(width: 6),
                        Expanded(
                          child: MiniStat(
                            value:
                                '${stats.maxGforce.toStringAsFixed(1)}g',
                            label: AppStrings.trackingGForce,
                            valueColor: AppColors.orange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: MiniStat(
                            value: locale.formatDistance(
                              stats.distanceKm,
                              fractionDigits: 1,
                            ),
                            label: AppStrings.trackingDistance,
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
                      const SizedBox(width: 6),
                      Expanded(
                        child: MiniStat(
                          value: locale.formatSpeedValue(stats.avgSpeedKmh),
                          label:
                              '${AppStrings.trackingAvgSpeed} '
                              '${locale.speedUnitLabel}',
                        ),
                      ),
                      const SizedBox(width: 6),
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
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _EndTripButton(
                onPressed: () => context
                    .read<TrackingBloc>()
                    .add(const TrackingStopRequested()),
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
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
              const LiveBadge(),
              const SizedBox(width: 7),
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

class _EndTripButton extends StatelessWidget {
  const _EndTripButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: Material(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onPressed,
          child: const Row(
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
    );
  }
}

class _PermissionGate extends StatelessWidget {
  const _PermissionGate({required this.state});

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    final isServicesOff = state.phase == TrackingPhase.servicesDisabled;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            ElevatedButton(
              onPressed: () => context
                  .read<TrackingBloc>()
                  .add(const TrackingPermissionRequested()),
              child: Text(
                isServicesOff
                    ? AppStrings.trackingOpenSettings
                    : AppStrings.trackingGrantPermission,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
