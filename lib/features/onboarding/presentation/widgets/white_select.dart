import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// The white pill dropdown used throughout onboarding (`.white-select` in
/// the mock). Black text on a white background — high contrast against
/// the otherwise dark UI.
class WhiteSelect extends StatelessWidget {
  const WhiteSelect({
    required this.label,
    required this.onTap,
    super.key,
    this.leading,
    this.hint,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;

  /// If non-null, [label] is rendered in a muted grey (placeholder state).
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final showHint = hint != null && label.isEmpty;
    final displayed = showHint ? hint! : label;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              if (leading != null) ...[
                DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 18),
                  child: leading!,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  displayed,
                  style: AppTextStyles.title.copyWith(
                    color: showHint ? Colors.grey.shade600 : Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '∨', // ∨ — matches the mock chevron glyph
                style: AppTextStyles.title.copyWith(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
