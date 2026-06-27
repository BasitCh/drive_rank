import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart' show TripRow;
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/personal_record.dart';
import 'package:flutter/material.dart';

/// 2x2 hero strip at the top of Insights.
///
/// Cell layout (chosen for screenshot density — the diagonal teal
/// emphasis pulls the eye from top-left "biggest stat" down to the
/// bottom-right achievement, which is the post-share flex):
///   ┌─────────────┬─────────────┐
///   │  Top Speed  │  Avg Speed  │
///   ├─────────────┼─────────────┤
///   │  Distance   │ Best Ach.   │
///   └─────────────┴─────────────┘
///
/// When the trip earned no badge, the achievement cell falls back to
/// the trip duration so the grid stays symmetric.
class InsightsHeroStrip extends StatelessWidget {
  const InsightsHeroStrip({
    required this.trip,
    required this.locale,
    required this.bestAchievement,
    super.key,
  });

  final TripRow trip;
  final LocaleService locale;
  final PersonalRecord? bestAchievement;

  @override
  Widget build(BuildContext context) {
    final ach = bestAchievement;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _HeroCell(
                  label: 'TOP SPEED',
                  value: locale.formatSpeed(trip.topSpeedKmh),
                  accent: AppColors.teal,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HeroCell(
                  label: 'AVG SPEED',
                  value: locale.formatSpeed(trip.avgSpeedKmh),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HeroCell(
                  label: 'DISTANCE',
                  value: locale.formatDistance(trip.distanceKm),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HeroCell(
                  label: ach != null ? 'ACHIEVEMENT' : 'DURATION',
                  value: ach != null
                      ? '${ach.kind.emoji} ${ach.kind.title}'
                      : locale.formatDuration(trip.durationSeconds),
                  accent: ach != null ? AppColors.teal : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCell extends StatelessWidget {
  const _HeroCell({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.microLabel.copyWith(fontSize: 9),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: accent ?? AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
