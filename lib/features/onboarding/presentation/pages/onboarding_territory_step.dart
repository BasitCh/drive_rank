import 'dart:math' as math;

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:drive_rank/shared/models/car_category.dart';
import 'package:drive_rank/shared/widgets/car_silhouette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Feature-teaser step — previews the real, already-shipped Territory
/// page (`lib/features/territory/`) before the user has driven anything
/// to actually populate it. A scripted, ~2.5s "takeover" demo — a canned
/// sequence over a hand-placed hex grid, not read from any real trip
/// data (there isn't any yet at this point in onboarding).
class OnboardingTerritoryStep extends StatefulWidget {
  const OnboardingTerritoryStep({super.key});

  @override
  State<OnboardingTerritoryStep> createState() =>
      _OnboardingTerritoryStepState();
}

class _OnboardingTerritoryStepState extends State<OnboardingTerritoryStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1; // jump straight to the end state
    } else {
      _controller.forward(); // play once, hold the end state
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (a, b) => a.carMake != b.carMake || a.username != b.username,
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    AppStrings.onboardTerritoryTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.onboardTerritorySub,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AspectRatio(
                    aspectRatio: 1.15,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(color: AppColors.border2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => _TerritoryTakeover(
                            t: _controller.value,
                            username: state.username.trim().isEmpty
                                ? 'You'
                                : state.username.trim(),
                            userCategory:
                                state.carMake?.category ??
                                CarCategory.defaultCategory,
                            userMakeId: state.carMake?.id,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Driven directly off the master controller (not its own
                // implicit animation) — it's already ticking every
                // frame, so a second AnimatedOpacity here would just be
                // re-targeting a new implicit animation on every tick.
                final enabled = _seqT(_controller.value, 0.85, 1) >= 1;
                return Opacity(
                  opacity: 0.5 + 0.5 * _seqT(_controller.value, 0.85, 1),
                  child: TealButton(
                    label: AppStrings.continueAction,
                    enabled: enabled,
                    onPressed: () => context.read<OnboardingBloc>().add(
                      const OnboardingStepNext(),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Maps the master `t` (0..1) onto a sub-interval, clamped 0..1 — the
/// same "one controller, several intervals" pattern used to sequence
/// every stage of the takeover below.
double _seqT(double t, double start, double end) =>
    ((t - start) / (end - start)).clamp(0.0, 1.0);

enum _Cluster { teal, red, blue, neutral }

class _Cell {
  const _Cell(this.col, this.row, this.cluster, {this.flipsAt});

  final int col;
  final int row;
  final _Cluster cluster;

  /// (start, end) of this cell's flip window within the master timeline,
  /// or null if this cell never changes colour.
  final (double, double)? flipsAt;
}

/// Hand-placed ~20-cell layout: a teal cluster (left, "you"), a red
/// cluster (centre, a rival), a blue cluster (upper right, another
/// rival), and neutral unclaimed filler cells for grid density. Two of
/// the red cells flip to teal during the sequence — chosen adjacent to
/// the teal cluster so the "growing rightward" motion reads naturally.
const _cells = <_Cell>[
  // Teal — the user's existing territory.
  _Cell(0, 0, _Cluster.teal),
  _Cell(0, 1, _Cluster.teal),
  _Cell(1, 0, _Cluster.teal),
  _Cell(1, 1, _Cluster.teal),
  // Red — rival, two cells flip during the takeover.
  _Cell(2, 0, _Cluster.red, flipsAt: (0.18, 0.34)),
  _Cell(2, 1, _Cluster.red, flipsAt: (0.38, 0.54)),
  _Cell(3, 0, _Cluster.red),
  _Cell(3, 1, _Cluster.red),
  // Blue — a second, untouched rival.
  _Cell(4, -1, _Cluster.blue),
  _Cell(5, -1, _Cluster.blue),
  _Cell(5, 0, _Cluster.blue),
  // Neutral — unclaimed filler, purely for grid density.
  _Cell(1, -1, _Cluster.neutral),
  _Cell(2, -1, _Cluster.neutral),
  _Cell(3, -1, _Cluster.neutral),
  _Cell(0, 2, _Cluster.neutral),
  _Cell(1, 2, _Cluster.neutral),
  _Cell(2, 2, _Cluster.neutral),
  _Cell(3, 2, _Cluster.neutral),
  _Cell(4, 0, _Cluster.neutral),
  _Cell(4, 1, _Cluster.neutral),
];

/// Cursor waypoints, in the same (col, row) space as `_cells` — glides
/// from inside the teal cluster, through the two flipping red cells, and
/// one cell further to suggest continued advance without claiming it.
const _cursorWaypoints = <(double, double)>[
  (1.0, 0.0),
  (2.0, 0.0),
  (2.0, 1.0),
  (2.6, 1.0),
];

class _TerritoryTakeover extends StatelessWidget {
  const _TerritoryTakeover({
    required this.t,
    required this.username,
    required this.userCategory,
    required this.userMakeId,
  });

  final double t;
  final String username;
  final CarCategory userCategory;
  final String? userMakeId;

  @override
  Widget build(BuildContext context) {
    final pillT = _seqT(t, 0.55, 0.85);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _HexGridPainter(t: t)),
        Positioned(
          left: 10,
          right: 10,
          top: 10,
          child: _KingPill(
            t: pillT,
            username: username,
            userCategory: userCategory,
            userMakeId: userMakeId,
          ),
        ),
      ],
    );
  }
}

class _HexGridPainter extends CustomPainter {
  _HexGridPainter({required this.t});

  final double t;

  static const double _radius = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final panelCentre = Offset(size.width / 2, size.height * 0.58);
    // The cells span roughly col -1..5, row -1..2 — not symmetric
    // around (col:0, row:0) — so anchoring that origin at the panel's
    // literal centre pushes the whole cluster visibly right. Centre the
    // cluster's actual bounding box instead.
    final raw = [
      for (final cell in _cells) _pixelFor(cell.col, cell.row, Offset.zero),
    ];
    final minX = raw.map((o) => o.dx).reduce(math.min);
    final maxX = raw.map((o) => o.dx).reduce(math.max);
    final minY = raw.map((o) => o.dy).reduce(math.min);
    final maxY = raw.map((o) => o.dy).reduce(math.max);
    final clusterCentre = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    final centre = panelCentre - clusterCentre;

    for (final cell in _cells) {
      final origin = _pixelFor(cell.col, cell.row, centre);
      final flip = cell.flipsAt;
      final flipT = flip == null ? 0.0 : _seqT(t, flip.$1, flip.$2);
      final color = _colorFor(cell.cluster, flipT);
      final filled = cell.cluster != _Cluster.neutral || flipT > 0;
      // A brief scale-pop while a cell is actively flipping — peaks at
      // the midpoint of its own flip window, settles back to 1.0 either
      // side of it.
      final scale = flip == null
          ? 1.0
          : 1.0 + 0.15 * math.sin(math.pi * flipT);
      _drawHex(canvas, origin, color, filled, scale);
    }

    // Cursor glides through the waypoints — piecewise-linear between
    // them, eased overall via the cursor interval below.
    final cursorT = _seqT(t, 0, 0.55);
    final cursorPixel = _cursorPositionFor(cursorT, centre);
    if (cursorT > 0 && cursorT < 1) {
      _drawCursor(canvas, cursorPixel);
    }
  }

  Offset _pixelFor(int col, int row, Offset centre) {
    final x = centre.dx + _radius * 1.5 * col;
    final y =
        centre.dy +
        _radius * math.sqrt(3) * (row + 0.5 * (col.isOdd ? 1 : 0));
    return Offset(x, y);
  }

  /// Waypoint pixel positions, computed once per paint via [_pixelFor] —
  /// [_cursorPositionFor] then does plain linear interpolation between
  /// them. (Reconstructing a pixel position mid-segment from a rounded
  /// column, as an earlier version of this did, breaks: `_pixelFor`'s
  /// row offset depends on the column's parity, so a fractional column
  /// crossing a rounding boundary mid-glide caused a visible jump.)
  List<Offset> _cursorWaypointPixels(Offset centre) => [
    for (final (col, row) in _cursorWaypoints)
      Offset(
        centre.dx + _radius * 1.5 * col,
        centre.dy +
            _radius *
                math.sqrt(3) *
                (row + 0.5 * (col.round().isOdd ? 1 : 0)),
      ),
  ];

  Offset _cursorPositionFor(double rawT, Offset centre) {
    final points = _cursorWaypointPixels(centre);
    final segments = points.length - 1;
    final scaled = (Curves.easeInOut.transform(rawT.clamp(0.0, 1.0)) *
            segments)
        .clamp(0.0, segments.toDouble());
    final index = scaled.floor().clamp(0, segments - 1);
    final localT = scaled - index;
    return Offset.lerp(points[index], points[index + 1], localT)!;
  }

  Color _colorFor(_Cluster cluster, double flipT) {
    if (flipT > 0) {
      return Color.lerp(AppColors.red, AppColors.teal, flipT)!;
    }
    return switch (cluster) {
      _Cluster.teal => AppColors.teal,
      _Cluster.red => AppColors.red,
      _Cluster.blue => AppColors.blue,
      _Cluster.neutral => Colors.white,
    };
  }

  void _drawHex(
    Canvas canvas,
    Offset centre,
    Color color,
    bool filled,
    double scale,
  ) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i);
      final point = Offset(
        centre.dx + _radius * scale * math.cos(angle),
        centre.dy + _radius * scale * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    if (filled) {
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.42));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: filled ? 0.85 : 0.18),
    );
  }

  void _drawCursor(Canvas canvas, Offset at) {
    final path = Path()
      ..moveTo(at.dx, at.dy - 7)
      ..lineTo(at.dx + 6, at.dy + 5)
      ..lineTo(at.dx - 6, at.dy + 5)
      ..close();
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = AppColors.teal
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawPath(path, Paint()..color = AppColors.teal);
  }

  @override
  bool shouldRepaint(_HexGridPainter old) => old.t != t;
}

