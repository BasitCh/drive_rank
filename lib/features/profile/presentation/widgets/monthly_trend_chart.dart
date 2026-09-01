import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Line/area chart of total distance per month for the last 6 months —
/// just the chart, no card chrome (the caller — the Profile page's "This
/// Month" hero card — supplies that, so the two read as one unified
/// card instead of a card nested inside a card). Renders nothing when
/// there's no data at all (the caller is responsible for not mounting
/// this widget in that case).
///
/// `LineChart` is an `ImplicitlyAnimatedWidget` — it only tweens
/// *between* an old and a new value, so passing `duration`/`curve` alone
/// does nothing on the very first build (there's no "old" state to
/// animate from, so it just snaps straight to its final shape). To get
/// the line to draw itself in on load, this widget renders a flat
/// zero-height line for one frame, then flips to the real curve on the
/// next frame — giving the `LineChart` something to tween away from.
class MonthlyTrendChart extends StatefulWidget {
  const MonthlyTrendChart({
    required this.stats,
    required this.locale,
    super.key,
  });

  final List<MonthlyDistanceStat> stats;
  final LocaleService locale;

  @override
  State<MonthlyTrendChart> createState() => _MonthlyTrendChartState();
}

class _MonthlyTrendChartState extends State<MonthlyTrendChart> {
  bool _grown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _grown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawStats = widget.stats;
    if (rawStats.isEmpty) return const SizedBox.shrink();

    // `monthlyDistanceTrend` omits months with no trips entirely, so a
    // brand-new account with a single trip ever gets exactly one data
    // point. A line chart can't draw a line through one point — it was
    // rendering as an isolated dot with no line or fill underneath it,
    // which read as broken rather than "your trend so far". Prepending
    // a synthetic zero-distance point for the prior month gives it an
    // actual line to draw, matching how this chart looks once a second
    // real month of data exists.
    final stats = rawStats.length == 1
        ? [_priorMonthZero(rawStats.first), rawStats.first]
        : rawStats;

    final maxKm = stats
        .map((s) => s.distanceKm)
        .reduce((a, b) => a > b ? a : b);
    // Headroom above the peak so the line doesn't touch the top edge.
    final maxY = maxKm <= 0 ? 1.0 : maxKm * 1.3;
    final lastIndex = stats.length - 1;

    return SizedBox(
      height: 120,
      child: LineChart(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        LineChartData(
          maxY: maxY,
          minY: 0,
          minX: 0,
          maxX: lastIndex.toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
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
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
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
                      style: AppTextStyles.microLabel.copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < stats.length; i++)
                  FlSpot(i.toDouble(), _grown ? stats[i].distanceKm : 0),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: AppColors.green,
              barWidth: 2.5,
              dotData: FlDotData(
                checkToShowDot: (spot, bar) => spot.x == lastIndex,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.green,
                      strokeColor: AppColors.bg,
                      strokeWidth: 2,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.green.withValues(alpha: 0.28),
                    AppColors.green.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MonthlyDistanceStat _priorMonthZero(MonthlyDistanceStat only) {
    final prior = DateTime(only.year, only.month - 1);
    return MonthlyDistanceStat(
      year: prior.year,
      month: prior.month,
      distanceKm: 0,
    );
  }
}
