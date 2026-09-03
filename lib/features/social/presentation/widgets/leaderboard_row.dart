import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/presentation/widgets/benchmark_badge.dart';
import 'package:flutter/material.dart';

/// One row of the leaderboard.
///
/// Layout mirrors `TripListItem` — a 48×40 leading slot, the name and a
/// marker, then the value right-aligned in BebasNeue — so the rankings
/// list reads as the same kind of list as History rather than a new
/// species of row.
///
/// Two independent signals separate the three kinds of row, so no single
/// missed detail can make a benchmark look like a person:
///  * the leading slot holds a rank number for people and a target glyph
///    for benchmarks;
///  * the marker under the name is `YOU`, `BENCHMARK`, or absent.
///
/// The viewer's own row additionally gets the app's selection promotion
/// (teal 5% fill, teal border at 1.5px), the same treatment the paywall
/// uses for the chosen plan.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    required this.position,
    required this.formattedValue,
    required this.unitLabel,
    super.key,
  });

  final LeaderboardPosition position;

  /// Pre-formatted by the caller through `LocaleService`, so this widget
  /// never has to know about unit systems.
  final String formattedValue;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final entry = position.entry;
    final isMe = entry.isCurrentUser;
    final isBenchmark = entry.isBenchmark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: isMe ? AppColors.teal.withValues(alpha: 0.05) : AppColors.card,
        border: Border.all(
          color: isMe ? AppColors.teal : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 40,
            child: Center(
              child: isBenchmark
                  ? const Icon(
                      // Not an avatar — a benchmark has no face because
                      // it isn't a person.
                      Icons.adjust_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    )
                  : Text(
                      '${AppStrings.rankingsRankPrefix}${position.rank}',
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 22,
                        height: 1,
                        color: AppColors.yellow,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isMe || isBenchmark) ...[
                  const SizedBox(height: 4),
                  if (isBenchmark)
                    const BenchmarkBadge()
                  else
                    const YouBadge(),
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
                style: AppTextStyles.microLabel.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
