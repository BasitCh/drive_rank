import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 5 — map theme picker. Large preview strip on top, 6 chip thumbnails
/// in a horizontal scroller.
class OnboardingMapThemeStep extends StatelessWidget {
  const OnboardingMapThemeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (a, b) => a.mapTheme != b.mapTheme,
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    AppStrings.onboardMapThemeTitle,
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.onboardMapThemeSub,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ThemePreview(theme: state.mapTheme),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: MapTheme.values.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (_, i) {
                        final t = MapTheme.values[i];
                        final selected = state.mapTheme == t;
                        return _ThemeChip(
                          theme: t,
                          selected: selected,
                          onTap: () => context.read<OnboardingBloc>().add(
                            OnboardingMapThemeSelected(t),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                    ),
                  ),
                ],
              ),
            ),
            TealButton(
              label: AppStrings.continueAction,
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

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});

  final MapTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: theme.gradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 7,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                theme.label.toUpperCase(),
                style: AppTextStyles.microLabel.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 8,
                ),
              ),
            ),
          ),
          // Faux road cross hairs to evoke a map.
          Positioned.fill(
            child: CustomPaint(painter: _RoadHairsPainter(theme: theme)),
          ),
        ],
      ),
    );
  }
}

class _RoadHairsPainter extends CustomPainter {
  _RoadHairsPainter({required this.theme});

  final MapTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.butt;

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas
      ..drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        shadowPaint,
      )
      ..drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        shadowPaint,
      )
      ..drawCircle(Offset(size.width / 2, size.height / 2), 6, dotPaint);
  }

  @override
  bool shouldRepaint(_RoadHairsPainter old) => old.theme != theme;
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final MapTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: theme.gradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.teal : Colors.transparent,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(theme.glyph, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          theme.label,
          style: AppTextStyles.microLabel.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
