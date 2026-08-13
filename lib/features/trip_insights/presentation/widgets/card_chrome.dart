import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page chrome bar shared by Performance + Journey share pages.
///
/// Back button on the left, page title centred, Share CTA on the right.
/// The chrome is what the user sees, the card is what they screenshot.
///
/// Back-button reliability notes (the previous three patches did not
/// fix this — the issue was the tap target, not pop semantics):
///   • Visible chip stays 36 dp so the chrome doesn't get visually
///     bulkier, but the tappable area is a 48×48 dp box (Material's
///     accessibility floor). The 30-dp box in v1.1.0–v1.1.4 was
///     smaller than a fingertip on high-DPI Android and tap events
///     were physically missing it.
///   • Tap action goes through `Navigator.maybePop(context)` — the
///     underlying primitive both go_router and the Android system
///     back gesture funnel through. No fall-back to `context.go(...)`
///     because the only callers push these pages from Trip Summary,
///     so the route stack always has a previous entry to pop to.
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _CircleButton(
            tooltip: 'Back',
            onTap: () async {
              // maybePop returns false instead of throwing if the
              // route stack is somehow empty — the only callers always
              // push, so this is purely defensive.
              final popped = await Navigator.of(context).maybePop();
              if (!popped && context.mounted) {
                context.go('/home');
              }
            },
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 22,
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
          _ShareButton(label: shareLabel, isSharing: isSharing, onTap: onShare),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
  });

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;

  /// Material spec: minimum touch target is 48×48 dp. The visible
  /// pill chip stays 36 dp; the InkWell+SizedBox sits on a 48 dp
  /// square so taps anywhere in that neighbourhood land.
  static const double _hitSize = 48;
  static const double _visualSize = 36;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: _hitSize,
        height: _hitSize,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Container(
                width: _visualSize,
                height: _visualSize,
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.border),
                  ),
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
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
