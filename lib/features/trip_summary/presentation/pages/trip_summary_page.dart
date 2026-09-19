import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/card_kind.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_bloc.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_event.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_state.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/elevation_chart.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/hero_stat_strip.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/journey_map.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/performance_chart.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/speed_breakdown_bar.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_social_bloc.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_bloc.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_event.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_state.dart';
import 'package:drive_rank/features/trip_summary/presentation/widgets/analytics_grid.dart';
import 'package:drive_rank/features/trip_summary/presentation/widgets/stat_card.dart';
import 'package:drive_rank/features/trip_summary/presentation/widgets/trip_competition_card.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Single-page trip detail: a collapsible real map (with a Play button
/// that opens the full-screen `RouteReplayPage`), hero stats, speed
/// distribution, the trip statistics grid, Speed/Elevation Over Time
/// charts, a goal nudge, and the shareable stat card — all in one
/// scroll. Replaces the old three-page split (Trip Summary /
/// Performance card / Journey card); trip/points/goals/delete/share
/// still come from `TripSummaryBloc` exactly as before, with
/// `InsightsBloc` added alongside it for the map/charts/breakdown data
/// those pages used to load independently.
class TripSummaryPage extends StatelessWidget {
  const TripSummaryPage({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TripSummaryBloc>(
          create: (_) =>
              getIt<TripSummaryBloc>()..add(TripSummaryLoaded(tripId)),
        ),
        BlocProvider<InsightsBloc>(
          create: (_) => getIt<InsightsBloc>()
            ..add(InsightsLoaded(tripId: tripId, kind: CardKind.performance)),
        ),
        // The competition side of the trip. A third bloc rather than
        // extra fields on TripSummaryBloc, for the same reason
        // InsightsBloc was added alongside it — the one-shot loader
        // stays a one-shot loader, and this feature's failures can't
        // stop the page rendering.
        BlocProvider<TripSocialBloc>(
          create: (_) => getIt<TripSocialBloc>()..add(TripSocialLoaded(tripId)),
        ),
      ],
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
      body: BlocConsumer<TripSummaryBloc, TripSummaryState>(
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

    return BlocBuilder<InsightsBloc, InsightsState>(
      builder: (context, insights) {
        final bundle = insights.bundle;
        return Stack(
          children: [
            _ScrollBody(
              trip: trip,
              state: state,
              bundle: bundle,
              locale: locale,
            ),
            _HiddenExportLayer(
              trip: trip,
              state: state,
              bundle: bundle,
              locale: locale,
            ),
          ],
        );
      },
    );
  }
}

/// The page's real, visible scroll content — split out from `_Loaded`
/// so it can sit alongside `_HiddenExportLayer` in a `Stack` without
/// nesting a second `BlocBuilder`.
class _ScrollBody extends StatelessWidget {
  const _ScrollBody({
    required this.trip,
    required this.state,
    required this.bundle,
    required this.locale,
  });

