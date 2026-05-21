import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Banner card shown on the profile (and at top of history) that surfaces
/// this month's roll-up — "May Driving Report · 847 km · 14 trips · Tap to
/// see your month".
class MonthlyReportCard extends StatelessWidget {
  const MonthlyReportCard({
    required this.report,
    required this.locale,
    required this.onTap,
    super.key,
  });

  final MonthlyReport report;
  final LocaleService locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat.MMMM().format(
      DateTime(report.year, report.month),
    );
    final subtitle = report.isEmpty
        ? AppStrings.monthlyReportEmpty
        : '${locale.formatDistance(report.totalDistanceKm)} · '
              '${report.tripCount} trips · '
              '${AppStrings.monthlyReportCta}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.teal.withValues(alpha: 0.08),
                AppColors.blue.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthName ${AppStrings.monthlyReportTitle}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.teal,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
