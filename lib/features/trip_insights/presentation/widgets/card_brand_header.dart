import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart' show TripRow;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Top of every social card: the DriveRank wordmark + the trip's
/// vehicle + date row. Compact — the screenshot's information density
/// is owned by the hero strip / chart / map below it.
class CardBrandHeader extends StatelessWidget {
  const CardBrandHeader({
    required this.trip,
    required this.vehicleLabel,
    super.key,
  });

  final TripRow trip;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, MMM d').format(trip.startedAt.toLocal());
    final time = DateFormat.jm().format(trip.startedAt.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppStrings.appName.toUpperCase(),
          style: AppTextStyles.brandLogo.copyWith(
            fontSize: 24,
            letterSpacing: 4.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$date · $time · $vehicleLabel',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
