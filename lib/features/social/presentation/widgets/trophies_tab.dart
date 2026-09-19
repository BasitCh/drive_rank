import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/presentation/widgets/trophy_tile.dart';
import 'package:flutter/material.dart';

/// Every trophy, earned or not.
///
/// Shows the whole set rather than only what's been unlocked, because a
/// trophy case you can't see the shape of gives you nothing to aim at.
/// Earned ones come first; the rest keep their order so the list is
/// stable as they're unlocked.
///
/// Rows of two, following the Personal Bests grid rhythm — the tiles
/// carry a title and a description, so three across would truncate both.
class TrophiesTab extends StatelessWidget {
  const TrophiesTab({
    required this.trophies,
    required this.formatUnlockedAt,
    super.key,
  });

  /// What the user has actually unlocked.
  final List<Trophy> trophies;

  /// Formats an unlock date — the caller owns date formatting.
  final String Function(DateTime) formatUnlockedAt;

  @override
  Widget build(BuildContext context) {
    final earnedAt = <TrophyType, DateTime>{};
    for (final trophy in trophies) {
      final existing = earnedAt[trophy.type];
      // Keep the first time it was earned; a repeatable trophy can have
      // several rows and the original unlock is the interesting one.
      if (existing == null || trophy.unlockedAt.isBefore(existing)) {
        earnedAt[trophy.type] = trophy.unlockedAt;
      }
    }

    final ordered = [
      ...TrophyType.values.where(earnedAt.containsKey),
      ...TrophyType.values.where((t) => !earnedAt.containsKey(t)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      children: [
        for (var i = 0; i < ordered.length; i += 2) ...[
          // IntrinsicHeight, not a bare stretch: inside a ListView the
          // row's vertical extent is unbounded, and stretching against
          // that fails layout outright — the grid rendered blank on
          // device. This gives the row a real height first, so the two
          // tiles can then match it.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _tileFor(ordered[i], earnedAt)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: i + 1 < ordered.length
                      ? _tileFor(ordered[i + 1], earnedAt)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _tileFor(TrophyType type, Map<TrophyType, DateTime> earnedAt) {
    final unlocked = earnedAt[type];
    return TrophyTile(
      type: type,
      unlockedAt: unlocked,
      unlockedLabel: unlocked == null ? null : formatUnlockedAt(unlocked),
    );
  }
}
