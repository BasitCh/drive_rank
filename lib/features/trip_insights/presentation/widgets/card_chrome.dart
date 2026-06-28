import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page chrome bar shared by Performance + Journey share pages.
///
/// Back button on the left, page title centred, Share CTA on the right.
/// Kept thin so the share card below has room to breathe — the chrome
/// is what the user sees, the card is what they screenshot.
class CardChromeBar extends StatelessWidget {
  const CardChromeBar({
    required this.title,
    required this.shareLabel,
    required this.isSharing,
    required this.onShare,
    super.key,
  });

  final String title;
  final String shareLabel;
  final bool isSharing;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          _CircleButton(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _ShareButton(
            label: shareLabel,
            isSharing: isSharing,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 30, height: 30, child: Center(child: child)),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.label,
    required this.isSharing,
    required this.onTap,
  });

  final String label;
  final bool isSharing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: isSharing ? null : onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSharing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: AppColors.bg,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.bg,
                  size: 14,
                ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
