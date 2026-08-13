import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Top-of-screen chrome shown on onboarding steps 2-7: a `‹` back chevron
/// and a thin teal progress bar that fills 20% → 95% across the flow.
class ProgressChrome extends StatelessWidget {
  const ProgressChrome({
    required this.progress,
    required this.onBack,
    super.key,
  });

  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 32,
          child: onBack == null
              ? null
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBack,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
