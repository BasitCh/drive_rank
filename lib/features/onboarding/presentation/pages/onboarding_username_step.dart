import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Onboarding step — pick the public username that shows on the
/// leaderboard. Live-checks availability against Firestore with a
/// 600ms debounce; the Continue button is gated on
/// `usernameStatus == available` (the bloc enforces this via
/// `canAdvance` so we never accidentally enable it elsewhere).
class OnboardingUsernameStep extends StatefulWidget {
  const OnboardingUsernameStep({super.key});

  @override
  State<OnboardingUsernameStep> createState() => _OnboardingUsernameStepState();
}

class _OnboardingUsernameStepState extends State<OnboardingUsernameStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = context.read<OnboardingBloc>().state.username;
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (a, b) =>
          a.username != b.username && b.username != _controller.text,
      listener: (context, state) {
        // Bloc rewrote the username (e.g. resume from saved settings) —
        // keep the field in sync without losing the cursor.
        _controller.value = TextEditingValue(
          text: state.username,
          selection: TextSelection.collapsed(offset: state.username.length),
        );
      },
      buildWhen: (a, b) =>
          a.username != b.username ||
          a.usernameStatus != b.usernameStatus ||
          a.completionError != b.completionError,
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      AppStrings.onboardUsernameTitle,
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        AppStrings.onboardUsernameSub,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: TextField(
                        controller: _controller,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.none,
                        inputFormatters: [
                          // Keep the user from typing characters we'll
                          // reject — feels nicer than the inline error.
                          FilteringTextInputFormatter.allow(
                            RegExp('[A-Za-z0-9_]'),
                          ),
                          LengthLimitingTextInputFormatter(24),
                        ],
                        style: AppTextStyles.title.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.onboardUsernameHint,
                          prefixText: '@ ',
                          prefixStyle: AppTextStyles.title.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w400,
                          ),
                          suffixIcon: _StatusIcon(status: state.usernameStatus),
                        ),
                        onChanged: (v) => context.read<OnboardingBloc>().add(
                          OnboardingUsernameChanged(v),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _HelperText(
                      username: state.username,
                      status: state.usernameStatus,
                    ),
                    if (state.completionError != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          state.completionError!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            TealButton(
              label: AppStrings.continueAction,
              enabled: state.canAdvance,
              onPressed: () => context.read<OnboardingBloc>().add(
                const OnboardingStepNext(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final UsernameCheckStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case UsernameCheckStatus.idle:
        return const SizedBox.shrink();
      case UsernameCheckStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: AppColors.teal,
              strokeWidth: 2,
            ),
          ),
        );
      case UsernameCheckStatus.available:
        return const Icon(Icons.check_circle_rounded, color: AppColors.green);
      case UsernameCheckStatus.taken:
      case UsernameCheckStatus.error:
        return const Icon(Icons.cancel_rounded, color: AppColors.red);
      case UsernameCheckStatus.tooShort:
      case UsernameCheckStatus.invalidFormat:
        return const Icon(
          Icons.info_outline_rounded,
          color: AppColors.textTertiary,
        );
    }
  }
}

class _HelperText extends StatelessWidget {
  const _HelperText({required this.username, required this.status});

  final String username;
  final UsernameCheckStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = _resolve(username, status);
    if (text == null) {
      // Reserve a constant vertical slot so the layout doesn't jump
      // between helper-text states.
      return const SizedBox(height: 18);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static (String?, Color) _resolve(
    String username,
    UsernameCheckStatus status,
  ) => switch (status) {
    UsernameCheckStatus.idle => (null, AppColors.textSecondary),
    UsernameCheckStatus.checking => (
      AppStrings.onboardUsernameChecking,
      AppColors.textSecondary,
    ),
    UsernameCheckStatus.available => (
      '@${username.trim().toLowerCase()}'
          '${AppStrings.onboardUsernameAvailableSuffix}',
      AppColors.green,
    ),
    UsernameCheckStatus.taken => (
      AppStrings.onboardUsernameTaken,
      AppColors.red,
    ),
    UsernameCheckStatus.tooShort => (
      AppStrings.onboardUsernameTooShort,
      AppColors.textSecondary,
    ),
    UsernameCheckStatus.invalidFormat => (
      AppStrings.onboardUsernameInvalid,
      AppColors.textSecondary,
    ),
    UsernameCheckStatus.error => (
      AppStrings.onboardUsernameError,
      AppColors.red,
    ),
  };
}
