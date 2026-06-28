import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart' show TripRow;
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/personal_record.dart';
import 'package:flutter/material.dart';

/// 2x2 hero strip used by both social cards.
///
/// Top row anchors the eye with the two "flex" numbers (Top Speed left,
/// teal-accented, then Avg Speed). Bottom row balances with Distance
/// and the Best Achievement badge — when no record fired, that cell
/// shows the trip duration instead so the grid stays symmetric.
class HeroStatStrip extends StatelessWidget {
  const HeroStatStrip({
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
                child: _Cell(
                  label: 'TOP SPEED',
                  value: locale.formatSpeed(trip.topSpeedKmh),
                  accent: AppColors.teal,
                  big: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Cell(
                  label: 'AVG SPEED',
                  value: locale.formatSpeed(trip.avgSpeedKmh),
                  big: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Cell(
                  label: 'DISTANCE',
                  value: locale.formatDistance(trip.distanceKm),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Cell(
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

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    this.accent,
    this.big = false,
  });

  final String label;
  final String value;
  final Color? accent;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.microLabel.copyWith(fontSize: 9)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: big ? 24 : 16,
            fontWeight: FontWeight.w700,
            color: accent ?? AppColors.textPrimary,
            letterSpacing: -0.4,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}
