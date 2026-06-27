import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_bucket.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/insights_section_card.dart';
import 'package:flutter/material.dart';

/// Horizontal bar chart — % of trip time in each speed bucket.
///
/// Bar widths come straight from the pre-computed bundle. Label
/// rendering converts km/h boundaries to mph via `LocaleService` at
/// build-time only — no math.
class SpeedBreakdownBars extends StatelessWidget {
  const SpeedBreakdownBars({
    required this.bundle,
    required this.locale,
    super.key,
  });

  final InsightsBundle bundle;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return InsightsSectionCard(
      title: 'Speed Breakdown',
      trailing: 'Time spent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < bundle.breakdown.length; i++) ...[
            _Row(
              label: _labelFor(bundle.breakdown[i].bucket),
              percentage: bundle.breakdown[i].percentage,
              color: bundle.breakdown[i].bucket.color,
            ),
            if (i != bundle.breakdown.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  String _labelFor(SpeedBucket bucket) {
    final min = locale.formatSpeed(bucket.minKmh).split(' ').first;
    final max = bucket.maxKmh;
    final unit = locale.speedUnitLabel;
    if (max == null) return '$min+ $unit';
    final maxLabel = locale.formatSpeed(max).split(' ').first;
    return '$min–$maxLabel $unit';
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${(percentage * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
