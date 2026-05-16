import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/leaderboard_entry.dart';
import 'package:flutter/material.dart';

/// One row in the leaderboard list (ranks 4+ — top 3 live in the podium).
/// The user's own row is highlighted with a teal border and a YOU tag.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    required this.entry,
    required this.locale,
    super.key,
  });

  final LeaderboardEntry entry;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final isYou = entry.isYou;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isYou
            ? AppColors.teal.withValues(alpha: 0.04)
            : AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isYou
              ? AppColors.teal.withValues(alpha: 0.2)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              entry.rank.toString(),
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 14,
                color: isYou ? AppColors.teal : AppColors.textTertiary,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isYou
                  ? AppColors.teal.withValues(alpha: 0.1)
                  : AppColors.card2,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(entry.username),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isYou ? AppColors.teal : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isYou) ...[
                  const SizedBox(width: 6),
                  _YouTag(),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                locale.formatSpeedValue(entry.topSpeedKmh),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isYou ? AppColors.teal : AppColors.textPrimary,
                ),
              ),
              Text(
                locale.speedUnitLabel,
                style: AppTextStyles.microLabel.copyWith(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String username) {
    final cleaned = username.replaceAll(RegExp('[^a-zA-Z]'), '');
    if (cleaned.length >= 2) return cleaned.substring(0, 2).toUpperCase();
    if (cleaned.isEmpty) return '?';
    return cleaned.toUpperCase().padRight(2, '?');
  }
}

class _YouTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        AppStrings.leaderboardYou,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 8,
          color: AppColors.bg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
