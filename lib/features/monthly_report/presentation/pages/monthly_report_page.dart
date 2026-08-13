import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/trip_stats_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The "Spotify Wrapped for your car" monthly recap — full screen, with
/// totals + per-metric tiles. Falls back to an empty-state if the user
/// hasn't driven this month yet.
class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({this.year, this.month, super.key});

  /// Defaults to the current calendar month if null.
  final int? year;
  final int? month;

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  late final Future<MonthlyReport> _future;
  late final int _year;
  late final int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = widget.year ?? now.year;
    _month = widget.month ?? now.month;
    _future = _load();
  }

  Future<MonthlyReport> _load() async {
    final settings = await getIt<UserSettingsRepository>().read();
    return getIt<TripStatsService>().monthlyReport(
      uid: settings.uid,
      year: _year,
      month: _month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    final monthName = DateFormat.yMMMM().format(DateTime(_year, _month));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FutureBuilder<MonthlyReport>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              );
            }
            return _Body(
              report: snap.data!,
              locale: locale,
              monthName: monthName,
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.report,
    required this.locale,
    required this.monthName,
  });

  final MonthlyReport report;
  final LocaleService locale;
  final String monthName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(monthName: monthName),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: report.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        AppStrings.monthlyReportEmpty,
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _Stats(report: report, locale: locale),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.monthName});

  final String monthName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Row(
        children: [
          Material(
            color: AppColors.card,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/profile'),
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              monthName.toUpperCase(),
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.report, required this.locale});

  final MonthlyReport report;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroNumber(
          value: locale.formatDistance(report.totalDistanceKm),
          label: AppStrings.monthlyReportTotalKm,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _Tile(
              value: report.tripCount.toString(),
              label: AppStrings.monthlyReportTotalTrips,
            ),
            const SizedBox(width: 8),
            _Tile(
              value: locale.formatSpeed(report.topSpeedKmh),
              label: AppStrings.monthlyReportTopSpeed,
              valueColor: AppColors.teal,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Tile(
              value: locale.formatDuration(report.totalDurationSeconds),
              label: AppStrings.monthlyReportTotalDuration,
            ),
            const SizedBox(width: 8),
            _Tile(
              value: '${report.bestGforce.toStringAsFixed(1)}g',
              label: AppStrings.monthlyReportBestGforce,
              valueColor: AppColors.orange,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Tile(
          value: _weekdayLabel(report.mostActiveWeekday),
          label: AppStrings.monthlyReportMostActiveDay,
          valueColor: AppColors.blue,
          fullWidth: true,
        ),
      ],
    );
  }

  static String _weekdayLabel(int? weekday) {
    if (weekday == null) return '—';
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[(weekday - 1).clamp(0, 6)];
  }
}

class _HeroNumber extends StatelessWidget {
  const _HeroNumber({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 72,
            height: 1,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    this.valueColor,
    this.fullWidth = false,
  });

  final String value;
  final String label;
  final Color? valueColor;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.microLabel.copyWith(fontSize: 9)),
        ],
      ),
    );
    return fullWidth ? child : Expanded(child: child);
  }
}
