import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/history/presentation/bloc/history_bloc.dart';
import 'package:flutter/material.dart';

/// Horizontal row of filter pills above the trip list: All | This Week |
/// Night Drives | Personal Best.
class FilterPills extends StatelessWidget {
  const FilterPills({required this.active, required this.onChanged, super.key});

  final TripFilter active;
  final ValueChanged<TripFilter> onChanged;

  static const _items = <(TripFilter, String)>[
    (TripFilter.all, AppStrings.historyFilterAll),
    (TripFilter.thisWeek, AppStrings.historyFilterWeek),
    (TripFilter.night, AppStrings.historyFilterNight),
    (TripFilter.best, AppStrings.historyFilterBest),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final (filter, label) = _items[i];
          final isOn = filter == active;
          return Material(
            color: isOn ? AppColors.teal : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: isOn ? AppColors.teal : AppColors.border2,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onChanged(filter),
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
