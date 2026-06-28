import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/card_brand_footer.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/card_brand_header.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/journey_footer_stats.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/journey_map.dart';
import 'package:flutter/material.dart';

/// Single-image Journey share card. Map dominates the surface (~70% of
/// the vertical real estate), explicit START / END markers, speed
/// legend, then a compact stats footer with the optional achievement
/// badge.
///
/// Same widget tree on the page as inside the share PNG — the user
/// frames the map by panning / zooming on the page, the screenshot
/// captures exactly that.
class JourneyCardView extends StatelessWidget {
  const JourneyCardView({
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
            // ~70 % of the card height — the screenshot's hero surface.
            // AspectRatio with a tall ratio so the map looks dominant on
            // a phone-sized portrait crop even when the rest of the
            // column is short.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: AspectRatio(
                aspectRatio: 0.88,
                child: JourneyMap(bundle: bundle),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const JourneyMapLegend(),
            const SizedBox(height: AppSpacing.md),
            JourneyFooterStats(
              trip: bundle.trip,
              locale: locale,
              achievement: bundle.bestAchievement,
            ),
            const SizedBox(height: AppSpacing.lg),
            const CardBrandFooter(),
          ],
        ),
      ),
    );
  }
}
