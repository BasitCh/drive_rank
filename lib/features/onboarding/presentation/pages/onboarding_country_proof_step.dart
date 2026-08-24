import 'dart:math' as math;

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 2 — "N people from your country used DriveRank yesterday" social
/// proof, right after country selection.
///
/// V1 uses a stable per-country seed number, same approach the car-make
/// community screen uses — a real per-country daily-active count needs a
/// Firestore aggregate that doesn't exist yet.
/// The seed floor (8k) is intentionally well above the "don't ship an
/// embarrassing number" threshold the reference design calls out; swap in
/// the real aggregate once DriveRank has enough daily actives per country
/// to clear that bar on its own.
class OnboardingCountryProofStep extends StatelessWidget {
  const OnboardingCountryProofStep({super.key});

  static int _seedFor(String countryCode) {
    if (countryCode.isEmpty) return 12000;
    final hash = countryCode.hashCode.abs();
    // Range 8k .. 96k — comfortably past the "not embarrassing" floor.
    return 8000 + (hash % 88000);
  }

  static String _formatThousands(int n) {
    final str = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (a, b) => a.country != b.country,
      builder: (context, state) {
        final country = state.country;
        final count = _seedFor(country?.code ?? '');

        return Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${AppStrings.onboardCountryProofTitle} '
                    '${country?.flag ?? ''}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Abstract activity texture, not a literal country
                  // outline — DriveRank has no geographic boundary data
                  // to draw a real map from, so this is a stylised
                  // "presence" visualisation rather than a claim of
                  // geographic accuracy. Seeded by country so it's
                  // stable per-country like the count below it.
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: _PresenceGrid(
                      key: ValueKey('presence-${country?.code}'),
                      seed: country?.code ?? '',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Same count-up treatment as the car-make social proof
                  // screen (A5 in the onboarding animation notes) — a
                  // static number reads as a fact, a number racing up
                  // reads as a crowd.
                  TweenAnimationBuilder<double>(
                    key: ValueKey('country-count-$count'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutExpo,
                    builder: (context, t, _) {
                      return Text(
                        _formatThousands((count * t).round()),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                          height: 1,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'people from ${country?.name ?? "your country"} '
                    '${AppStrings.onboardCountryProofSuffix}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
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

/// A grid of small dots, each a stable-per-[seed] colour/brightness,
/// fading in staggered by distance from the centre — reads as an
/// "activity heatmap" without claiming to be a real geographic map.
class _PresenceGrid extends StatefulWidget {
  const _PresenceGrid({required this.seed, super.key});

  final String seed;

  @override
  State<_PresenceGrid> createState() => _PresenceGridState();
}

class _PresenceGridState extends State<_PresenceGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `CustomPaint` with no `size:` collapses to zero size unless its
    // parent gives it a tight constraint — the enclosing Column here
    // uses the default centre cross-axis alignment, which only gives
    // loose constraints, so without this the whole grid rendered at
    // 0x0 (invisible, no error, nothing in any log).
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _PresenceGridPainter(widget.seed, _controller.value),
        ),
      ),
    );
  }
}

class _PresenceGridPainter extends CustomPainter {
  _PresenceGridPainter(this.seed, this.t);

  final String seed;
  final double t;

  static const _cols = 16;
  static const _rows = 8;
  static const _colors = [
    AppColors.teal,
    AppColors.blue,
    AppColors.orange,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed.hashCode);
    final cellW = size.width / _cols;
    final cellH = size.height / _rows;
    final dotRadius = math.min(cellW, cellH) * 0.28;
    const centreCol = _cols / 2;
    const centreRow = _rows / 2;
    final maxDist = math.sqrt(centreCol * centreCol + centreRow * centreRow);

    for (var row = 0; row < _rows; row++) {
      for (var col = 0; col < _cols; col++) {
        // A stable per-cell roll decides whether this cell has a dot at
        // all — an even grid of every cell reads as a spreadsheet, a
        // sparse irregular one reads as "coverage".
        if (rand.nextDouble() > 0.62) continue;

        final dist =
            math.sqrt(
              math.pow(col - centreCol, 2) + math.pow(row - centreRow, 2),
            ) /
            maxDist;
        // Dots nearer the centre fade in first — the same "sweep
        // outward" feel as the reference's map animating on.
        final delay = dist * 0.6;
        final localT = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
        if (localT <= 0) continue;

        final color = _colors[rand.nextInt(_colors.length)];
        final brightness = 0.35 + rand.nextDouble() * 0.65;
        final centre = Offset(
          col * cellW + cellW / 2,
          row * cellH + cellH / 2,
        );
        canvas.drawCircle(
          centre,
          dotRadius * Curves.easeOutBack.transform(localT).clamp(0.0, 1.2),
          Paint()..color = color.withValues(alpha: brightness * localT),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PresenceGridPainter old) =>
      old.t != t || old.seed != seed;
}
