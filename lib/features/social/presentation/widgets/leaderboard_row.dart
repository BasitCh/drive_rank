import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsRow;
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/presentation/widgets/benchmark_badge.dart';
import 'package:drive_rank/features/social/presentation/widgets/rank_identity.dart';
import 'package:drive_rank/features/social/presentation/widgets/rank_type.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:flutter/material.dart';

/// One row below the podium.
///
/// Three kinds of row, separated by two independent signals so that
/// missing one still leaves the other:
///  * the identity circle holds the driver's own vehicle for a person
///    and a gauge glyph for a benchmark — never an avatar;
///  * the marker beside the name is `YOU`, `BENCHMARK`, `OLD FIGURE`,
///    or absent.
///
/// The viewer's row additionally takes the app's selection promotion
/// (teal fill, teal 1.5px border), the same treatment the paywall uses
/// for the chosen plan — so "this is me" survives even if both labels
/// are missed.
///
/// A benchmark or friend row is tappable and opens the head-to-head; the
/// viewer's own row is not, and shows no affordance, because there is
/// nothing to compare yourself against on it.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    required this.position,
    required this.formattedValue,
    required this.unitLabel,
    this.subtitle,
    this.viewer,
    this.onTap,
    super.key,
  });

  final LeaderboardPosition position;

  /// Pre-formatted by the caller through `LocaleService`, so this widget
  /// never has to know about unit systems.
  final String formattedValue;
  final String unitLabel;

  /// The second line — a real driver's flag, country and car, or the
  /// benchmark's "Pace reference". Omitted when unknown rather than
  /// filled with a placeholder.
  final String? subtitle;

  final UserSettingsRow? viewer;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final entry = position.entry;
    final isMe = entry.isCurrentUser;
    final isBenchmark = entry.isBenchmark;
    // The viewer's country from settings, everyone else's from what they
    // published — never the other way round. A benchmark is from
    // nowhere, so it gets no flag.
    final flag = isBenchmark
        ? null
        : countryFromCode(isMe ? (viewer?.country ?? '') : entry.countryCode)
              ?.flag;

    final row = Container(
      height: 66,
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF16252C) : AppColors.card,
        border: Border.all(
          color: isMe ? AppColors.teal : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // The driver's flag, faded out behind the rank — where they
          // drive, read before their name is.
          // Where the driver is from, faded out behind the rank. A
          // benchmark is from nowhere, so it flies the chequered flag
          // instead — the racing mark for a pace to beat, and never a
          // nationality.
          if (flag != null || isBenchmark)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 92,
              child: _Wash(
                child: isBenchmark
                    ? const _ChequeredFlag()
                    : _EmojiFlag(flag: flag!),
              ),
            ),
          Row(
            children: [
              SizedBox(
                width: 58,
                child: Center(
                  child: Text(
                    '${position.rank}',
                    style: RankType.numeral(
                      size: position.rank >= 100 ? 15 : 21,
                      color: AppColors.textPrimary,
                    ).copyWith(
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
              RankIdentity(entry: entry, diameter: 42, viewer: viewer),
              const SizedBox(width: 12),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: isMe ? 1.2 : 0,
                              color: isMe
                                  ? AppColors.teal
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isBenchmark) ...[
                          const SizedBox(width: 6),
                          const BenchmarkBadge(),
                        ]
                        // Marked on the row, not hidden from it. The value
                        // still ranks — see `StaleBadge`.
                        else if (entry.isStale) ...[
                          const SizedBox(width: 6),
                          const StaleBadge(),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedValue,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: isBenchmark
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      unitLabel.toLowerCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final tap = onTap;
    if (tap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(16),
        child: row,
      ),
    );
  }
}

/// Fades whatever flag sits behind a row's rank out to the right.
class _Wash extends StatelessWidget {
  const _Wash({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0x99FFFFFF), Color(0x73FFFFFF), Color(0x00FFFFFF)],
        // Fully faded well inside the wash, so the flag's own edge never
        // shows as a line.
        stops: [0, 0.35, 0.8],
      ).createShader(bounds),
      child: ClipRect(child: child),
    );
  }
}

/// A country flag from its emoji, blown up and cropped.
class _EmojiFlag extends StatelessWidget {
  const _EmojiFlag({required this.flag});

  final String flag;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.scale(
        // An emoji flag is drawn with rounded corners and a waving edge.
        // Blown up well past the row and cropped, only its colours remain
        // — a solid wash, like a printed flag.
        scale: 2.2,
        child: Text(flag, style: const TextStyle(fontSize: 60, height: 1)),
      ),
    );
  }
}

/// The chequered racing flag, tilted as if flown.
class _ChequeredFlag extends StatelessWidget {
  const _ChequeredFlag();

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: 160,
      maxHeight: 160,
      child: Transform.rotate(
        angle: -0.2,
        child: const CustomPaint(
          size: Size(160, 160),
          painter: _ChequerPainter(),
        ),
      ),
    );
  }
}

class _ChequerPainter extends CustomPainter {
  const _ChequerPainter();

  static const double _square = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFF2F2F7);
    final dark = Paint()..color = const Color(0xFF26262E);
    final columns = (size.width / _square).ceil();
    final rows = (size.height / _square).ceil();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * _square, r * _square, _square, _square),
          (r + c).isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChequerPainter oldDelegate) => false;
}
