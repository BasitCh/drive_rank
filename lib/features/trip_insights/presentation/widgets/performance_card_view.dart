import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/card_brand_footer.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/card_brand_header.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/elevation_chart.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/hero_stat_strip.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/performance_chart.dart';
import 'package:flutter/material.dart';

/// The Performance share card — a single-image flex surface optimised
/// for IG Stories / TikTok end cards. Renders identically on the page
/// and inside the off-screen capture; what the user sees is what the
/// share looks like.
///
/// Layout:
///   ┌────────────────────────────┐
///   │  DRIVERANK                 │   brand header
///   │  Wed, Jun 17 · Suzuki ...  │
///   │                            │
///   │  ┌────────┬─────────────┐  │
///   │  │ Top    │   Avg       │  │   hero strip
///   │  │ Dist   │   Achv      │  │
///   │  └────────┴─────────────┘  │
///   │                            │
///   │  ┌────────────────────┐    │
///   │  │   Speed Over Time  │    │   energetic chart
///   │  │   ▲▲∧∧╱╲╱╲▼▼  ▴▴  │    │
///   │  └────────────────────┘    │
///   │                            │
///   │       DRIVERANK            │   footer
///   └────────────────────────────┘
class PerformanceCardView extends StatelessWidget {
  const PerformanceCardView({
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardBrandHeader(trip: bundle.trip, vehicleLabel: vehicleLabel),
            const SizedBox(height: AppSpacing.lg),
            HeroStatStrip(
              trip: bundle.trip,
              locale: locale,
              bestAchievement: bundle.bestAchievement,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
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
                        const Expanded(
                          child: Text(
                            'Speed Over Time',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
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
                  ),
                  PerformanceChart(bundle: bundle, locale: locale),
                  if (bundle.elevationEligible) ...[
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              AppStrings.elevationChartTitle,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            locale.elevationUnitLabel.toUpperCase(),
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
                    ElevationChart(bundle: bundle, locale: locale),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const CardBrandFooter(),
          ],
        ),
      ),
    );
  }
}
