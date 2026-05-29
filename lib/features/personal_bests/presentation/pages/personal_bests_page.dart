import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/personal_bests/domain/personal_bests.dart';
import 'package:drive_rank/features/personal_bests/presentation/bloc/personal_bests_bloc.dart';
import 'package:drive_rank/features/tracking/presentation/widgets/mini_stat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Personal Bests — local-only roll-ups of the user's best numbers
/// across every saved trip. Replaces the (removed) Leaderboard tab
/// for the MVP launch.
///
/// Six tiles in a 2×3 grid, plus a header and a soft "all your trips,
/// in one place" subtitle. Every value is recomputed from the trips
/// table on demand; the bloc subscribes to a reactive stream so the
/// page redraws the moment a new trip lands.
class PersonalBestsPage extends StatelessWidget {
  const PersonalBestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PersonalBestsBloc>(
      create: (_) =>
          getIt<PersonalBestsBloc>()..add(const PersonalBestsStarted()),
      child: const _PersonalBestsBody(),
    );
  }
}

class _PersonalBestsBody extends StatelessWidget {
  const _PersonalBestsBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<PersonalBestsBloc, PersonalBestsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              );
            }
            if (state.bests.isEmpty) {
              return const _EmptyState();
            }
            return _Loaded(bests: state.bests);
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: AppColors.teal,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No bests yet',
              style: AppTextStyles.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Record your first trip and the numbers below light up. '
              'Your bests live on this phone — nothing leaves the device.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.bests});

  final PersonalBests bests;

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        const _Header(),
        const SizedBox(height: AppSpacing.xl),
        _StatsGrid(bests: bests, locale: locale)
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: 0.05, duration: 280.ms, curve: Curves.easeOut),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PERSONAL BESTS', style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'All your numbers, in one place. Updates after every trip.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.bests, required this.locale});

  final PersonalBests bests;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    // 2×3 grid of MiniStat tiles (reusing the same widget as the live
    // tracking screen for visual consistency). Rows of 2 instead of 3
    // here so the numbers have more headroom — Personal Bests are
    // hero figures, not glanceable telemetry.
    return Column(
      children: [
        _Row(
          left: MiniStat(
            value: locale.formatSpeedValue(bests.topSpeedKmh),
            label: 'TOP SPEED ${locale.speedUnitLabel}',
            valueColor: AppColors.teal,
          ),
          right: MiniStat(
            value: locale.formatDistance(bests.longestTripKm),
            label: 'LONGEST TRIP',
            valueColor: AppColors.blue,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Row(
          left: MiniStat(
            value: bests.totalTrips.toString(),
            label: 'TOTAL TRIPS',
          ),
          right: MiniStat(
            value: locale.formatDistance(bests.totalDistanceKm),
            label: 'TOTAL DISTANCE',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Row(
          left: MiniStat(
            value: locale.formatSpeedValue(bests.bestAvgSpeedKmh),
            label: 'BEST AVG ${locale.speedUnitLabel}',
            valueColor: AppColors.orange,
          ),
          right: MiniStat(
            value: locale.formatDuration(bests.totalDriveSeconds),
            label: 'TOTAL DRIVE TIME',
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: right),
      ],
    );
  }
}
