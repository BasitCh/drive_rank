import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Temporary scaffold used during Session 1 (Foundation) so the router has
/// something to render. Each feature replaces this with a real page later.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.sectionTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle!,
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Container(
                  height: 2,
                  width: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.all(Radius.circular(1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
