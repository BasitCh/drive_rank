import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/replay_point.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_bucket.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Dark-themed map with the speed-coloured polyline + explicit START /
/// END markers, plus an animated route replay: play/pause, a
/// draggable scrub bar, a 1x/2x/3x speed multiplier, live speed /
/// distance / elapsed-time counters, a pulsing radar marker at the
/// trip's fastest waypoint with a "TOP SPEED" popover once the replay
/// vehicle reaches it, and a re-centre button once the user pans away.
/// The camera itself follows the replay marker start-to-end while
/// playing — panning is automatic, not something the user has to do
/// by hand — and backs off the moment the user drags manually; the
/// re-centre button hands control back to auto-follow. The moving
/// marker renders the user's selected vehicle glyph (car or
/// motorbike) rather than a plain dot. Fills the Journey card's
/// vertical real estate per spec (~70 % of the card).
///
/// Replay is disabled entirely below 20 waypoints
/// (`InsightsBundle.replayEligible`) — a couple of jerky hops isn't a
/// route story, so the controls just don't render.
///
/// Basemap: CartoDB Dark Matter tiles — pre-rendered dark style with
/// legible white labels. Earlier versions filtered OSM Carto-light at
/// runtime with a `ColorFilter` matrix, which mangled label contrast
/// (the user couldn't read country names) and cost a GPU pass per
/// tile per frame. Dark tiles render natively, no filter required.
/// Attribution rendered bottom-right via flutter_map's
/// `RichAttributionWidget`.
class JourneyMap extends StatefulWidget {
  const JourneyMap({
    required this.bundle,
    required this.locale,
    this.showControls = true,
    this.vehicleType = VehicleType.car,
    super.key,
  });

  final InsightsBundle bundle;
  final LocaleService locale;

  /// When false, renders the route/tiles/markers only — no play/pause,
  /// scrub bar, multiplier, live-stats overlay, or TOP SPEED badge.
  /// Used for the trip detail page's collapsible map preview, where a
  /// separate "Play" button opens the full replay on its own screen
  /// instead of animating in place. Panning/re-centring still works
  /// either way.
  final bool showControls;

  /// The user's selected vehicle (Settings) — the replay marker shows
  /// this vehicle's glyph instead of a plain dot.
  final VehicleType vehicleType;

  @override
  State<JourneyMap> createState() => _JourneyMapState();
}

