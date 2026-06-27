import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/personal_record.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/insights_section_card.dart';
import 'package:flutter/material.dart';

/// Stack of record badges — most-impressive first.
///
/// Empty state ("No records this trip") only shows for eligible trips
/// that didn't earn a badge. Trips on first-install (zero prior trips)
/// hide the section entirely upstream — the gate lives in
/// `InsightsBundle.recordsEligible`.
class PersonalRecordsList extends StatelessWidget {
  const PersonalRecordsList({required this.bundle, super.key});

  final InsightsBundle bundle;

  @override
  Widget build(BuildContext context) {
    return InsightsSectionCard(
      title: 'Personal Records',
      child: bundle.records.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                for (var i = 0; i < bundle.records.length; i++) ...[
                  _RecordTile(record: bundle.records[i]),
                  if (i != bundle.records.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              record.kind.emoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.kind.title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.valueDisplay,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text('🚗', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No records this trip — keep driving!',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
