import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/insights_brand_footer.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/insights_brand_header.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/insights_hero_strip.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/personal_records_list.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/speed_breakdown_bars.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/speed_intensity_map.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/speed_over_time_chart.dart';
import 'package:flutter/material.dart';

/// Single composite Trip Insights surface — used both inside the
/// in-app `TripInsightsPage` (wrapped in a Scaffold + chrome) and as
/// the off-screen capture target for the share button.
///
/// One source of truth means the screenshot matches what the user sees
/// pixel-for-pixel — no surprises post-share.
class InsightsSocialCard extends StatelessWidget {
  const InsightsSocialCard({
    required this.bundle,
    required this.locale,
    required this.vehicleLabel,
    super.key,
  });

  final InsightsBundle bundle;
  final LocaleService locale;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InsightsBrandHeader(trip: bundle.trip, vehicleLabel: vehicleLabel),
            const SizedBox(height: AppSpacing.lg),
            InsightsHeroStrip(
              trip: bundle.trip,
              locale: locale,
              bestAchievement: bundle.bestAchievement,
            ),
            if (bundle.chartEligible) ...[
              const SizedBox(height: AppSpacing.md),
              SpeedOverTimeChart(bundle: bundle, locale: locale),
            ],
            if (bundle.segments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SpeedIntensityMap(bundle: bundle, locale: locale),
            ],
            if (bundle.breakdownEligible) ...[
              const SizedBox(height: AppSpacing.md),
              SpeedBreakdownBars(bundle: bundle, locale: locale),
            ],
            if (bundle.recordsEligible) ...[
              const SizedBox(height: AppSpacing.md),
              PersonalRecordsList(bundle: bundle),
            ],
            const SizedBox(height: AppSpacing.sm),
            const InsightsBrandFooter(),
          ],
        ),
      ),
    );
  }
}
