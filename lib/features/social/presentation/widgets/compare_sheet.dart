import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsRow;
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/usecases/compare_with_benchmark.dart';
import 'package:drive_rank/features/social/presentation/widgets/benchmark_badge.dart';
import 'package:drive_rank/shared/models/car_category.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/widgets/car_silhouette.dart';
import 'package:flutter/material.dart';

/// You against one benchmark, metric by metric.
///
/// The board tells you where you stand; this tells you *why*. Both sides
/// are real — your figures come from the same calculator the board uses,
/// the benchmark's from its published constants — so the bars measure
/// something rather than dramatise it.
///
/// This is deliberately the layout a real friend will occupy. When the
/// remote phase lands, their values replace the constants and their car
/// replaces the gauge glyph; nothing else about this screen changes.
class CompareSheet extends StatelessWidget {
  const CompareSheet({
    required this.comparison,
    required this.periodLabel,
    required this.metricLabel,
    required this.formatValue,
    this.viewer,
    super.key,
  });

  final BenchmarkComparison comparison;
  final String periodLabel;
  final String Function(CompetitionMetric) metricLabel;

  /// Formats one metric's value with its unit — the caller owns units.
  final String Function(CompetitionMetric, double) formatValue;

  final UserSettingsRow? viewer;

  @override
  Widget build(BuildContext context) {
    final led = comparison.metricsLed;
    final total = comparison.metricCount;

    return SafeArea(
      // Scrollable rather than a bare column: three metric rows plus two
      // identities is close to the height a modal sheet gets, and a
      // short screen or a large text size would otherwise overflow
      // instead of just scrolling.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Text(
                  AppStrings.compareTitle,
                  style: AppTextStyles.headingMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: AppColors.border2),
                  ),
                  child: Text(
                    periodLabel.toUpperCase(),
                    style: AppTextStyles.microLabel.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _You(viewer: viewer)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 22,
                      height: 1.6,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Expanded(child: _Them(name: comparison.benchmarkName)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final row in comparison.rows) ...[
              _MetricRow(
                label: metricLabel(row.metric),
                mineLabel: formatValue(row.metric, row.mine),
                theirsLabel: formatValue(row.metric, row.theirs),
                share: row.myShare,
                iLead: row.iLead,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: 2),
            Center(
              child: Text(
                led == 0
                    ? AppStrings.compareScoreNone
                    : led == total
                    ? AppStrings.compareAllLed
                    : AppStrings.compareScore(led, total),
                style: AppTextStyles.bodySmall.copyWith(
                  color: led > 0 ? AppColors.teal : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _You extends StatelessWidget {
  const _You({this.viewer});

  final UserSettingsRow? viewer;

  @override
  Widget build(BuildContext context) {
    final settings = viewer;
    final flag = countryFromCode(settings?.country ?? '')?.flag;
    final hasPhoto =
        settings?.carPhotoPath != null && settings!.carPhotoPath!.isNotEmpty;
    final category = settings?.vehicleType == VehicleType.motorbike.id
        ? CarCategory.motorbike
        : CarCategory.defaultCategory;
    final car = [
      settings?.carMake ?? '',
      settings?.carModel ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.card,
            border: Border.all(color: AppColors.teal, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(hasPhoto ? 0 : 11),
            child: CarSilhouette(
              category: category,
              photoPath: settings?.carPhotoPath,
              fit: hasPhoto ? BoxFit.cover : BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppStrings.compareYou,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          [if (flag != null) flag, if (car.isNotEmpty) car].join(' '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.microLabel.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _Them extends StatelessWidget {
  const _Them({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The same gauge glyph the board uses. A benchmark gets no car,
        // no photo and no flag here either — the rule doesn't relax
        // because the screen got bigger.
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.card,
            border: Border.all(color: AppColors.border2),
          ),
          child: const Icon(
            Icons.speed_rounded,
            size: 30,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        const BenchmarkBadge(),
      ],
    );
  }
}

/// One metric as two bars growing from a shared centre.
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.mineLabel,
    required this.theirsLabel,
    required this.share,
    required this.iLead,
  });

  final String label;
  final String mineLabel;
  final String theirsLabel;

  /// The viewer's portion of the pair, 0..1 — both bars are drawn on one
  /// scale so the longer bar really is the bigger number.
  final double share;
  final bool iLead;

  @override
  Widget build(BuildContext context) {
    final mine = share.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              mineLabel,
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 18,
                height: 1,
                color: iLead ? AppColors.teal : AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  fontSize: 9,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            Text(
              theirsLabel,
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 18,
                height: 1,
                color: iLead ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 8,
          child: Row(
            children: [
              Expanded(
                flex: (mine * 1000).round().clamp(1, 1000),
                child: Container(
                  decoration: BoxDecoration(
                    color: iLead ? AppColors.teal : AppColors.border2,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                flex: ((1 - mine) * 1000).round().clamp(1, 1000),
                child: Container(
                  decoration: BoxDecoration(
                    color: iLead ? AppColors.border2 : AppColors.textTertiary,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
