import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_breakdown_slice.dart';
import 'package:flutter/material.dart';

/// Continuous gradient bar showing what fraction of the trip was
/// spent in each `SpeedBucket` band, plus a percentage-labelled
/// legend row underneath. The bucket boundaries are the app's single
/// speed-bucket scheme (also used for the route polyline colouring
/// and the Journey map legend) rather than a separate set, so the
/// colour language stays consistent everywhere a speed is shown.
class SpeedBreakdownBar extends StatelessWidget {
  const SpeedBreakdownBar({
    required this.slices,
    required this.locale,
    super.key,
  });

  final List<SpeedBreakdownSlice> slices;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final nonZero = slices.where((s) => s.percentage > 0).toList();
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
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.speedDistributionTitle,
                  style: AppTextStyles.label.copyWith(fontSize: 10),
                ),
              ),
              Text(
                locale.speedUnitLabel.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _GradientBar(slices: nonZero),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (final s in slices)
                Expanded(child: _LegendEntry(slice: s, locale: locale)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single continuous line whose colour flows through each bucket's
/// colour, weighted by how much of the trip it accounts for — the
/// blended-gradient look of the reference design, rather than the
/// earlier hard-edged block bar.
class _GradientBar extends StatelessWidget {
  const _GradientBar({required this.slices});

  final List<SpeedBreakdownSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    final colors = <Color>[];
    final stops = <double>[];
    var cumulative = 0.0;
    for (final s in slices) {
      colors.add(s.bucket.color);
      stops.add((cumulative + s.percentage / 2).clamp(0.0, 1.0));
      cumulative += s.percentage;
    }
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(colors: colors, stops: stops),
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.slice, required this.locale});

  final SpeedBreakdownSlice slice;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: slice.bucket.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _rangeLabel(),
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(slice.percentage * 100).round()}%',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _rangeLabel() {
    final unit = locale.speedUnitLabel;
    final lo = locale.formatSpeedValue(slice.bucket.minKmh);
    final hi = slice.bucket.maxKmh;
    if (slice.bucket.minKmh == 0 && hi != null) {
      return '<${locale.formatSpeedValue(hi)}$unit';
    }
    if (hi == null) return '>$lo$unit';
    return '$lo–${locale.formatSpeedValue(hi)}$unit';
  }
}
