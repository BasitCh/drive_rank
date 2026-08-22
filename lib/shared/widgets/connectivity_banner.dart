import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/network/network_info.dart';
import 'package:flutter/material.dart';

/// Thin banner shown at the top of the main shell whenever the device
/// has no network connectivity, and automatically hidden the instant it
/// comes back — reactive to `NetworkInfo.connectivityChanges`.
///
/// Assumes online on the very first frame (rather than flashing a scary
/// banner on every cold boot before the stream's first event arrives) —
/// `NetworkInfo.connectivityChanges` corrects this within a beat if the
/// device is actually offline.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final network = getIt<NetworkInfo>();
    return StreamBuilder<bool>(
      initialData: true,
      stream: network.connectivityChanges,
      builder: (context, snapshot) {
        final online = snapshot.data ?? true;
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: online
              ? const SizedBox(width: double.infinity)
              : const _OfflineBar(),
        );
      },
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    // The safe-area top inset belongs here, not on ConnectivityBanner
    // itself — every page already applies its own SafeArea, so reserving
    // it unconditionally at the shell level double-pads every screen's
    // top content even while this bar is hidden (0-height).
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        color: AppColors.orange,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 14, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              AppStrings.errorNoInternet,
              textAlign: TextAlign.center,
              style: AppTextStyles.microLabel.copyWith(
                color: Colors.black,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
