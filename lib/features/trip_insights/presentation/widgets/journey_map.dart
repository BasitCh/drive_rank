import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_bucket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Dark-themed map with the speed-coloured polyline + explicit START /
/// END markers. Fills the Journey card's vertical real estate per
/// spec (~70 % of the card).
///
/// Basemap: CartoDB Dark Matter tiles — pre-rendered dark style with
/// legible white labels. Earlier versions filtered OSM Carto-light at
/// runtime with a `ColorFilter` matrix, which mangled label contrast
/// (the user couldn't read country names) and cost a GPU pass per
/// tile per frame. Dark tiles render natively, no filter required.
/// Attribution rendered bottom-right via flutter_map's
/// `RichAttributionWidget`.
class JourneyMap extends StatefulWidget {
  const JourneyMap({required this.bundle, super.key});

  final InsightsBundle bundle;

  @override
  State<JourneyMap> createState() => _JourneyMapState();
}

class _JourneyMapState extends State<JourneyMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _replayController;
  late List<LatLng> _routePoints;

  @override
  void initState() {
    super.initState();
    _replayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _routePoints = _flattenPoints(widget.bundle);
  }

  @override
  void didUpdateWidget(covariant JourneyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bundle != widget.bundle) {
      _routePoints = _flattenPoints(widget.bundle);
      _replayController.reset();
    }
  }

  @override
  void dispose() {
    _replayController.dispose();
    super.dispose();
  }

  void _replay() {
    if (_routePoints.length < 2) return;
    _replayController.forward(from: 0);
  }

  /// Points revealed by the current replay progress. Keyed off point
  /// *index* rather than geographic distance — waypoints are logged at
  /// a roughly fixed sampling interval, so index position already
  /// tracks elapsed trip time (a highway segment isn't sampled any
  /// denser than a slow one), which is what a "replay" should follow.
  List<LatLng> _revealedPoints(double progress) {
    if (_routePoints.length < 2) return _routePoints;
    final count = (_routePoints.length * progress).ceil().clamp(
      1,
      _routePoints.length,
    );
    return _routePoints.sublist(0, count);
  }

  @override
  Widget build(BuildContext context) {
    final bundle = widget.bundle;
    final bounds = _boundsForSegments(bundle);
    final centre = bounds != null
        ? LatLng(
            (bounds.north + bounds.south) / 2,
            (bounds.east + bounds.west) / 2,
          )
        : const LatLng(0, 0);
    final start = _firstPoint(bundle);
    final end = _lastPoint(bundle);
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
              final isReplaying = progress > 0 && progress < 1;
              final revealed = isReplaying
                  ? _revealedPoints(progress)
                  : const <LatLng>[];
              return FlutterMap(
                options: MapOptions(
                  initialCenter: centre,
                  initialZoom: 12,
                  initialCameraFit: bounds == null
                      ? null
                      : CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.all(28),
                        ),
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
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          child: const _ReplayPuck(),
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
          if (_routePoints.length > 1)
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _ReplayButton(onTap: _replay),
            ),
        ],
      ),
    );
  }

  /// Matches AppColors.bg2 (#0D0D12) — a shade darker than the section
  /// card so the "loading" surface reads as its own region under the
  /// tiles rather than blending with the card background.
  static const Color _mapBackdrop = Color(0xFF0D0D12);

  List<LatLng> _flattenPoints(InsightsBundle bundle) {
    return [for (final s in bundle.segments) ...s.points];
  }

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

/// Small dot marking the replay's current position while animating.
class _ReplayPuck extends StatelessWidget {
  const _ReplayPuck();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.teal,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.6),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

/// Circular "replay route" trigger, bottom-right of the map — dark
/// translucent so it reads as part of the map chrome (same idiom as
/// [_EndpointMarker]'s pill) rather than a floating app button.
class _ReplayButton extends StatelessWidget {
  const _ReplayButton({required this.onTap});

  final VoidCallback onTap;

  static const double _size = 40;

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
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 22,
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
