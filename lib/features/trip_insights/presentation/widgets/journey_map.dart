import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
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
class JourneyMap extends StatelessWidget {
  const JourneyMap({required this.bundle, super.key});

  final InsightsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final bounds = _boundsForSegments(bundle);
    final centre = bounds != null
        ? LatLng(
            (bounds.north + bounds.south) / 2,
            (bounds.east + bounds.west) / 2,
          )
        : const LatLng(0, 0);
    final start = _firstPoint(bundle);
    final end = _lastPoint(bundle);
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
          // Drag + pinch only — no rotation / doubletap. The user can
          // reframe before screenshotting but accidental gestures
          // can't unmoor the camera.
          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: true,
          userAgentPackageName: 'com.bytse.drive_rank',
          // No tileBuilder filter — Dark Matter is already dark with
          // legible labels. Filtering on top would only crush contrast.
        ),
        PolylineLayer(
          polylines: [
            for (final s in bundle.segments)
              Polyline(
                points: s.points,
                color: s.bucket.color,
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
  }

  LatLngBounds? _boundsForSegments(InsightsBundle bundle) {
    if (bundle.segments.isEmpty) return null;
    final all = <LatLng>[
      for (final s in bundle.segments) ...s.points,
    ];
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

/// Compact horizontal speed legend rendered below the map.
class JourneyMapLegend extends StatelessWidget {
  const JourneyMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final entry in _legendEntries)
          _Chip(label: entry.$1, color: entry.$2),
      ],
    );
  }

  // Bucket → human label. The numeric thresholds are intentionally
  // omitted here — the legend in the screenshot reads cleaner as
  // descriptive words ("Slow / Cruising / Fast / Very Fast") than as
  // a tooltip of km/h ranges.
  static const List<(String, Color)> _legendEntries = [
    ('Slow', AppColors.red),
    ('Cruising', AppColors.orange),
    ('Fast', AppColors.green),
    ('Very Fast', AppColors.teal),
  ];
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