class _JourneyMapState extends State<JourneyMap>
    with TickerProviderStateMixin {
  late final AnimationController _replayController;

  /// Drives the continuous "radar ping" ring around the trip's top
  /// speed point — a standing affordance marking where it happened,
  /// independent of playback state.
  late final AnimationController _pulseController;
  final MapController _mapController = MapController();
  late List<LatLng> _routePoints;
  late int _topSpeedIndex;
  int _speedMultiplier = 1;
  bool _hasPannedAway = false;
  LatLngBounds? _bounds;

  /// The live stats row (Speed / Distance / Time) only refreshes this
  /// often, regardless of frame rate — the replay covers a whole trip
  /// in ~12 real seconds, so re-deriving the readout every animation
  /// frame made the numbers flicker past unreadably fast. The marker
  /// and route reveal stay perfectly smooth; only the digits are
  /// sampled down to a human-readable cadence.
  static const Duration _statsRefreshInterval = Duration(milliseconds: 180);
  int? _displayedStatsIndex;
  DateTime? _lastStatsRefresh;

  /// Full-route replay duration at 1x — tuned for a satisfying watch
  /// without dragging on a long trip. Scaled down by the multiplier.
  static const int _baseDurationMs = 12000;

  @override
  void initState() {
    super.initState();
    _replayController = AnimationController(
      vsync: this,
      duration: _durationForMultiplier(1),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _routePoints = _positionsOf(widget.bundle);
    _topSpeedIndex = _topSpeedIndexOf(widget.bundle);
    _replayController.addListener(_followCamera);
  }

  @override
  void didUpdateWidget(covariant JourneyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bundle != widget.bundle) {
      _routePoints = _positionsOf(widget.bundle);
      _topSpeedIndex = _topSpeedIndexOf(widget.bundle);
      _replayController.reset();
      _hasPannedAway = false;
      _displayedStatsIndex = null;
      _lastStatsRefresh = null;
    }
  }

  @override
  void dispose() {
    _replayController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Duration _durationForMultiplier(int multiplier) =>
      Duration(milliseconds: (_baseDurationMs / multiplier).round());

  List<LatLng> _positionsOf(InsightsBundle bundle) =>
      [for (final p in bundle.replayPoints) p.position];

  int _topSpeedIndexOf(InsightsBundle bundle) {
    final points = bundle.replayPoints;
    if (points.isEmpty) return -1;
    var best = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].speedKmh > points[best].speedKmh) best = i;
    }
    return best;
  }

  bool get _canReplay =>
      widget.showControls &&
      widget.bundle.replayEligible &&
      _routePoints.length > 1;

  void _togglePlayback() {
    if (!_canReplay) return;
    if (_replayController.isAnimating) {
      _replayController.stop();
      return;
    }
    if (_replayController.value >= 1) {
      _replayController.forward(from: 0);
    } else {
      _replayController.forward();
    }
  }

  void _setMultiplier(int multiplier) {
    if (multiplier == _speedMultiplier) return;
    final wasAnimating = _replayController.isAnimating;
    final current = _replayController.value;
    setState(() => _speedMultiplier = multiplier);
    _replayController.duration = _durationForMultiplier(multiplier);
    if (wasAnimating) {
      _replayController.forward(from: current);
    }
  }

  /// Points revealed by the current replay progress. Keyed off point
  /// *index* rather than geographic distance — waypoints are logged at
  /// a roughly fixed sampling interval, so index position already
  /// tracks elapsed trip time (a highway segment isn't sampled any
  /// denser than a slow one), which is what a "replay" should follow.
  int _revealedCount(double progress) {
    if (_routePoints.length < 2) return _routePoints.length;
    return (_routePoints.length * progress).ceil().clamp(
      1,
      _routePoints.length,
    );
  }

  /// The replay-point index to *display* in the stats row right now —
  /// sampled from the true (smooth, per-frame) progress at
  /// [_statsRefreshInterval] so the digits update at a readable pace
  /// instead of every frame. See the field doc for why.
  int _statsDisplayIndex(InsightsBundle bundle) {
    final progress = _replayController.value;
    final revealedCount = _revealedCount(progress);
    final rawIdx = (revealedCount - 1).clamp(0, bundle.replayPoints.length - 1);
    final now = DateTime.now();
    final due =
        _displayedStatsIndex == null ||
        _lastStatsRefresh == null ||
        now.difference(_lastStatsRefresh!) >= _statsRefreshInterval;
    if (progress <= 0 || progress >= 1 || due) {
      _displayedStatsIndex = rawIdx;
      _lastStatsRefresh = now;
    }
    return _displayedStatsIndex!.clamp(0, bundle.replayPoints.length - 1);
  }

  void _recentre() {
    final bounds = _bounds;
    if (bounds == null) return;
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(28)),
    );
    setState(() => _hasPannedAway = false);
  }

  /// Pans the camera to track the replay marker's current position —
  /// the map follows the route start-to-end on its own instead of the
  /// user having to manually drag to keep up. Fires on every
  /// `_replayController` tick (not from `build`, so this stays a plain
  /// imperative camera move rather than a widget rebuild side effect).
  /// Backs off the moment the user pans by hand — `_recentre` is what
  /// hands control back to auto-follow.
  void _followCamera() {
    if (!_canReplay || _hasPannedAway) return;
    final progress = _replayController.value;
    if (progress <= 0 || progress >= 1) return;
    if (_routePoints.length < 2) return;
    final idx = (_revealedCount(progress) - 1).clamp(
      0,
      _routePoints.length - 1,
    );
    try {
      _mapController.move(_routePoints[idx], _mapController.camera.zoom);
    } catch (_) {
      // Controller isn't attached to a laid-out map yet (e.g. the very
      // first tick before the first frame) — next tick catches up.
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = widget.bundle;
    _bounds = _boundsForSegments(bundle);
    final bounds = _bounds;
    final centre = bounds != null
        ? LatLng(
            (bounds.north + bounds.south) / 2,
            (bounds.east + bounds.west) / 2,
          )
        : const LatLng(0, 0);
    final start = _firstPoint(bundle);
    final end = _lastPoint(bundle);
    final canReplay = _canReplay;
    // Dark backdrop behind the map. FlutterMap paints on top of whatever
    // its parent provides — before OSM tiles land on a slow connection
    // the map area was flashing bright white against our dark card
    // (~1 s on cold cache). Painting the underlying region dark first
    // means the same window shows a subtle "loading" surface in the
    // brand palette instead of a jarring white square.
    return ColoredBox(
      color: _mapBackdrop,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _replayController,
            builder: (context, _) {
              final progress = _replayController.value;
              final isReplaying = canReplay && progress > 0 && progress < 1;
              final revealed = isReplaying
                  ? _routePoints.sublist(0, _revealedCount(progress))
                  : const <LatLng>[];
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centre,
                  initialZoom: 12,
                  initialCameraFit: bounds == null
                      ? null
                      : CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.all(28),
                        ),
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && !_hasPannedAway) {
                      setState(() => _hasPannedAway = true);
                    }
                  },
                  interactionOptions: const InteractionOptions(
                    // Drag + pinch only — no rotation / doubletap. The
                    // user can reframe before screenshotting but
                    // accidental gestures can't unmoor the camera.
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    // {r} expands to "@2x" on retina screens. CartoDB
                    // ships 512 px @2x dark tiles that render city /
                    // country labels crisp white against the dark base
                    // — exactly the look the user pointed at on
                    // TripRank. The non-retina path looked soft and
                    // grey on high-DPI Android, which is what they
                    // were seeing.
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: true,
                    userAgentPackageName: 'com.bytse.drive_rank',
                    // Keep one extra ring of tiles prefetched around the
                    // viewport so panning / zooming during framing
                    // reveals already-loaded labels instead of grey
                    // squares.
                    keepBuffer: 2,
                    maxZoom: 19,
                  ),
                  PolylineLayer(
                    polylines: [
                      for (final s in bundle.segments)
                        Polyline(
                          points: s.points,
                          color: isReplaying
                              ? s.bucket.color.withValues(alpha: 0.25)
                              : s.bucket.color,
                          strokeWidth: 5,
                          borderColor: Colors.black.withValues(
                            alpha: isReplaying ? 0.15 : 0.45,
                          ),
                          borderStrokeWidth: 1.5,
                        ),
                      if (isReplaying && revealed.length > 1)
                        Polyline(
                          points: revealed,
                          color: AppColors.teal,
                          strokeWidth: 5,
                          borderColor: Colors.black.withValues(alpha: 0.45),
                          borderStrokeWidth: 1.5,
                        ),
                    ],
                  ),
                  if (start != null || end != null)
                    MarkerLayer(
                      markers: [
                        if (start != null)
                          Marker(
                            point: start,
                            width: 64,
                            height: 28,
                            alignment: Alignment.center,
                            child: const _EndpointMarker(
                              label: 'Start',
                              dotColor: AppColors.green,
                            ),
                          ),
                        if (end != null)
                          Marker(
                            point: end,
                            width: 56,
                            height: 28,
                            alignment: Alignment.center,
                            child: const _EndpointMarker(
                              label: 'End',
                              dotColor: AppColors.red,
                            ),
                          ),
                      ],
                    ),
                  if (isReplaying && revealed.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: revealed.last,
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) => _VehicleMarker(
                              vehicleType: widget.vehicleType,
                              pulseValue: _pulseController.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (canReplay && _topSpeedIndex >= 0)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: bundle.replayPoints[_topSpeedIndex].position,
                          width: 150,
                          height: 96,
                          // flutter_map's `alignment` describes where the
                          // WIDGET sits relative to the point — topCenter
                          // means the widget renders above the point, i.e.
                          // the point anchors the widget's bottom edge,
                          // which is where the ring/dot in this widget
                          // live. bottomCenter (the earlier, wrong value)
                          // put the point at the widget's TOP instead, so
                          // the ring rendered well below the real spot.
                          alignment: Alignment.topCenter,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _pulseController,
                              _replayController,
                            ]),
                            builder: (context, _) {
                              final revealedCount = _revealedCount(
                                _replayController.value,
                              );
                              final passedTopSpeed =
                                  revealedCount - 1 >= _topSpeedIndex;
                              return _TopSpeedRadarMarker(
                                pulseValue: _pulseController.value,
                                showPopover: passedTopSpeed,
                                locale: widget.locale,
                                speedKmh:
                                    bundle.replayPoints[_topSpeedIndex].speedKmh,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  RichAttributionWidget(
                    showFlutterMapAttribution: false,
                    alignment: AttributionAlignment.bottomRight,
                    popupBorderRadius: BorderRadius.circular(8),
                    attributions: const [
                      TextSourceAttribution('OpenStreetMap'),
                      TextSourceAttribution('CARTO'),
                    ],
                  ),
                ],
              );
            },
          ),
          if (canReplay)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: AnimatedBuilder(
                animation: _replayController,
                builder: (context, _) {
                  final point = bundle.replayPoints[_statsDisplayIndex(bundle)];
                  return _LiveStatsRow(locale: widget.locale, point: point);
                },
              ),
            ),
          if (_hasPannedAway)
            Positioned(
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: _RecentreButton(onTap: _recentre),
            ),
          if (canReplay)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: AnimatedBuilder(
                animation: _replayController,
                builder: (context, _) {
                  return _ReplayControlBar(
                    isPlaying: _replayController.isAnimating,
                    progress: _replayController.value,
                    speedMultiplier: _speedMultiplier,
                    onTogglePlay: _togglePlayback,
                    onMultiplierSelected: _setMultiplier,
                    onScrubStart: () => _replayController.stop(),
                    onScrubChanged: (v) =>
                        setState(() => _replayController.value = v),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Matches AppColors.bg2 (#0D0D12) — a shade darker than the section
  /// card so the "loading" surface reads as its own region under the
  /// tiles rather than blending with the card background.
  static const Color _mapBackdrop = Color(0xFF0D0D12);

  LatLngBounds? _boundsForSegments(InsightsBundle bundle) {
    if (bundle.segments.isEmpty) return null;
    final all = <LatLng>[for (final s in bundle.segments) ...s.points];
    if (all.isEmpty) return null;
    return LatLngBounds.fromPoints(all);
  }

  LatLng? _firstPoint(InsightsBundle bundle) {
    for (final s in bundle.segments) {
      if (s.points.isNotEmpty) return s.points.first;
    }
    return null;
  }

  LatLng? _lastPoint(InsightsBundle bundle) {
    for (final s in bundle.segments.reversed) {
      if (s.points.isNotEmpty) return s.points.last;
    }
    return null;
  }
}

/// Marks the replay's current position while animating — a crisp
/// vector icon for the selected vehicle (car or motorbike) instead of
/// a plain dot or an emoji glyph (which renders inconsistently across
/// devices/fonts), on a teal badge with a soft breathing halo so it
/// reads as "live" rather than static.
class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({required this.vehicleType, required this.pulseValue});

  final VehicleType vehicleType;
  final double pulseValue;

  IconData get _icon => switch (vehicleType) {
    VehicleType.car => Icons.directions_car_rounded,
    VehicleType.motorbike => Icons.two_wheeler_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: (0.4 * (1 - pulseValue)).clamp(0.0, 0.4),
          child: Transform.scale(
            scale: 1 + pulseValue * 0.7,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.teal, Color(0xFF1F8F82)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.55),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(_icon, color: Colors.white, size: 18),
        ),
      ],
    );
  }
}

