import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/features/trip_summary/presentation/widgets/route_map_header.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:flutter/material.dart';

/// The shareable trip stat card.
///
/// Wrap with a `RepaintBoundary` to export at 3× via `CardExportService`.
/// Layout (top → bottom) matches the HTML mock 1:1:
///   - Route map header (100dp) with car tag + optional weather tag
///   - Top-speed hero (BebasNeue 60dp number, teal unit, optional rank
///     badge in yellow)
///   - Three stat cells (Avg / Distance / Duration)
///   - Footer: faded DRIVERANK wordmark + g-force badge
class StatCard extends StatelessWidget {
  const StatCard({
    required this.locale,
    required this.theme,
    required this.points,
    required this.topSpeedKmh,
    required this.avgSpeedKmh,
    required this.distanceKm,
    required this.durationSeconds,
    required this.maxGforce,
    required this.carTag,
    super.key,
    this.weatherTag,
    this.rankBadge,
  });

  final LocaleService locale;
  final MapTheme theme;
  final List<TripPoint> points;
  final double topSpeedKmh;
  final double avgSpeedKmh;
  final double distanceKm;
  final int durationSeconds;
  final double maxGforce;
  final String carTag;
  final String? weatherTag;
  final String? rankBadge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141420), Color(0xFF0E0E18)],
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.12),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        // LayoutBuilder lets every internal size scale with the card's
        // outer width — same widget renders crisply at narrow phone
        // widths (350dp), tablets (600dp+), and the 3× exported PNG.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final headerHeight = (w * 0.27).clamp(80.0, 140.0);
            final bodyPadding = (w * 0.04).clamp(10.0, 18.0);
            final blockGap = (w * 0.03).clamp(8.0, 14.0);
            final glowSize = (w * 0.34).clamp(80.0, 160.0);
            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RouteMapHeader(
                      theme: theme,
                      points: points,
                      carTag: carTag,
                      weatherTag: weatherTag,
                      height: headerHeight,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        bodyPadding,
                        bodyPadding * 0.85,
                        bodyPadding,
                        bodyPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TopSpeedHero(
                            valueText: locale.formatSpeedValue(topSpeedKmh),
                            unitLabel: locale.speedUnitLabel,
                            rankBadge: rankBadge,
                          ),
                          SizedBox(height: blockGap),
                          const _Divider(),
                          SizedBox(height: blockGap),
                          _StatsRow(
                            avg: locale.formatSpeed(avgSpeedKmh),
                            distance: locale.formatDistance(distanceKm),
                            duration: locale.formatDuration(durationSeconds),
                          ),
                          SizedBox(height: blockGap),
                          _FooterRow(maxGforce: maxGforce),
                        ],
                      ),
                    ),
                  ],
                ),
                // Subtle teal glow in the top-right corner.
                Positioned(
                  top: -glowSize * 0.25,
                  right: -glowSize * 0.25,
                  child: IgnorePointer(
                    child: Container(
                      width: glowSize,
                      height: glowSize,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.teal.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopSpeedHero extends StatelessWidget {
  const _TopSpeedHero({
    required this.valueText,
    required this.unitLabel,
    required this.rankBadge,
  });

  final String valueText;
  final String unitLabel;
  final String? rankBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppStrings.trackingTopSpeed,
          style: AppTextStyles.microLabel.copyWith(fontSize: 8),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: valueText, style: AppTextStyles.statCardSpeed),
              TextSpan(
                text: ' $unitLabel',
                style: AppTextStyles.speedUnit.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
        if (rankBadge != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.yellow.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rankBadge!,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.yellow,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.border);
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.avg,
    required this.distance,
    required this.duration,
  });

  final String avg;
  final String distance;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Cell(value: avg, label: AppStrings.trackingAvgSpeed),
        _Cell(value: distance, label: AppStrings.trackingDistance),
        _Cell(value: duration, label: AppStrings.trackingDuration),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.microLabel.copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.maxGforce});

  final double maxGforce;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.appName.toUpperCase(),
          style: AppTextStyles.cardBrand.copyWith(
            color: AppColors.teal.withValues(alpha: 0.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.orange.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Text(
                '${maxGforce.toStringAsFixed(1)}'
                '${AppStrings.tripSummaryGforcePeakSuffix}',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
