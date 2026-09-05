import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:flutter/material.dart';

/// One trophy, in one of three honest states.
///
///  * **Earned** — teal, with the date it was unlocked.
///  * **Not yet earned, but earnable** — muted, showing what to do.
///  * **Not yet earnable at all** — muted, and it says *why* ("needs
///    friends"). Four of the seven trophies are in this state until the
///    remote layer exists, and hiding that would be telling the user to
///    chase something unreachable.
class TrophyTile extends StatelessWidget {
  const TrophyTile({
    required this.type,
    this.unlockedAt,
    this.unlockedLabel,
    super.key,
  });

  final TrophyType type;

  /// Null when the user hasn't earned it.
  final DateTime? unlockedAt;

  /// Pre-formatted unlock date — the caller owns date formatting.
  final String? unlockedLabel;

  bool get _earned => unlockedAt != null;

  @override
  Widget build(BuildContext context) {
    final blocked = !type.isEarnableNow && !_earned;
    final accent = _earned ? AppColors.teal : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _earned
            ? AppColors.teal.withValues(alpha: 0.06)
            : AppColors.card,
        border: Border.all(
          color: _earned
              ? AppColors.teal.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type.icon, size: 22, color: accent),
              const Spacer(),
              if (blocked)
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            type.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _earned ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            type.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.microLabel.copyWith(fontSize: 10),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _earned
                ? (unlockedLabel ?? '')
                // States the blocker rather than implying it's just
                // not done yet.
                : (type.unavailableReason ?? ''),
            style: AppTextStyles.microLabel.copyWith(
              fontSize: 9,
              color: _earned ? AppColors.teal : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
