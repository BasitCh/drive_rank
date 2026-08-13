import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/database/app_database.dart' show TripRow;
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/personal_record.dart';
import 'package:flutter/material.dart';

/// Distance / Duration / Fuel Cost row + optional achievement badge
/// rendered below the Journey map. Stats sit inside one bordered card
/// so the surface reads as a single "trip recap" block under the map.
///
/// Fuel cost falls back to a gentle "—" when the user hasn't configured
/// fuel — matching the Trip Summary AnalyticsGrid behaviour so the same
/// trip doesn't render two different fuel labels across surfaces.
class JourneyFooterStats extends StatelessWidget {
  const JourneyFooterStats({
    required this.trip,
    required this.locale,
    required this.achievement,
    super.key,
  });

  final TripRow trip;
  final LocaleService locale;
  final PersonalRecord? achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Cell(
                  label: 'DISTANCE',
                  value: locale.formatDistance(trip.distanceKm),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Cell(
                  label: 'DURATION',
                  value: locale.formatDuration(trip.durationSeconds),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Cell(label: 'FUEL COST', value: _fuelLabel()),
              ),
            ],
          ),
          if (achievement != null) ...[
            const SizedBox(height: AppSpacing.md),
            _Badge(record: achievement!),
          ],
        ],
      ),
    );
  }

  String _fuelLabel() {
    final cost = trip.fuelCostLocal;
    final code = trip.localCurrencyCode;
    if (cost == null || code == null) {
      return AppStrings.trackingFuelNotConfigured;
    }
    return locale.formatCurrency(cost, code);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // textTertiary at 9 pt was invisible on the dark card — bumped
        // to textSecondary (#8E8E9A) and weight 600 so the field
        // labels read at a glance in screenshots.
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.record});

  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Text(record.kind.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.kind.title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  record.valueDisplay,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