/// Standing marker at the trip's fastest recorded point: a
/// continuously pulsing "radar ping" ring so the spot reads as a point
/// of interest even before playback reaches it, plus a callout bubble
/// that pops in above it the moment the replay vehicle arrives there.
class _TopSpeedRadarMarker extends StatelessWidget {
  const _TopSpeedRadarMarker({
    required this.pulseValue,
    required this.showPopover,
    required this.locale,
    required this.speedKmh,
  });

  final double pulseValue;
  final bool showPopover;
  final LocaleService locale;
  final double speedKmh;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            alignment: Alignment.bottomCenter,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: showPopover
              ? Padding(
                  key: const ValueKey('popover'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TopSpeedPopover(locale: locale, speedKmh: speedKmh),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
        SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Stable ring — always visible, so the spot reads clearly
              // even between pulse cycles, not just at the animation's
              // brightest frame.
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
              ),
              Opacity(
                opacity: ((1 - pulseValue) * 0.9).clamp(0.0, 0.9),
                child: Transform.scale(
                  scale: 0.5 + pulseValue * 1.8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.orange, width: 2.5),
                    ),
                  ),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopSpeedPopover extends StatelessWidget {
  const _TopSpeedPopover({required this.locale, required this.speedKmh});

  final LocaleService locale;
  final double speedKmh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'TOP SPEED ${locale.formatSpeed(speedKmh)}',
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.bg,
        ),
      ),
    );
  }
}

