import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/history/presentation/widgets/route_sparkline.dart';
import 'package:flutter/material.dart';

/// One row in the trip history list.
///
/// Route-shape sparkline | name + date/distance | top speed.
/// Wrap with `Dismissible` (in the page) for swipe-to-delete.
class TripListItem extends StatelessWidget {
  const TripListItem({
    required this.trip,
    required this.locale,
    required this.onTap,
    super.key,
  });

  final TripRow trip;
  final LocaleService locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RouteSparkline(tripId: trip.id),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tripName(trip),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_relativeDate(trip.startedAt)} · '
                      '${locale.formatDistance(trip.distanceKm)}',
                      style: AppTextStyles.microLabel.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    locale.formatSpeedValue(trip.topSpeedKmh),
                    style: const TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 25,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  Text(
                    locale.speedUnitLabel,
                    style: AppTextStyles.microLabel.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _tripName(TripRow t) {
    final hour = t.startedAt.hour;
    if (hour >= 5 && hour < 12) return 'Morning Drive';
    if (hour >= 12 && hour < 17) return 'Afternoon Drive';
    if (hour >= 17 && hour < 21) return 'Evening Drive';
    return 'Night Drive';
  }

  static String _relativeDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final delta = today.difference(that).inDays;
    if (delta == 0) return 'Today';
    if (delta == 1) return 'Yesterday';
    if (delta < 7) return '$delta days ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
