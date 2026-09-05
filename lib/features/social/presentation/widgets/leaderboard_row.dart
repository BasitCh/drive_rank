import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsRow;
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/presentation/widgets/benchmark_badge.dart';
import 'package:drive_rank/features/social/presentation/widgets/rank_identity.dart';
import 'package:flutter/material.dart';

/// One row below the podium.
///
/// Three kinds of row, separated by two independent signals so that
/// missing one still leaves the other:
///  * the identity circle holds the driver's own vehicle for a person
///    and a gauge glyph for a benchmark — never an avatar;
///  * the marker beside the name is `YOU`, `BENCHMARK`, or absent.
///
/// The viewer's row additionally takes the app's selection promotion
/// (teal fill, teal 1.5px border), the same treatment the paywall uses
/// for the chosen plan — so "this is me" survives even if both labels
/// are missed.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    required this.position,
    required this.formattedValue,
    required this.unitLabel,
    this.subtitle,
    this.viewer,
    super.key,
  });

  final LeaderboardPosition position;

  /// Pre-formatted by the caller through `LocaleService`, so this widget
  /// never has to know about unit systems.
  final String formattedValue;
  final String unitLabel;

  /// The second line — a real driver's car and country, or the
  /// benchmark's "Pace reference". Omitted when unknown rather than
  /// filled with a placeholder.
  final String? subtitle;

  final UserSettingsRow? viewer;

  @override
  Widget build(BuildContext context) {
    final entry = position.entry;
    final isMe = entry.isCurrentUser;
    final isBenchmark = entry.isBenchmark;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.teal.withValues(alpha: 0.06) : AppColors.card,
        border: Border.all(
          color: isMe ? AppColors.teal : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${position.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 22,
                height: 1,
                color: isMe ? AppColors.teal : AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          RankIdentity(entry: entry, diameter: 40, viewer: viewer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? AppStrings.leaderboardYou : entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isMe ? AppColors.teal : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isBenchmark) ...[
                      const SizedBox(width: 6),
                      const BenchmarkBadge(),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.microLabel.copyWith(fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedValue,
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 25,
                  height: 1,
                  color: isBenchmark
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                unitLabel,
                style: AppTextStyles.microLabel.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
