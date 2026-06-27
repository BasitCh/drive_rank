import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart' show TripRow;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Top of the social card: small DriveRank wordmark + the trip's date
/// and vehicle. Reads at a glance — first thing a viewer sees in the
/// Instagram crop preview.
class InsightsBrandHeader extends StatelessWidget {
  const InsightsBrandHeader({
    required this.trip,
    required this.vehicleLabel,
    super.key,
  });

  final TripRow trip;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.MMMEd().format(trip.startedAt.toLocal());
    final timeLabel = DateFormat.jm().format(trip.startedAt.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppStrings.appName.toUpperCase(),
          style: AppTextStyles.brandLogo.copyWith(
            fontSize: 22,
            letterSpacing: 4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$dateLabel · $timeLabel · $vehicleLabel',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