/// Bottom control strip for the replay: play/pause, a draggable scrub
/// bar, and a 1x/2x/3x speed multiplier — one translucent bar so the
/// controls read as map chrome rather than floating app UI.
class _ReplayControlBar extends StatelessWidget {
  const _ReplayControlBar({
    required this.isPlaying,
    required this.progress,
    required this.speedMultiplier,
    required this.onTogglePlay,
    required this.onMultiplierSelected,
    required this.onScrubStart,
    required this.onScrubChanged,
  });

  final bool isPlaying;
  final double progress;
  final int speedMultiplier;
  final VoidCallback onTogglePlay;
  final ValueChanged<int> onMultiplierSelected;
  final VoidCallback onScrubStart;
  final ValueChanged<double> onScrubChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _PlayPauseButton(isPlaying: isPlaying, onTap: onTogglePlay),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: AppColors.teal,
                inactiveTrackColor: AppColors.border2,
                thumbColor: AppColors.teal,
              ),
              child: Slider(
                value: progress.clamp(0, 1),
                onChangeStart: (_) => onScrubStart(),
                onChanged: onScrubChanged,
              ),
            ),
          ),
          for (final m in const [1, 2, 3])
            _MultiplierChip(
              multiplier: m,
              isSelected: m == speedMultiplier,
              onTap: () => onMultiplierSelected(m),
            ),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _MultiplierChip extends StatelessWidget {
  const _MultiplierChip({
    required this.multiplier,
    required this.isSelected,
    required this.onTap,
  });

  final int multiplier;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.teal : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            '${multiplier}x',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.bg : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Live Speed / Distance / Time readout that steps through the
/// replay's [ReplayPoint] series — a label above a large bold number
/// per stat, laid straight over the map with a text shadow for
/// legibility rather than a background chip.
class _LiveStatsRow extends StatelessWidget {
  const _LiveStatsRow({required this.locale, required this.point});

  final LocaleService locale;
  final ReplayPoint point;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatBlock(
          label: 'SPEED',
          value: locale.formatSpeedValue(point.speedKmh),
          unitBelow: locale.speedUnitLabel,
        ),
        const SizedBox(width: 22),
        _StatBlock(
          label: 'DISTANCE',
          value: locale.formatDistance(point.cumulativeDistanceKm),
        ),
        const SizedBox(width: 22),
        _StatBlock(label: 'TIME', value: _elapsedClock(point.secondsFromStart)),
      ],
    );
  }

  String _elapsedClock(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value, this.unitBelow});

  final String label;
  final String value;
  final String? unitBelow;

  static const List<Shadow> _shadow = [
    Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 1.1,
            shadows: _shadow,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.05,
            shadows: _shadow,
          ),
        ),
        if (unitBelow != null)
          Text(
            unitBelow!,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              color: Colors.white70,
              shadows: _shadow,
            ),
          ),
      ],
    );
  }
}

