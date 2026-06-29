import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Speed-over-time chart for the Performance card.
///
/// Designed for "flex" energy, not analysis: lightly damped waypoint
/// data (2-pt MA upstream) keeps the natural peaks and dips, fl_chart's
/// `shadow` parameter adds a thin teal glow that pops on dark
/// backgrounds, a low-alpha gradient fills underneath. Fixed axis
/// (0-400 km/h, 0-250 mph) so a 60 km/h commute reads as "could have
/// gone faster" instead of being auto-zoomed into a wall of peaks.
///
/// Y-axis labels live on the **right** — TripRank's signature framing
/// for these cards. fl_chart hides the left ticks; the right column
/// is the only label column.
class PerformanceChart extends StatelessWidget {
  const PerformanceChart({
    required this.bundle,
    required this.locale,
    super.key,
  });

  final InsightsBundle bundle;
  final LocaleService locale;

  /// Fixed ceiling in metric — the spec calls for a *flex* axis, not
  /// an auto-fit one. Hairy edge case: a sub-10-second video sprint
  /// past 400 km/h. We clamp to the ceiling rather than blow the axis.
  static const double _ceilingKmh = 400;

  /// Imperial mirror — 0..250 mph (~402 km/h).
  static const double _ceilingMph = 250;

  @override
  Widget build(BuildContext context) {
    final speeds = bundle.smoothedSpeedKmh;
    final times = bundle.smoothedSecondsFromStart;
    final isImperial = locale.unitSystem == UnitSystem.imperial;
    final ceiling = isImperial ? _ceilingMph : _ceilingKmh;

    final spots = <FlSpot>[
      for (var i = 0; i < speeds.length; i++)
        FlSpot(
          times[i].toDouble(),
          (isImperial ? speeds[i] * 0.621371 : speeds[i])
              .clamp(0, ceiling),
        ),
    ];
    final maxTime = (times.isEmpty ? 1 : times.last).toDouble();
    // 40 km/h ticks (or 25 mph in imperial) match the TripRank reference
    // and stay readable at typical phone widths. Grid lines + labels
    // both use the same interval so the eye reads one cadence.
    final step = isImperial ? 25.0 : 40.0;

    return AspectRatio(
      aspectRatio: 0.95, // tall — chart dominates the card
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxTime <= 0 ? 1 : maxTime,
          minY: 0,
          maxY: ceiling,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: step,
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
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                // Dedicated label column. Wider reserved space pushes
                // text safely outside the polyline area so the chart
                // can't visually overlap the right-axis values.
                reservedSize: 64,
                interval: step,
                getTitlesWidget: (value, meta) {
                  // Hide the 0 label — visually noisy at the baseline.
                  if (value <= 0.5) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      '${value.toStringAsFixed(0)} ${locale.speedUnitLabel}',
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
              // Polyline (not Bezier) preserves the natural waveform
              // peaks — the smoothing pass already de-noised single-
              // sample spikes, anything more would tame the screenshot.
              // Also removes per-frame Bezier control-point math, which
              // contributes to the perceived back-button lag on long
              // trips.
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
}
