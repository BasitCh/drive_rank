import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
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
      create: (_) =>
          getIt<TripSummaryBloc>()..add(TripSummaryLoaded(tripId)),
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
          onShare: () => context
              .read<TripSummaryBloc>()
              .add(const TripSummaryShareRequested()),
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
                  fuelCostFormatted: _fuelLabel(locale, trip),
                  rankLabel: '—',
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
      context
          .read<TripSummaryBloc>()
          .add(const TripSummaryDeleteRequested());
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
            onTap: () => context.canPop()
                ? context.pop()
                : context.go('/home'),
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
                const Icon(Icons.ios_share_rounded, color: AppColors.bg,
                    size: 14),
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
