import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_bucket.dart';
import 'package:drive_rank/features/trip_insights/presentation/widgets/insights_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Speed-coloured route on top of an OSM-tiled flutter_map.
///
/// Pre-computed `SpeedSegment`s render one `Polyline` each — a 5000-
/// waypoint trip ends up at 30-80 segments after grouping, which fits
/// in a single frame. Boundary points are shared between adjacent
/// segments so the colour transitions are gap-free.
///
/// Naming kept generic ("intensity") so a future heatmap pass (g-force,
/// braking density, etc.) can reuse the same surface.
class SpeedIntensityMap extends StatelessWidget {
  const SpeedIntensityMap({
    required this.bundle,
    required this.locale,
    super.key,
  });

  final InsightsBundle bundle;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final bounds = _boundsForSegments(bundle);
    final fallbackCentre =
        bounds != null ? LatLng((bounds.north + bounds.south) / 2,
            (bounds.east + bounds.west) / 2) : const LatLng(0, 0);
    return InsightsSectionCard(
      title: 'Speed-Coloured Route',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              height: 240,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: fallbackCentre,
                  initialZoom: 12,
                  initialCameraFit: bounds == null
                      ? null
                      : CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.all(24),
                        ),
                  interactionOptions: const InteractionOptions(
                    // Static-ish presentation — drag/zoom allowed for
                    // exploration but no rotation or doubletap zoom so
                    // accidental gestures don't reset the screenshot
                    // framing.
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bytse.drive_rank',
                    // OSM's Carto-light is too bright for the dark
                    // theme — colourize the default tiles to fit by
                    // overlaying a dark blend below.
                    tileBuilder: _darkenTile,
                  ),
                  PolylineLayer(
                    polylines: [
                      for (final s in bundle.segments)
                        Polyline(
                          points: s.points,
                          color: s.bucket.color,
                          strokeWidth: 4.5,
                          borderColor: Colors.black.withValues(alpha: 0.3),
                          borderStrokeWidth: 1.5,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Legend(locale: locale),
        ],
      ),
    );
  }

  /// Bounding box covering every polyline. Returns null if there's
  /// nothing to show — the caller falls back to a zero centre with the
  /// default zoom level.
  LatLngBounds? _boundsForSegments(InsightsBundle bundle) {
    if (bundle.segments.isEmpty) return null;
    final all = <LatLng>[
      for (final s in bundle.segments) ...s.points,
    ];
    if (all.isEmpty) return null;
    return LatLngBounds.fromPoints(all);
  }

  /// Dims the tile so the bright OSM Carto-light fits a dark app
  /// surface. ColorFiltered would be simpler but bleeds into adjacent
  /// pixels; Stack + IgnorePointer overlay is the pattern flutter_map's
  /// own examples use for theming.
  Widget _darkenTile(BuildContext context, Widget tileWidget, _) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        // Soft luminance reduction + mild blue tint to harmonise with
        // AppColors.bg. Matches the existing route_strip mood.
        0.45, 0, 0, 0, 8,
        0, 0.45, 0, 0, 8,
        0, 0, 0.50, 0, 12,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.locale});

  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final bucket in SpeedBucket.values)
          _LegendChip(label: _labelFor(bucket), color: bucket.color),
      ],
    );
  }

  String _labelFor(SpeedBucket bucket) {
    final min = locale.formatSpeed(bucket.minKmh).split(' ').first;
    final max = bucket.maxKmh;
    if (max == null) return '$min+ ${locale.speedUnitLabel}';
    final maxLabel = locale.formatSpeed(max).split(' ').first;
    return '$min–$maxLabel ${locale.speedUnitLabel}';
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
