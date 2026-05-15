import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Full-width pill button — the recurring "Continue / Next / Continue →"
/// CTA at the bottom of every onboarding screen.
class TealButton extends StatelessWidget {
  const TealButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFF333333) : AppColors.teal,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: disabled
                      ? const Color(0xFF666666)
                      : AppColors.bg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
