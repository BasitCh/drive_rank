import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/leaderboard_entry.dart';
import 'package:flutter/material.dart';

/// Top-3 podium: silver (left) / gold (center, tallest) / bronze (right).
/// Renders `null` slots gracefully when the leaderboard has fewer than 3
/// entries — empty pedestal with placeholder copy.
class Podium extends StatelessWidget {
  const Podium({
    required this.first,
    required this.second,
    required this.third,
    required this.locale,
    super.key,
  });

  final LeaderboardEntry? first;
  final LeaderboardEntry? second;
  final LeaderboardEntry? third;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _Pillar(
              entry: second,
              locale: locale,
              tier: _Tier.silver,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Pillar(entry: first, locale: locale, tier: _Tier.gold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Pillar(
              entry: third,
              locale: locale,
              tier: _Tier.bronze,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Tier { gold, silver, bronze }

class _Pillar extends StatelessWidget {
  const _Pillar({
    required this.entry,
    required this.locale,
    required this.tier,
  });

  final LeaderboardEntry? entry;
  final LocaleService locale;
  final _Tier tier;

  @override
  Widget build(BuildContext context) {
    final (avatarBg, avatarFg, pillarBg, pillarFg, height, place) =
        switch (tier) {
          _Tier.gold => (
            AppColors.yellow,
            AppColors.bg,
            AppColors.yellow,
            AppColors.bg,
            52.0,
            '1',
          ),
          _Tier.silver => (
            AppColors.card2,
            AppColors.textSecondary,
            AppColors.card2,
            AppColors.textSecondary,
            38.0,
            '2',
          ),
          _Tier.bronze => (
            AppColors.card,
            AppColors.textTertiary,
            AppColors.card,
            AppColors.textTertiary,
            28.0,
            '3',
          ),
        };

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _Avatar(
          initials: entry == null
              ? '—'
              : _initials(entry!.username),
          bg: avatarBg,
          fg: avatarFg,
          isGold: tier == _Tier.gold,
        ),
        const SizedBox(height: 5),
        Text(
          entry?.username ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.microLabel.copyWith(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          entry == null ? '—' : locale.formatSpeed(entry!.topSpeedKmh),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: pillarBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            place,
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 18,
              color: pillarFg,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String username) {
    if (username.isEmpty) return '?';
    final cleaned = username.replaceAll(RegExp('[^a-zA-Z]'), '');
    if (cleaned.length >= 2) {
      return cleaned.substring(0, 2).toUpperCase();
    }
    return cleaned.toUpperCase().padRight(2, '?');
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.bg,
    required this.fg,
    required this.isGold,
  });

  final String initials;
  final Color bg;
  final Color fg;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isGold
            ? const LinearGradient(
                colors: [AppColors.yellow, Color(0xFFD4A017)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isGold ? null : bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
