import 'dart:math' as math;

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/splash_ring.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const double _kmhToMph = 0.621371;

/// Step 2 — km/h vs mph, with a live-oscillating dial identical in spirit
/// to the splash step's (see A1 in the onboarding animation notes), plus
/// A2: tapping the other unit live-converts the running number instead of
/// just relabelling it, so the choice demonstrates itself.
class OnboardingUnitStep extends StatefulWidget {
  const OnboardingUnitStep({super.key});

  @override
  State<OnboardingUnitStep> createState() => _OnboardingUnitStepState();
}

class _OnboardingUnitStepState extends State<OnboardingUnitStep>
    with TickerProviderStateMixin {
  // The live value oscillates in km/h regardless of which unit is
  // displayed — only the text label converts. That's what makes toggling
  // read as "the same live speed, shown differently" rather than two
  // unrelated numbers.
  static const double _settledKmh = 140;
  static const double _ringMaxKmh = 200;

  late final AnimationController _rampController;
  late final Animation<double> _rampValue;
  late final AnimationController _wobbleController;
  double _wobbleFrom = 0;
  double _wobbleTo = 0;
  final _rand = math.Random();

  late UnitSystem _unit;

  @override
  void initState() {
    super.initState();
    _unit = getIt<LocaleService>().unitSystem;
    _rampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _rampValue = CurvedAnimation(
      parent: _rampController,
      curve: Curves.easeOutCubic,
    );
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _rampController.forward().whenComplete(_scheduleNextWobble);
  }

  void _scheduleNextWobble() {
    if (!mounted) return;
    _wobbleFrom = _wobbleTo;
    _wobbleTo = (_rand.nextDouble() * 0.08) - 0.04;
    _wobbleController
      ..reset()
      ..forward().whenComplete(_scheduleNextWobble);
  }

  double get _wobbleFraction {
    final t = Curves.easeInOut.transform(_wobbleController.value);
    return _wobbleFrom + (_wobbleTo - _wobbleFrom) * t;
  }

  @override
  void dispose() {
    _rampController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  void _selectUnit(UnitSystem unit) {
    if (unit == _unit) return;
    setState(() => _unit = unit);
  }

  void _continue() {
    context.read<OnboardingBloc>().add(OnboardingUnitSelected(_unit));
    context.read<OnboardingBloc>().add(const OnboardingStepNext());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                AppStrings.onboardUnitTitle,
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Text(
                  AppStrings.onboardUnitSub,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AnimatedBuilder(
                animation: Listenable.merge([_rampValue, _wobbleController]),
                builder: (_, __) {
                  const settledFraction = _settledKmh / _ringMaxKmh;
                  final fraction = _rampController.isCompleted
                      ? (settledFraction + _wobbleFraction).clamp(0.0, 1.15)
                      : _rampValue.value * settledFraction;
                  final liveKmh = fraction * _ringMaxKmh;
                  final displayValue = _unit == UnitSystem.imperial
                      ? (liveKmh * _kmhToMph).round()
                      : liveKmh.round();
                  return SplashRing(
                    value: (liveKmh / _ringMaxKmh).clamp(0.0, 1.15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$displayValue',
                          style: AppTextStyles.splashNumber,
                        ),
                        Text(
                          _unit == UnitSystem.imperial ? 'mph' : 'km/h',
                          style: AppTextStyles.speedUnit.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              _UnitToggle(selected: _unit, onChanged: _selectUnit),
            ],
          ),
        ),
        TealButton(label: AppStrings.continueAction, onPressed: _continue),
      ],
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.selected, required this.onChanged});

  final UnitSystem selected;
  final ValueChanged<UnitSystem> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitPill(
            label: 'km/h',
            selected: selected == UnitSystem.metric,
            onTap: () => onChanged(UnitSystem.metric),
          ),
          _UnitPill(
            label: 'mph',
            selected: selected == UnitSystem.imperial,
            onTap: () => onChanged(UnitSystem.imperial),
          ),
        ],
      ),
    );
  }
}

class _UnitPill extends StatelessWidget {
  const _UnitPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
