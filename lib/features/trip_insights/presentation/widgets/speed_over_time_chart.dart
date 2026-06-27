import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/insights_section_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Smoothed speed-over-time line chart.
///
/// Reads pre-computed `smoothedSpeedKmh` + `smoothedSecondsFromStart`
/// off the bundle — no math in build. Minimal axis chrome so the line
/// itself owns the frame: teal stroke + soft gradient fill, no grid,
/// 3 y-ticks. Optimised for the screenshot.
class SpeedOverTimeChart extends StatelessWidget {
  const SpeedOverTimeChart({
    required this.bundle,
    required this.locale,
    super.key,
  });

  final InsightsBundle bundle;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final speeds = bundle.smoothedSpeedKmh;
    final times = bundle.smoothedSecondsFromStart;
    final maxSpeed = _ceilTo(
      speeds.fold<double>(0, (a, b) => b > a ? b : a),
      20,
    );
    final maxTime = (times.isEmpty ? 0 : times.last).toDouble();
    final isImperial = locale.unitSystem == UnitSystem.imperial;

    final spots = <FlSpot>[
      for (var i = 0; i < speeds.length; i++)
        FlSpot(
          times[i].toDouble(),
          isImperial ? speeds[i] * 0.621371 : speeds[i],
        ),
    ];
    final yMax = isImperial ? maxSpeed * 0.621371 : maxSpeed;

    return InsightsSectionCard(
      title: 'Speed Over Time',
      trailing: locale.speedUnitLabel,
      child: AspectRatio(
        aspectRatio: 1.85,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxTime <= 0 ? 1 : maxTime,
            minY: 0,
            maxY: yMax <= 0 ? 1 : yMax,
            lineTouchData: const LineTouchData(enabled: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yMax / 3,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: yMax / 3,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.18,
                color: AppColors.teal,
                barWidth: 2.4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.teal.withValues(alpha: 0.28),
                      AppColors.teal.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Rounds [v] up to the nearest multiple of [step] so the y-axis ends
  /// on a round number — the chart reads cleaner in the screenshot than
  /// "max = 287".
  double _ceilTo(double v, double step) {
    if (v <= 0) return step;
    return (v / step).ceilToDouble() * step;
  }
}
