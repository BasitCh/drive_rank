import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Elevation-over-time chart for the Performance card — styled
/// identically to `PerformanceChart` (same line/gradient/grid/axis
/// treatment) so the two read as one system, placed directly below it.
///
/// Unlike the speed chart's fixed 0–400 km/h "flex" axis, elevation has
/// no universal scale (sea-level coastal drives vs mountain passes), so
/// this one auto-fits to the trip's own smoothed min/max with a small
/// padding margin.
class ElevationChart extends StatelessWidget {
  const ElevationChart({required this.bundle, required this.locale, super.key});

  final InsightsBundle bundle;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final rawMetres = bundle.smoothedElevationMeters;
    final times = bundle.smoothedElevationSecondsFromStart;
    final isImperial = locale.unitSystem == UnitSystem.imperial;
    final values = [
      for (final m in rawMetres)
        isImperial ? m * AppConstants.metresToFeet : m,
    ];

    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        FlSpot(times[i].toDouble(), values[i]),
    ];
    final maxTime = (times.isEmpty ? 1 : times.last).toDouble();

    var minY = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    var maxY = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    // Pad the range so the line never touches the top/bottom grid edge,
    // and guard the degenerate flat-elevation case (maxY == minY).
    final span = (maxY - minY).abs();
    final pad = span < 1 ? 1.0 : span * 0.15;
    minY -= pad;
    maxY += pad;
    final step = _niceStep(maxY - minY);

    return AspectRatio(
      aspectRatio: 0.95,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxTime <= 0 ? 1 : maxTime,
          minY: minY,
          maxY: maxY,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: step,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 64,
                interval: step,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      '${value.toStringAsFixed(0)} ${locale.elevationUnitLabel}',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
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
              isCurved: false,
              color: AppColors.teal,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.teal.withValues(alpha: 0.22),
                    AppColors.teal.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A "nice" grid interval for an auto-fit range — roughly a quarter
  /// of the span, rounded to 1/2/5 × a power of ten so labels read as
  /// round numbers instead of "173.4 m".
  double _niceStep(double range) {
    if (range <= 0) return 1;
    final raw = range / 4;
    final magnitude = _pow10Floor(raw);
    final normalized = raw / magnitude;
    final niceNormalized = normalized < 1.5
        ? 1.0
        : normalized < 3.5
        ? 2.0
        : normalized < 7.5
        ? 5.0
        : 10.0;
    return niceNormalized * magnitude;
  }

  double _pow10Floor(double value) {
    var magnitude = 1.0;
    if (value <= 0) return magnitude;
    while (magnitude * 10 <= value) {
      magnitude *= 10;
    }
    while (magnitude > value) {
      magnitude /= 10;
    }
    return magnitude;
  }
}
