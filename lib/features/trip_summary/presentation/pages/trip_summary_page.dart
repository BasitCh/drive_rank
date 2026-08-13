import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_bloc.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_event.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_state.dart';
import 'package:drive_rank/features/trip_summary/presentation/widgets/analytics_grid.dart';
import 'package:drive_rank/features/trip_summary/presentation/widgets/stat_card.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TripSummaryPage extends StatelessWidget {
  const TripSummaryPage({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripSummaryBloc>(
      create: (_) => getIt<TripSummaryBloc>()..add(TripSummaryLoaded(tripId)),
      child: const _TripSummaryBody(),
    );
  }
}

class _TripSummaryBody extends StatelessWidget {
  const _TripSummaryBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocConsumer<TripSummaryBloc, TripSummaryState>(
          listenWhen: (a, b) => a.status != b.status,
          listener: (context, state) {
            if (state.status == TripSummaryStatus.deleted) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/history');
              }
            }
          },
          builder: (context, state) {
            return switch (state.status) {
              TripSummaryStatus.loading => const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              ),
              TripSummaryStatus.notFound => const _NotFound(),
              TripSummaryStatus.error => const _NotFound(),
              TripSummaryStatus.deleted => const SizedBox.shrink(),
              TripSummaryStatus.ready => _Loaded(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final TripSummaryState state;

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    final trip = state.trip!;
    final theme = MapTheme.fromId(trip.mapTheme);

    return Column(
      children: [
        _Header(
          isSharing: state.isSharing,
          onShare: () => context.read<TripSummaryBloc>().add(
            const TripSummaryShareRequested(),
          ),
          onDelete: () => _confirmDelete(context),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(
                  key: context.read<TripSummaryBloc>().cardBoundaryKey,
                  child: StatCard(
                    locale: locale,
                    theme: theme,
                    points: state.points,
                    topSpeedKmh: trip.topSpeedKmh,
                    avgSpeedKmh: trip.avgSpeedKmh,
                    distanceKm: trip.distanceKm,
                    durationSeconds: trip.durationSeconds,
                    maxGforce: trip.maxGforce,
                    carTag: _carTag(state.carLabel, trip.isNightDrive),
                    weatherTag: _weatherTag(trip),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AnalyticsGrid(
                  hardCorners: trip.hardCornersCount,
                  hardBrakes: trip.hardBrakesCount,
                  durationSeconds: trip.durationSeconds,
                  fuelCostFormatted: _fuelLabel(locale, trip),
                ),
                if (state.speedGoalKmh != null ||
                    state.distanceGoalKm != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _GoalNudge(state: state, locale: locale),
                ],
                const SizedBox(height: AppSpacing.md),
                _ShareCardsRow(
                  tripId: trip.id,
                  // Performance card hides when the chart would be
                  // empty — < 20 waypoints means a flatline screenshot
                  // and we'd rather not surface the CTA at all than
                  // ship a broken share.
                  showPerformance: state.points.length >= 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _carTag(String carLabel, bool isNight) {
    final emoji = isNight ? '🌙' : '🚗';
    final label = carLabel.isEmpty ? 'My Car' : carLabel;
    return '$emoji $label';
  }

  String? _weatherTag(TripRow trip) {
    final temp = trip.weatherTempC;
    final cond = trip.weatherCondition;
    if (temp == null && cond == null) return null;
    final parts = <String>[
      if (temp != null) '${temp.round()}°C',
      if (cond != null) cond,
    ];
    return parts.join(' · ');
  }

  String _fuelLabel(LocaleService locale, TripRow trip) {
    final cost = trip.fuelCostLocal;
    final code = trip.localCurrencyCode;
    if (cost == null || code == null) {
      return AppStrings.trackingFuelNotConfigured;
    }
    return locale.formatCurrency(cost, code);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text(AppStrings.tripSummaryDelete),
        content: const Text(AppStrings.tripSummaryDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      if (!context.mounted) return;
      context.read<TripSummaryBloc>().add(const TripSummaryDeleteRequested());
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isSharing,
    required this.onShare,
    required this.onDelete,
  });

  final bool isSharing;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          _CircleButton(
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              AppStrings.tripSummaryTitle,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.tripSummaryDelete,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          _ShareCtaButton(isSharing: isSharing, onTap: onShare),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 30, height: 30, child: Center(child: child)),
      ),
    );
  }
}

class _ShareCtaButton extends StatelessWidget {
  const _ShareCtaButton({required this.isSharing, required this.onTap});

  final bool isSharing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: isSharing ? null : onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSharing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: AppColors.bg,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.bg,
                  size: 14,
                ),
              const SizedBox(width: 4),
              const Text(
                AppStrings.tripSummaryShare,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Beat this next" card — one row per active goal (speed and/or
/// distance). Shown whenever at least one goal exists; per-metric rows
/// are independently optional since a user could be mid-way between
/// achieving one goal and the other recomputing.
class _GoalNudge extends StatelessWidget {
  const _GoalNudge({required this.state, required this.locale});

  final TripSummaryState state;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final speedGoal = state.speedGoalKmh;
    final distanceGoal = state.distanceGoalKm;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.tripSummaryGoalTitle,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (speedGoal != null)
            _GoalRow(
              previousLabel: AppStrings.tripSummaryPreviousTopSpeed,
              previousValue: locale.formatSpeed(state.bestTopSpeedKmh ?? 0),
              goalValue: locale.formatSpeed(speedGoal),
            ),
          if (speedGoal != null && distanceGoal != null)
            const SizedBox(height: 12),
          if (distanceGoal != null)
            _GoalRow(
              previousLabel: AppStrings.tripSummaryPreviousDistance,
              previousValue: locale.formatDistance(state.bestDistanceKm ?? 0),
              goalValue: locale.formatDistance(distanceGoal),
            ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.previousLabel,
    required this.previousValue,
    required this.goalValue,
  });

  final String previousLabel;
  final String previousValue;
  final String goalValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                previousLabel,
                style: AppTextStyles.microLabel.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                previousValue,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.teal,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppStrings.tripSummaryGoalNextLabel,
                style: AppTextStyles.microLabel.copyWith(
                  fontSize: 10,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                goalValue,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          AppStrings.errorUnknown,
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Side-by-side CTA row under the AnalyticsGrid. Trip Summary remains
/// the lightweight share surface; each card opens its own dedicated
/// share page (one screenshot per card).
///
/// Performance card auto-hides when the chart wouldn't have anything
/// to show — < 20 waypoints means a flatline export, and we'd rather
/// not surface the CTA at all than ship a broken share.
class _ShareCardsRow extends StatelessWidget {
  const _ShareCardsRow({required this.tripId, required this.showPerformance});

  final int tripId;
  final bool showPerformance;

  @override
  Widget build(BuildContext context) {
    final journey = Expanded(
      child: _ShareCardCta(
        emoji: '🗺',
        title: AppStrings.journeyCardCta,
        subtitle: AppStrings.journeyCardCtaSub,
        onTap: () => context.push(RouteNames.journeyCardFor(tripId)),
      ),
    );
    if (!showPerformance) return Row(children: [journey]);
    return Row(
      children: [
        Expanded(
          child: _ShareCardCta(
            emoji: '📈',
            title: AppStrings.performanceCardCta,
            subtitle: AppStrings.performanceCardCtaSub,
            onTap: () => context.push(RouteNames.performanceCardFor(tripId)),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        journey,
      ],
    );
  }
}

class _ShareCardCta extends StatelessWidget {
  const _ShareCardCta({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
