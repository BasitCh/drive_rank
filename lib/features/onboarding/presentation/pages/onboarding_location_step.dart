import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 8 — Prominent Disclosure for background location.
///
/// Required by the Google Play User Data policy: the in-app surface must
/// explain the type of data, the feature using it, and the fact that
/// access continues in the background before any system permission
/// prompt fires. Don't reorder steps so this lands after the safety
/// reminders but before the welcome — keeping it last means a user who
/// quits mid-onboarding hasn't been asked yet (we re-prompt on first
/// Start in that case).
class OnboardingLocationStep extends StatefulWidget {
  const OnboardingLocationStep({super.key});

  @override
  State<OnboardingLocationStep> createState() => _OnboardingLocationStepState();
}

class _OnboardingLocationStepState extends State<OnboardingLocationStep>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Once the OS permission or location toggle is "stuck", the only way
  // out is the Settings app — and the system permission dialog never
  // fires again for `deniedForever`, so nothing else re-checks the
  // status for us. Without this, a user who grants location from
  // Settings and switches back sees the exact same "stuck" screen they
  // left, because nothing ever re-reads the OS state. Re-request on
  // resume so a real fix (permission granted, GPS re-enabled) is
  // picked up immediately — `_onRequestPermission` in the bloc already
  // no-ops the system dialog when the status isn't a plain "denied",
  // and auto-advances on grant.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<OnboardingBloc>().add(
        const OnboardingLocationPermissionRequested(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (a, b) => a.locationStatus != b.locationStatus,
      builder: (context, state) {
        final servicesOff =
            state.locationStatus == LocationPermissionStatus.servicesDisabled;
        final deniedForever =
            state.locationStatus == LocationPermissionStatus.deniedForever;
        final denied =
            servicesOff ||
            deniedForever ||
            state.locationStatus == LocationPermissionStatus.denied;
        // Once the OS won't show its own prompt again (deniedForever) or
        // there's nothing to prompt for (the location toggle itself is
        // off), the CTA has to route to Settings instead of re-asking.
        final needsSettings = servicesOff || deniedForever;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    const Center(
                      child: Text('📍', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        AppStrings.locationDisclosureTitle,
                        style: AppTextStyles.headingLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        AppStrings.locationDisclosureSub,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _DisclosureItem(
                      emoji: '🛣',
                      text: AppStrings.locationDisclosureItem1,
                    ),
                    const _DisclosureItem(
                      emoji: '🔋',
                      text: AppStrings.locationDisclosureItem2,
                    ),
                    const _DisclosureItem(
                      emoji: '🔒',
                      text: AppStrings.locationDisclosureItem3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.locationDisclosureRevoke,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (denied) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          servicesOff
                              ? AppStrings.locationDisclosureServicesOffHelp
                              : AppStrings.locationDisclosureDeniedHelp,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.red,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            TealButton(
              label: needsSettings
                  ? AppStrings.locationDisclosureOpenSettingsCta
                  : AppStrings.locationDisclosureCta,
              enabled: true,
              onPressed: () => _onCtaPressed(
                context,
                servicesOff: servicesOff,
                deniedForever: deniedForever,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<OnboardingBloc>().add(
                const OnboardingStepNext(),
              ),
              child: const Text(
                AppStrings.locationDisclosureSkip,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onCtaPressed(
    BuildContext context, {
    required bool servicesOff,
    required bool deniedForever,
  }) async {
    // Neither case has an in-app prompt left to show — Settings is the
    // only place that can fix them (see `didChangeAppLifecycleState`
    // above for how we notice when the user comes back).
    if (servicesOff) {
      await getIt<PermissionService>().openLocationSettings();
      return;
    }
    if (deniedForever) {
      await getIt<PermissionService>().openSettings();
      return;
    }
    if (!context.mounted) return;
    context.read<OnboardingBloc>().add(
      const OnboardingLocationPermissionRequested(),
    );
  }
}

class _DisclosureItem extends StatelessWidget {
  const _DisclosureItem({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
