import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsRow;
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/presentation/widgets/benchmark_badge.dart';
import 'package:drive_rank/features/social/presentation/widgets/rank_identity.dart';
import 'package:flutter/material.dart';

/// The top three, as a podium.
///
/// This is what makes the screen read as a competition rather than a
/// table: you understand the standings before reading a single number,
/// and first place is visibly worth more than second.
///
/// The trophy above first place is **gold only when a real driver holds
/// it**. While a benchmark is top of the board nobody has actually won
/// anything, so the trophy renders muted — the podium still frames the
/// target without staging a victory that didn't happen.
class TopThreePodium extends StatelessWidget {
  const TopThreePodium({
    required this.positions,
    required this.formatValue,
    required this.unitFor,
    this.viewer,
    super.key,
  });

  /// The board's leading positions, best first. Fewer than three is
  /// handled — an early board can legitimately have one.
  final List<LeaderboardPosition> positions;

  final String Function(double) formatValue;
  final String Function(double) unitFor;
  final UserSettingsRow? viewer;

  /// Fixed heights for the block above each plinth.
  ///
  /// Without these the tiles are bottom-aligned by content, so a tile
  /// without a `BENCHMARK` badge (the viewer's) ends up shorter and its
  /// circle floats higher than its neighbours' — which read as a
  /// jumbled podium rather than a stepped one. Pinning the head height
  /// per tier means the *only* thing that varies between places is the
  /// plinth, which is exactly the effect a podium wants.
  static const double _leadHeadHeight = 186;
  static const double _sideHeadHeight = 150;

  @override
  Widget build(BuildContext context) {
    final first = positions.isNotEmpty ? positions[0] : null;
    final second = positions.length > 1 ? positions[1] : null;
    final third = positions.length > 2 ? positions[2] : null;
    if (first == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second == null
                ? const SizedBox.shrink()
                : _PodiumTile(
                    position: second,
                    formatValue: formatValue,
                    unitFor: unitFor,
                    viewer: viewer,
                    diameter: 60,
                    headHeight: _sideHeadHeight,
                    plinthHeight: 58,
                    plinthColor: AppColors.card2,
                    plinthBorder: AppColors.border2,
                    rankColor: AppColors.textSecondary,
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _PodiumTile(
              position: first,
              formatValue: formatValue,
              unitFor: unitFor,
              viewer: viewer,
              diameter: 78,
              headHeight: _leadHeadHeight,
              plinthHeight: 84,
              plinthColor: AppColors.yellow.withValues(alpha: 0.08),
              plinthBorder: AppColors.yellow.withValues(alpha: 0.25),
              rankColor: AppColors.yellow,
              showTrophy: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: third == null
                ? const SizedBox.shrink()
                : _PodiumTile(
                    position: third,
                    formatValue: formatValue,
                    unitFor: unitFor,
                    viewer: viewer,
                    diameter: 60,
                    headHeight: _sideHeadHeight,
                    plinthHeight: 40,
                    plinthColor: AppColors.orange.withValues(alpha: 0.08),
                    plinthBorder: AppColors.orange.withValues(alpha: 0.25),
                    rankColor: AppColors.orange,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  const _PodiumTile({
    required this.position,
    required this.formatValue,
    required this.unitFor,
    required this.diameter,
    required this.headHeight,
    required this.plinthHeight,
    required this.plinthColor,
    required this.plinthBorder,
    required this.rankColor,
    this.viewer,
    this.showTrophy = false,
  });

  final LeaderboardPosition position;
  final String Function(double) formatValue;
  final String Function(double) unitFor;
  final double diameter;
  final double headHeight;
  final double plinthHeight;
  final Color plinthColor;
  final Color plinthBorder;
  final Color rankColor;
  final UserSettingsRow? viewer;
  final bool showTrophy;

  @override
  Widget build(BuildContext context) {
    final entry = position.entry;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: headHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showTrophy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 22,
                    // Muted while a benchmark holds the top spot — nobody has
                    // won a board whose leader never drove anywhere.
                    color: entry.isBenchmark
                        ? AppColors.textTertiary
                        : AppColors.yellow,
                  ),
                ),
              RankIdentity(entry: entry, diameter: diameter, viewer: viewer),
              const SizedBox(height: 6),
              Text(
                entry.isCurrentUser ? 'YOU' : entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: showTrophy ? 14 : 13,
                  fontWeight: FontWeight.w700,
                  color: entry.isCurrentUser
                      ? AppColors.teal
                      : AppColors.textPrimary,
                ),
              ),
              // The badge slot is reserved whether or not there's a
              // badge in it. Collapsing it on the viewer's tile made
              // their circle sit lower than its neighbours', which read
              // as a misaligned podium rather than a stepped one — the
              // only thing that should differ between places is the
              // plinth.
              SizedBox(
                height: 19,
                child: entry.isBenchmark
                    ? const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: BenchmarkBadge(),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatValue(entry.value),
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: showTrophy ? 26 : 22,
                      height: 1,
                      color: entry.isBenchmark
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      unitFor(entry.value),
                      style: AppTextStyles.microLabel.copyWith(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: plinthHeight,
          decoration: BoxDecoration(
            color: plinthColor,
            border: Border.all(color: plinthBorder),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSm),
            ),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${position.rank}',
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: showTrophy ? 30 : 24,
              height: 1,
              color: rankColor,
            ),
          ),
        ),
      ],
    );
  }
}