  final TripRow trip;
  final TripSummaryState state;
  final InsightsBundle? bundle;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    // Local capture so `bundle != null` narrows the type below — Dart
    // doesn't promote instance fields the way it promotes locals.
    final bundle = this.bundle;
    return CustomScrollView(
      slivers: [
        _MapSliverAppBar(
          trip: trip,
          bundle: bundle,
          locale: locale,
          vehicleType: state.vehicleType,
          isSharing: state.isSharing,
          onShare: () => context.read<TripSummaryBloc>().add(
            const TripSummaryShareRequested(),
          ),
          onDelete: () => _confirmDelete(context),
        ),
        SliverSafeArea(
          top: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, AppSpacing.md, 14, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (bundle != null)
                  HeroStatStrip(
                    trip: trip,
                    locale: locale,
                    bestAchievement: bundle.bestAchievement,
                  ),
                if (bundle != null && bundle.breakdownEligible) ...[
                  const SizedBox(height: AppSpacing.md),
                  SpeedBreakdownBar(slices: bundle.breakdown, locale: locale),
                ],
                const SizedBox(height: AppSpacing.md),
                AnalyticsGrid(
                  hardCorners: trip.hardCornersCount,
                  hardBrakes: trip.hardBrakesCount,
                  durationSeconds: trip.durationSeconds,
                  fuelCostFormatted: _fuelLabel(locale, trip),
                  stoppedTimeFormatted: locale.formatDuration(
                    trip.stoppedSeconds,
                  ),
                  stopCount: trip.stopCount,
                  elevationGainFormatted: trip.elevationGainMeters != null
                      ? locale.formatElevation(trip.elevationGainMeters!)
                      : null,
                  maxElevationFormatted: trip.maxElevationMeters != null
                      ? locale.formatElevation(trip.maxElevationMeters!)
                      : null,
                  zeroToHundredFormatted: bundle?.zeroToHundredSeconds != null
                      ? '${bundle!.zeroToHundredSeconds!.toStringAsFixed(2)}s'
                      : null,
                  zeroToHundredLabel: locale.unitSystem == UnitSystem.imperial
                      ? AppStrings.tripSummaryZeroToSixty
                      : AppStrings.tripSummaryZeroToHundred,
                ),
                if (bundle != null && bundle.chartEligible) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ChartCard(
                    title: AppStrings.speedOverTimeChartTitle,
                    unitLabel: locale.speedUnitLabel,
                    child: PerformanceChart(bundle: bundle, locale: locale),
                  ),
                ],
                if (bundle != null && bundle.elevationEligible) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ChartCard(
                    title: AppStrings.elevationChartTitle,
                    unitLabel: locale.elevationUnitLabel,
                    child: ElevationChart(bundle: bundle, locale: locale),
                  ),
                ],
                const _TripCompetition(),
                if ((state.speedGoalKmh ?? 0) > 0 ||
                    (state.distanceGoalKm ?? 0) > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  _GoalNudge(state: state, locale: locale),
                ],
                const SizedBox(height: AppSpacing.md),
                _ShareableCardSection(
                  trip: trip,
                  state: state,
                  locale: locale,
                  onDelete: () => _confirmDelete(context),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
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

/// Collapsible map header — pinned back/delete/share toolbar, the
/// trip's real speed-coloured route (`JourneyMap` in preview mode, no
/// embedded replay controls), and a Play button that opens the
/// full-screen replay. Shows a plain placeholder until `InsightsBloc`
/// resolves the bundle the map needs.
class _MapSliverAppBar extends StatelessWidget {
  const _MapSliverAppBar({
    required this.trip,
    required this.bundle,
    required this.locale,
    required this.vehicleType,
    required this.isSharing,
    required this.onShare,
    required this.onDelete,
  });

  final TripRow trip;
  final InsightsBundle? bundle;
  final LocaleService locale;
  final VehicleType vehicleType;
  final bool isSharing;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final b = bundle;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 260,
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: _CircleButton(
          child: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      title: const Text(
        AppStrings.tripSummaryTitle,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _ShareCtaButton(isSharing: isSharing, onTap: onShare),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (b != null)
              JourneyMap(
                bundle: b,
                locale: locale,
                showControls: false,
                vehicleType: vehicleType,
              )
            else
              const ColoredBox(color: AppColors.bg2),
            if (b != null && b.replayEligible)
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: _PlayReplayButton(
                  onTap: () => context.push(RouteNames.tripReplayFor(trip.id)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayReplayButton extends StatelessWidget {
  const _PlayReplayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: AppColors.bg,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// Card wrapper for the Speed/Elevation Over Time charts — same title
/// row + unit suffix presentation the old standalone Performance card
/// used, now inline in the trip detail scroll.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.unitLabel,
    required this.child,
  });

  final String title;
  final String unitLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  unitLabel.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Shareable-card preview section — the existing `StatCard` (with its
/// Transparent toggle and date/location footer) surfaced as a section
/// of the detail page rather than a separate destination. Tapping
/// Share on the header bar exports exactly what's rendered here.
class _ShareableCardSection extends StatelessWidget {
  const _ShareableCardSection({
    required this.trip,
    required this.state,
    required this.locale,
    required this.onDelete,
  });

  final TripRow trip;
  final TripSummaryState state;
  final LocaleService locale;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = MapTheme.fromId(trip.mapTheme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        StatCard(
          locale: locale,
          theme: theme,
          points: state.points,
          topSpeedKmh: trip.topSpeedKmh,
          avgSpeedKmh: trip.avgSpeedKmh,
          distanceKm: trip.distanceKm,
          durationSeconds: trip.durationSeconds,
          maxGforce: trip.maxGforce,
          carTag: carTagFor(state.carLabel, isNight: trip.isNightDrive),
          weatherTag: weatherTagFor(trip),
          startedAt: trip.startedAt,
          locationName: trip.locationName,
          transparent: state.isTransparent,
        ),
        const SizedBox(height: AppSpacing.sm),
        const SizedBox(height: AppSpacing.md),
        _DeleteTripButton(onTap: onDelete),
      ],
    );
  }
}

String carTagFor(String carLabel, {required bool isNight}) {
  final emoji = isNight ? '🌙' : '🚗';
  final label = carLabel.isEmpty ? 'My Car' : carLabel;
  return '$emoji $label';
}

String? weatherTagFor(TripRow trip) {
  final temp = trip.weatherTempC;
  final cond = trip.weatherCondition;
  if (temp == null && cond == null) return null;
  final parts = <String>[
    if (temp != null) '${temp.round()}°C',
    if (cond != null) cond,
  ];
  return parts.join(' · ');
}

/// Always-painted but visually hidden duplicates of the shareable
/// stat card and the Speed Over Time chart, used only by Share.
///
/// The visible copies live inside a lazily-culled `SliverList` —
/// Flutter only *paints* sliver children within the viewport (a large
/// `cacheExtent` gets them laid out, but not painted), so
/// `RenderRepaintBoundary.toImage()` on the visible copies threw
/// `!debugNeedsPaint` the instant Share was tapped without first
/// scrolling that section fully into view. A plain `Stack` doesn't
/// cull off-screen children the way a sliver viewport does — it
/// paints every child and just clips the overflow — so duplicates
/// parked off-canvas here are always paintable, and Share works the
/// instant it's tapped regardless of scroll position.
class _HiddenExportLayer extends StatelessWidget {
  const _HiddenExportLayer({
    required this.trip,
    required this.state,
    required this.bundle,
    required this.locale,
  });

  final TripRow trip;
  final TripSummaryState state;
  final InsightsBundle? bundle;
  final LocaleService locale;

  /// A typical narrow-phone width — the same reference `StatCard`
  /// itself already designs around (see its class doc).
  static const double _exportWidth = 380;

  @override
  Widget build(BuildContext context) {
    final bundle = this.bundle;
    final bloc = context.read<TripSummaryBloc>();
    final theme = MapTheme.fromId(trip.mapTheme);
    return Positioned(
      left: -_exportWidth - 100,
      top: 0,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(
              key: bloc.cardBoundaryKey,
              child: SizedBox(
                width: _exportWidth,
                child: StatCard(
                  locale: locale,
                  theme: theme,
                  points: state.points,
                  topSpeedKmh: trip.topSpeedKmh,
                  avgSpeedKmh: trip.avgSpeedKmh,
                  distanceKm: trip.distanceKm,
                  durationSeconds: trip.durationSeconds,
                  maxGforce: trip.maxGforce,
                  carTag: carTagFor(state.carLabel, isNight: trip.isNightDrive),
                  weatherTag: weatherTagFor(trip),
                  startedAt: trip.startedAt,
                  locationName: trip.locationName,
                  transparent: state.isTransparent,
                ),
              ),
            ),
            if (bundle != null && bundle.chartEligible)
              RepaintBoundary(
                key: bloc.chartBoundaryKey,
                child: SizedBox(
                  width: _exportWidth,
                  child: _ChartCard(
                    title: AppStrings.speedOverTimeChartTitle,
                    unitLabel: locale.speedUnitLabel,
                    child: PerformanceChart(bundle: bundle, locale: locale),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-width destructive action below the shareable card, mirroring
/// the header's delete icon for anyone who's scrolled past it.
class _DeleteTripButton extends StatelessWidget {
  const _DeleteTripButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.red.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                AppStrings.tripSummaryDelete,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ),
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
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
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

/// The competition card, wired to `TripSocialBloc`.
///
/// Occupies zero height until it has something to say, so the page
/// doesn't reflow around an empty box while the social read is in
/// flight — the same `if (bundle != null)` discipline the charts use.
class _TripCompetition extends StatelessWidget {
  const _TripCompetition();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripSocialBloc, TripSocialState>(
      builder: (context, state) {
        if (state.isLoading || !state.hasContent) {
          return const SizedBox.shrink();
        }
        final locale = getIt<LocaleService>();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: TripCompetitionCard(
            rankChange: state.rankChange,
            completedTargets: state.completedTargets,
            activeTargets: state.activeTargets,
            unlockedTrophies: state.unlockedTrophies,
            isIneligible: state.isIneligible,
            formatTargetRemaining: (target) {
              if (target.challenge.metric == CompetitionMetric.consistency) {
                final days = target.remaining.ceil();
                return '$days ${days == 1 ? AppStrings.rankingsUnitDay.toLowerCase() : AppStrings.rankingsUnitDays.toLowerCase()}';
              }
              return locale.formatDistance(
                target.remaining,
                fractionDigits: target.remaining >= 10 ? 0 : 1,
              );
            },
            onViewRankings: () => context.go(RouteNames.rankings),
          ),
        );
      },
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
    final speedGoal = (state.speedGoalKmh ?? 0) > 0 ? state.speedGoalKmh : null;
    final distanceGoal = (state.distanceGoalKm ?? 0) > 0
        ? state.distanceGoalKm
        : null;
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