/// Appears once the user pans/zooms away from the trip's framed
/// bounds — snaps the camera back.
class _RecentreButton extends StatelessWidget {
  const _RecentreButton({required this.onTap});

  final VoidCallback onTap;

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _EndpointMarker extends StatelessWidget {
  const _EndpointMarker({required this.label, required this.dotColor});

  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: dotColor.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Speed Ranges card rendered below the map — title + 4 rows of
/// coloured bar + km/h (or mph) range. Matches the TripRank reference
/// the user pointed to: a proper card chrome with a clear hierarchy,
/// not a chip strip.
///
/// Numeric thresholds come from `SpeedBucket` constants and run
/// through [LocaleService] so an mph user reads "25 – 50 mph", not
/// "40 – 80 km/h".
class JourneyMapLegend extends StatelessWidget {
  const JourneyMapLegend({required this.locale, super.key});

  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Speed Ranges',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < SpeedBucket.values.length; i++) ...[
            _Row(bucket: SpeedBucket.values[i], locale: locale),
            if (i != SpeedBucket.values.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.bucket, required this.locale});

  final SpeedBucket bucket;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Short coloured pill — the visual key for this band.
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: bucket.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _label(),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Returns the inclusive-exclusive range label, locale-aware.
  /// Examples (metric):  "< 40 km/h", "40 – 80 km/h", "> 120 km/h".
  /// Examples (imperial):"< 25 mph",  "25 – 50 mph",   "> 75 mph".
  String _label() {
    final unit = locale.speedUnitLabel;
    final lo = locale.formatSpeedValue(bucket.minKmh);
    final hi = bucket.maxKmh;
    if (bucket.minKmh == 0 && hi != null) {
      return '< ${locale.formatSpeedValue(hi)} $unit';
    }
    if (hi == null) {
      return '> $lo $unit';
    }
    return '$lo – ${locale.formatSpeedValue(hi)} $unit';
  }
}