/// The floating "King of the Area" capsule — starts showing a rival,
/// cross-fades (plus a small scale-pop) into the user's own name, car,
/// and a count-up area figure once the takeover completes.
class _KingPill extends StatelessWidget {
  const _KingPill({
    required this.t,
    required this.username,
    required this.userCategory,
    required this.userMakeId,
  });

  /// 0 = still showing the rival, 1 = fully flipped to the user.
  final double t;
  final String username;
  final CarCategory userCategory;
  final String? userMakeId;

  static const _rivalName = 'APEX_NL';
  static const _rivalAreaKm2 = 12.4;
  static const _userAreaKm2 = 15.1;

  @override
  Widget build(BuildContext context) {
    final glowColor = Color.lerp(AppColors.red, AppColors.teal, t)!;
    final dotColor = Color.lerp(AppColors.red, AppColors.green, t)!;
    final areaKm2 = _rivalAreaKm2 + (_userAreaKm2 - _rivalAreaKm2) * t;
    final scale = 1.0 + 0.08 * math.sin(math.pi * t);

    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bg.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: 1 - t,
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.card,
                          child: Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: t,
                        child: ClipOval(
                          child: CarSilhouette(
                            category: userCategory,
                            makeId: userMakeId,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t < 0.5 ? _rivalName : username,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${areaKm2.toStringAsFixed(1)} km²',
                  style: AppTextStyles.microLabel.copyWith(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: dotColor),
                const SizedBox(width: 6),
                Text(
                  AppStrings.onboardTerritoryKingLabel,
                  style: AppTextStyles.microLabel.copyWith(
                    fontSize: 9,
                    letterSpacing: 0.6,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 6),
                _Dot(color: dotColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
