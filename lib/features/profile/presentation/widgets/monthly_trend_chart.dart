import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Compact bar chart on the profile screen — total distance per month
/// for the last 6 months. Renders nothing when there's no data at all
/// (the caller is responsible for not mounting this widget in that
/// case) and only draws bars for months that actually have a trip.
class MonthlyTrendChart extends StatelessWidget {
  const MonthlyTrendChart({
    required this.stats,
    required this.locale,
    super.key,
  });

  final List<MonthlyDistanceStat> stats;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final maxKm = stats
        .map((s) => s.distanceKm)
        .reduce((a, b) => a > b ? a : b);
    // Headroom above the tallest bar so its value label doesn't clip.
    final maxY = maxKm <= 0 ? 1.0 : maxKm * 1.25;

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
          Text(
            AppStrings.profileTrendTitle,
            style: AppTextStyles.label.copyWith(fontSize: 10),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                // Touch is disabled, but the tooltip is forced always-on
                // (via `showingTooltipIndicators` below) purely as a
                // value label above each bar — the user's unit system
                // via `locale.formatDistance`, not a hover affordance.
                barTouchData: BarTouchData(
                  enabled: false,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 6,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        locale.formatDistance(
                          stats[group.x].distanceKm,
                          fractionDigits: 0,
                        ),
                        AppTextStyles.microLabel.copyWith(fontSize: 9),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= stats.length) {
                          return const SizedBox.shrink();
                        }
                        final s = stats[i];
                        final label = DateFormat(
                          'MMM',
                        ).format(DateTime(s.year, s.month));
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: AppTextStyles.microLabel.copyWith(
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < stats.length; i++)
                    BarChartGroupData(
                      x: i,
                      showingTooltipIndicators: const [0],
                      barRods: [
                        BarChartRodData(
                          toY: stats[i].distanceKm,
                          color: AppColors.teal,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
