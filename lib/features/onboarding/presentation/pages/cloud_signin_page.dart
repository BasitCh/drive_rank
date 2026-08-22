import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/network/network_info.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:drive_rank/shared/services/cloud_sign_in_flow.dart';
import 'package:drive_rank/shared/widgets/offline_state.dart';
import 'package:flutter/material.dart';

/// Skippable "back up your data" prompt shown once, right after
/// onboarding completes. A full page rather than a bottom sheet, styled
/// to match every other onboarding step (black background, same padding/
/// typography, the same `TealButton` CTA) — reuses `performCloudSignIn`,
/// the exact same sequence the Settings entry point uses for existing
/// users, so there's only one place the sign-in/restore logic lives.
///
/// Never blocks progression to the home screen: cancelled, failed, and
/// "Not now" all just pop back (the caller navigates home regardless).
Future<void> pushCloudSignInPage(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const CloudSignInPage()),
  );
}

class CloudSignInPage extends StatefulWidget {
  const CloudSignInPage({super.key});

  @override
  State<CloudSignInPage> createState() => _CloudSignInPageState();
}

enum _Phase { prompt, working, done }

class _CloudSignInPageState extends State<CloudSignInPage> {
  _Phase _phase = _Phase.prompt;
  int _tripsRestored = 0;

  Future<void> _continue() async {
    setState(() => _phase = _Phase.working);
    final result = await performCloudSignIn();
    if (!mounted) return;
    if (result.outcome != CloudSignInOutcome.success) {
      // Cancelled or failed — this is a soft prompt, just leave quietly.
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _phase = _Phase.done;
      _tripsRestored = result.tripsRestored;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.of(context).pop();
  }

  void _skip() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _phase == _Phase.prompt,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: StreamBuilder<bool>(
              initialData: true,
              stream: getIt<NetworkInfo>().connectivityChanges,
              builder: (context, snapshot) {
                // Only the prompt phase cares about connectivity — once
                // sign-in is actually in flight or done, a mid-flight
                // drop is handled by performCloudSignIn's own failure
                // path, not by swapping this screen's content out from
                // under it.
                final offline =
                    !(snapshot.data ?? true) && _phase == _Phase.prompt;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: offline ? const OfflineState() : _body(),
                      ),
                    ),
                    if (_phase == _Phase.prompt) ...[
                      if (!offline) ...[
                        TealButton(
                          label: AppStrings.cloudSignInContinue,
                          onPressed: _continue,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Center(
                        child: TextButton(
                          onPressed: _skip,
                          child: const Text(
                            AppStrings.cloudSignInNotNow,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.prompt:
        return const _PromptBody();
      case _Phase.working:
        return const _WorkingBody();
      case _Phase.done:
        return _DoneBody(tripsRestored: _tripsRestored);
    }
  }
}

class _PromptBody extends StatelessWidget {
  const _PromptBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.card,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.cloud_sync_rounded,
            color: AppColors.teal,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          AppStrings.cloudSignInTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingLarge,
        ),
        const SizedBox(height: 10),
        Text(
          AppStrings.cloudSignInBody,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _WorkingBody extends StatelessWidget {
  const _WorkingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.teal),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.cloudSignInSyncing,
          style: AppTextStyles.body.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _DoneBody extends StatelessWidget {
  const _DoneBody({required this.tripsRestored});

  final int tripsRestored;

  @override
  Widget build(BuildContext context) {
    final message = tripsRestored > 0
        ? '${AppStrings.cloudSignInWelcomeBack} — $tripsRestored trips restored'
        : AppStrings.cloudSignInAllSet;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 40),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingMedium,
        ),
      ],
    );
  }
}
