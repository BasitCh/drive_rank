import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:flutter/material.dart';

/// Bottom sheet shown the first time a known-killer OEM device starts
/// a trip. Explains *why* the system might terminate the foreground
/// service and points the user at the battery whitelist.
///
/// We don't try to deep-link to the manufacturer-specific battery
/// page (every OEM names it differently); the Open Settings button
/// drops them into DriveRank's app settings, which on every modern
/// Android exposes a Battery row one tap away.
class OemBatteryAdviceSheet extends StatelessWidget {
  const OemBatteryAdviceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg2,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const OemBatteryAdviceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.battery_alert_rounded,
                    color: AppColors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Keep DriveRank running in the background',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Your phone\'s battery saver can close DriveRank while the '
              'screen is off — that ends long trips early. Set DriveRank '
              'to "no restrictions" or "allow background activity" so '
              'every drive is recorded fully.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'In Settings: Apps → DriveRank → Battery → Unrestricted.',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                color: AppColors.teal,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () async {
                  await getIt<PermissionService>().openSettings();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'I\'ll do this later',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
