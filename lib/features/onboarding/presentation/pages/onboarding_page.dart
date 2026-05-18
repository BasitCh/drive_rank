import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_car_photo_step.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_car_step.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_community_step.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_country_step.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_map_theme_step.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_reviews_step.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_safety_step.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_splash_step.dart';
import 'package:drive_rank/features/onboarding/presentation/pages/onboarding_username_step.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/progress_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Coordinator page for the entire onboarding flow.
///
/// Owns a single `OnboardingBloc`, renders progress chrome (except on the
/// splash and "done" steps), swaps in the active step widget, and redirects
/// to `/home` the moment `state.completed` flips to true.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingBloc>(
      create: (_) => getIt<OnboardingBloc>()..add(const OnboardingStarted()),
      child: const _OnboardingPageBody(),
    );
  }
}

class _OnboardingPageBody extends StatelessWidget {
  const _OnboardingPageBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (a, b) => a.completed != b.completed,
      listener: (context, state) {
        if (state.completed) context.go(RouteNames.home);
      },
      builder: (context, state) {
        // Splash step renders without progress chrome — it's the brand intro.
        if (state.step == OnboardingStep.splash) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: OnboardingSplashStep(locale: getIt<LocaleService>()),
          );
        }

        if (state.step == OnboardingStep.done) {
          return const ColoredBox(
            color: AppColors.bg,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            ),
          );
        }

        final canSystemPop =
            state.step.index <= OnboardingStep.countryAndVehicle.index;
        return PopScope<Object?>(
          canPop: canSystemPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              context.read<OnboardingBloc>().add(const OnboardingStepBack());
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProgressChrome(
                      progress: state.step.progress,
                      onBack:
                          state.step.index >
                              OnboardingStep.countryAndVehicle.index
                          ? () => context.read<OnboardingBloc>().add(
                              const OnboardingStepBack(),
                            )
                          : null,
                    ),
                    Expanded(child: _stepWidget(state.step)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stepWidget(OnboardingStep step) => switch (step) {
    OnboardingStep.countryAndVehicle => const OnboardingCountryStep(),
    OnboardingStep.car => const OnboardingCarStep(),
    OnboardingStep.username => const OnboardingUsernameStep(),
    OnboardingStep.carPhoto => const OnboardingCarPhotoStep(),
    OnboardingStep.community => const OnboardingCommunityStep(),
    OnboardingStep.mapTheme => const OnboardingMapThemeStep(),
    OnboardingStep.reviews => const OnboardingReviewsStep(),
    OnboardingStep.safety => const OnboardingSafetyStep(),
    OnboardingStep.splash || OnboardingStep.done => const SizedBox.shrink(),
  };
}
