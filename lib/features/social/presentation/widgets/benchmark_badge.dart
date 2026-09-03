import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// The `BENCHMARK` label.
///
/// Its own widget so the treatment has exactly one definition — a
/// benchmark that shows up unlabelled anywhere is the one failure mode
/// this whole design exists to prevent.
///
/// Uses the app's established tinted-pill formula (fill at 10%, border
/// at 20%, radius 20, mono caps) — the same shape as the rank badge on
/// the shareable card, the LIVE pill and the g-force badge. Rendered in
/// `textTertiary` rather than an accent colour so a benchmark reads as
/// neutral furniture: it's a target, not an achievement, and colouring
/// it like one would make it compete for attention with the viewer's own
/// row.
class BenchmarkBadge extends StatelessWidget {
  const BenchmarkBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.1),
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        AppStrings.leaderboardBenchmark,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// The `YOU` label — the counterpart marker on the viewer's own row.
///
/// Same geometry as [BenchmarkBadge] but in teal, so the two read as
/// siblings that are unmistakably not the same thing. The row itself is
/// also promoted (teal fill and border), so "this is me" survives even
/// if the label is missed.
class YouBadge extends StatelessWidget {
  const YouBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        AppStrings.leaderboardYou,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.teal,
        ),
      ),
    );
  }
}
