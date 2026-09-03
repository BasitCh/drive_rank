import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// A horizontally-scrolling row of selectable pills.
///
/// The generic sibling of History's `FilterPills` — same `Material` +
/// `StadiumBorder` treatment and the same solid-teal-when-active
/// inversion, but typed over any value so the metric and period
/// selectors are two instances of one widget rather than two
/// near-identical copies.
class RankingPills<T> extends StatelessWidget {
  const RankingPills({
    required this.items,
    required this.active,
    required this.onChanged,
    super.key,
  });

  final List<(T, String)> items;
  final T active;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final (value, label) = items[i];
          final isOn = value == active;
          return Material(
            color: isOn ? AppColors.teal : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: isOn ? AppColors.teal : AppColors.border2,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onChanged(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.microLabel.copyWith(
                    fontSize: 12,
                    color: isOn ? AppColors.bg : AppColors.textSecondary,
                    fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
