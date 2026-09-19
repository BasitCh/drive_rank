import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsRow;
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/presentation/widgets/benchmark_badge.dart';
import 'package:drive_rank/features/social/presentation/widgets/rank_identity.dart';
import 'package:drive_rank/features/social/presentation/widgets/rank_type.dart';
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
    this.onCompare,
    super.key,
  });

  /// The board's leading positions, best first. Fewer than three is
  /// handled — an early board can legitimately have one.
  final List<LeaderboardPosition> positions;

  final String Function(double) formatValue;
  final String Function(double) unitFor;
  final UserSettingsRow? viewer;

  /// Opens the head-to-head. Wired for everyone but the viewer — their
  /// own tile stays inert, because comparing yourself with yourself goes
  /// nowhere.
  final void Function(LeaderboardEntry entry)? onCompare;

  /// Fixed heights for the block above each plinth.
  ///
  /// Without these the tiles are bottom-aligned by content, so a tile
  /// without a `BENCHMARK` badge (the viewer's) ends up shorter and its
  /// circle floats higher than its neighbours' — which read as a
  /// jumbled podium rather than a stepped one. Pinning the head height
  /// per tier means the *only* thing that varies between places is the
  /// plinth, which is exactly the effect a podium wants.
  static const double _leadHeadHeight = 210;
  static const double _sideHeadHeight = 164;

  /// Medal colours, shared by each place's ring and its plinth.
  ///
  /// The plinths were already gold/silver/bronze while every head wore
  /// the same grey ring, which is what made the podium read flat: the
  /// places were distinguishable only by height. One colour per place,
  /// carried by both parts of the tile.
  static const Color _gold = MedalColors.gold;
  static const Color _silver = MedalColors.silver;
  static const Color _bronze = MedalColors.bronze;

  VoidCallback? _tapFor(LeaderboardPosition position) {
    final compare = onCompare;
    if (compare == null || position.entry.isCurrentUser) return null;
    return () => compare(position.entry);
  }

  @override
  Widget build(BuildContext context) {
    final first = positions.isNotEmpty ? positions[0] : null;
    final second = positions.length > 1 ? positions[1] : null;
    final third = positions.length > 2 ? positions[2] : null;
    if (first == null) return const SizedBox.shrink();
    // The label slot under each name is kept for all three places when
    // any of them has a label, so the circles stay level — and dropped
    // when none does, so the figure sits right under the name.
    final reserveBadge = [
      first,
      ?second,
      ?third,
    ].any((p) => p.entry.isBenchmark || p.entry.isStale);
    final sideHead = reserveBadge ? _sideHeadHeight : _sideHeadHeight - 19;
    final leadHead = reserveBadge ? _leadHeadHeight : _leadHeadHeight - 19;

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
                    onTap: _tapFor(second),
                    formatValue: formatValue,
                    unitFor: unitFor,
                    viewer: viewer,
                    diameter: 68,
                    headHeight: sideHead,
                    reserveBadge: reserveBadge,
                    plinthHeight: 72,
                    plinthColor: _silver.withValues(alpha: 0.10),
                    plinthBorder: _silver.withValues(alpha: 0.30),
                    rankColor: _silver,
                    medal: _silver,
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _PodiumTile(
              position: first,
              onTap: _tapFor(first),
              formatValue: formatValue,
              unitFor: unitFor,
              viewer: viewer,
              diameter: 88,
              headHeight: leadHead,
              reserveBadge: reserveBadge,
              plinthHeight: 104,
              plinthColor: _gold.withValues(alpha: 0.16),
              plinthBorder: _gold.withValues(alpha: 0.45),
              rankColor: _gold,
              medal: _gold,
              showTrophy: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: third == null
                ? const SizedBox.shrink()
                : _PodiumTile(
                    position: third,
                    onTap: _tapFor(third),
                    formatValue: formatValue,
                    unitFor: unitFor,
                    viewer: viewer,
                    diameter: 68,
                    headHeight: sideHead,
                    reserveBadge: reserveBadge,
                    plinthHeight: 54,
                    plinthColor: _bronze.withValues(alpha: 0.14),
                    plinthBorder: _bronze.withValues(alpha: 0.40),
                    rankColor: _bronze,
                    medal: _bronze,
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
    required this.medal,
    required this.reserveBadge,
    this.viewer,
    this.onTap,
    this.showTrophy = false,
  });

  /// Whether to keep the label slot under the name — see the podium.
  final bool reserveBadge;

  final LeaderboardPosition position;
  final String Function(double) formatValue;
  final String Function(double) unitFor;
  final double diameter;
  final double headHeight;
  final double plinthHeight;
  final Color plinthColor;
  final Color plinthBorder;
  final Color rankColor;
  final Color medal;
  final UserSettingsRow? viewer;

  /// Opens the compare sheet. Null for the viewer's own tile — there is
  /// nothing to compare yourself against on it.
  final VoidCallback? onTap;
  final bool showTrophy;

  @override
  Widget build(BuildContext context) {
    final entry = position.entry;
    final tile = Column(
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
                    size: 28,
                    // Muted while a benchmark holds the top spot — nobody has
                    // won a board whose leader never drove anywhere.
                    color: entry.isBenchmark
                        ? AppColors.textTertiary
                        : MedalColors.gold,
                  ),
                ),
              RankIdentity(
                entry: entry,
                diameter: diameter,
                viewer: viewer,
                ringColor: medal,
                ringWidth: 3,
                showFlag: entry.isCurrentUser || entry.countryCode.isNotEmpty,
              ),
              const SizedBox(height: 8),
              Text(
                entry.isCurrentUser ? 'YOU' : entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: showTrophy ? 17 : 15,
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
              if (reserveBadge)
                SizedBox(
                  height: 19,
                  child: entry.isBenchmark
                      ? const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: BenchmarkBadge(),
                        )
                      : entry.isStale
                      ? const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: StaleBadge(),
                        )
                      : null,
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // In the place's own colour, as the reference board
                  // does: the figure belongs to the medal, not the name.
                  Text(
                    formatValue(entry.value),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: showTrophy ? 20 : 16,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: entry.isBenchmark
                          ? medal.withValues(alpha: 0.7)
                          : medal,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    unitFor(entry.value).toLowerCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: showTrophy ? 13 : 11,
                      fontWeight: FontWeight.w600,
                      color: medal.withValues(alpha: 0.8),
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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [plinthColor, plinthColor.withValues(alpha: 0.02)],
            ),
            border: Border.all(color: plinthBorder, width: 1.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          alignment: Alignment.center,
          child: Text(
            '${position.rank}',
            style: RankType.numeral(
              size: showTrophy ? 40 : 30,
              color: rankColor,
            ),
          ),
        ),
      ],
    );

    final tap = onTap;
    if (tap == null) return tile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: tile,
      ),
    );
  }
}
