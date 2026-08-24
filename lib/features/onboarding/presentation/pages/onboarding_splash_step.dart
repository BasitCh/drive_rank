import 'dart:math' as math;

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/splash_ring.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Onboarding step 1 — the three-slide animated speedometer intro.
///
/// Each slide swaps the title/sub copy. The ring's arc and number animate
/// from 0 → ~75 on first appear, then hold steady. Dot indicators along the
/// top track which slide you're on; tapping Next advances slides until the
/// last one, where it forwards to step 2 via the OnboardingBloc.
class OnboardingSplashStep extends StatefulWidget {
  const OnboardingSplashStep({required this.locale, super.key});

  final LocaleService locale;

  @override
  State<OnboardingSplashStep> createState() => _OnboardingSplashStepState();
}

class _OnboardingSplashStepState extends State<OnboardingSplashStep>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final Animation<double> _ringValue;

  // Once the initial 0→74 ramp settles, a smooth "count-up" reads as a
  // loading bar rather than something alive. This keeps the dial gently
  // wobbling around its settled position afterward — small back-to-back
  // journeys between nearby random offsets, the same trick a real
  // telemetry readout does (see A1 in the onboarding animation notes).
  late final AnimationController _wobbleController;
  double _wobbleFrom = 0;
  double _wobbleTo = 0;
  final _rand = math.Random();

  int _slide = 0;

  static const _slides = <_Slide>[
    _Slide(
      title: AppStrings.splashTitleSlide1,
      sub: AppStrings.splashSubSlide1,
    ),
    _Slide(
      title: AppStrings.splashTitleSlide2,
      sub: AppStrings.splashSubSlide2,
    ),
    _Slide(
      title: AppStrings.splashTitleSlide3,
      sub: AppStrings.splashSubSlide3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringValue = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _ringController.forward().whenComplete(_scheduleNextWobble);
  }

  void _scheduleNextWobble() {
    if (!mounted) return;
    _wobbleFrom = _wobbleTo;
    // ±4% of the dial's full scale — on a settled value of 74 that's
    // roughly a 70-78 band, close to the "88, 86, 88, 89, 87…" swing a
    // real live readout has.
    _wobbleTo = (_rand.nextDouble() * 0.08) - 0.04;
    _wobbleController
      ..reset()
      ..forward().whenComplete(_scheduleNextWobble);
  }

  double get _wobbleValue {
    final t = Curves.easeInOut.transform(_wobbleController.value);
    return _wobbleFrom + (_wobbleTo - _wobbleFrom) * t;
  }

  @override
  void dispose() {
    _ringController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  void _onCta() {
    if (_slide < _slides.length - 1) {
      setState(() => _slide += 1);
      return;
    }
    context.read<OnboardingBloc>().add(const OnboardingStepNext());
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _slide ? 36 : 28,
                        height: 4,
                        decoration: BoxDecoration(
                          color: i == _slide
                              ? AppColors.teal
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: Listenable.merge([_ringValue, _wobbleController]),
                builder: (_, __) {
                  final live = _ringController.isCompleted
                      ? (_ringValue.value + _wobbleValue).clamp(0.0, 1.15)
                      : _ringValue.value;
                  return SplashRing(
                    value: live,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (74 * live).round().toString(),
                          style: AppTextStyles.splashNumber,
                        ),
                        const SizedBox(height: 0),
                        Text(
                          widget.locale.speedUnitLabel,
                          style: AppTextStyles.speedUnit.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              Column(
                children: [
                  Text(
                    _slides[_slide].title,
                    style: AppTextStyles.headingLarge.copyWith(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _slides[_slide].sub,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TealButton(
                label: _slide == _slides.length - 1
                    ? AppStrings.continueAction
                    : AppStrings.next,
                onPressed: _onCta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.title, required this.sub});
  final String title;
  final String sub;
}
