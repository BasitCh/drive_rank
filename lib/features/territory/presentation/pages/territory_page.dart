import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/hex_grid_service.dart';
import 'package:drive_rank/shared/models/territory_stats.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/map_basemap.dart';
import 'package:drive_rank/shared/services/map_tile_cache.dart';
import 'package:drive_rank/shared/services/territory_stats_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// Full-screen "everything you've conquered" map — every hex cell (see
/// `HexGridService`) the user has ever driven through, across every
/// trip, filled in on top of a real map (see `MapBasemap`).
///
/// Structurally modeled on `JourneyMap` (same basemap resolution, same
/// attribution style, same offline tile caching) but renders a
/// `PolygonLayer` of visited cells instead of a route `Polyline`,
/// camera-fit once to the visited area rather than animated replay.
class TerritoryPage extends StatefulWidget {
  const TerritoryPage({super.key});

  @override
  State<TerritoryPage> createState() => _TerritoryPageState();
}

class _TerritoryPageState extends State<TerritoryPage> {
  final MapController _mapController = MapController();
  late Future<TerritoryStats> _future;
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TerritoryStats> _load() async {
    final settings = await getIt<UserSettingsRepository>().read();
    _countryCode = settings.country;
    return getIt<TerritoryStatsService>().territory(
      uid: settings.uid,
      countryCode: settings.country,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder<TerritoryStats>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  );
                }
                if (snap.data!.cellCount == 0) {
                  // No trips yet — a map centred on (0,0) with nothing to
                  // show reads as broken, not "loading". A clear empty
                  // state is more honest than a blank ocean tile view.
                  return const _EmptyTerritoryState();
                }
                return _Map(stats: snap.data!, mapController: _mapController);
              },
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _BackButton(
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/profile'),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          AppStrings.profileTerritoryPageTitle,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<TerritoryStats>(
                    future: _future,
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      return _SummaryCard(
                        stats: snap.data!,
                        countryCode: _countryCode,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of `_Map` when the user hasn't driven any trips yet —
/// with no cells to fit a camera to, the map would otherwise default to
/// `LatLng(0, 0)` (open ocean) and read as broken rather than empty.
class _EmptyTerritoryState extends StatelessWidget {
  const _EmptyTerritoryState();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _Map._basemap.backdropColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.hexagon_outlined,
                  color: AppColors.teal,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                AppStrings.profileTerritoryEmptyTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.profileTerritoryEmptyBody,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.stats, required this.mapController});

  final TerritoryStats stats;
  final MapController mapController;

  static final MapBasemap _basemap = MapBasemap.resolve();

  /// The reference app fills conquered cells in a warm terracotta —
  /// distinct from this app's teal brand accent (used for the small
  /// hexagon glyph on the Profile card), matched here via the existing
  /// orange token rather than a new one-off hex constant.
  static const Color _conqueredFill = AppColors.orange;

  @override
  Widget build(BuildContext context) {
    final polygons = [
      for (final id in stats.cellIds)
        Polygon(
          points: HexGridService.cellCorners(id),
          color: _conqueredFill.withValues(alpha: 0.45),
          borderColor: _conqueredFill.withValues(alpha: 0.8),
          borderStrokeWidth: 1,
        ),
    ];
    final bounds = polygons.isEmpty
        ? null
        : LatLngBounds.fromPoints([for (final p in polygons) ...p.points]);

    return ColoredBox(
      color: _basemap.backdropColor,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: bounds == null
              ? const LatLng(0, 0)
              : LatLng(
                  (bounds.north + bounds.south) / 2,
                  (bounds.east + bounds.west) / 2,
                ),
          initialZoom: 12,
          initialCameraFit: bounds == null
              ? null
              : CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: _basemap.urlTemplate,
            additionalOptions: _basemap.additionalOptions,
            userAgentPackageName: 'com.bytse.drive_rank',
            tileProvider: OfflineCachedTileProvider(),
            keepBuffer: 2,
            maxZoom: 19,
          ),
          if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
          RichAttributionWidget(
            showFlutterMapAttribution: false,
            alignment: AttributionAlignment.bottomRight,
            popupBorderRadius: BorderRadius.circular(8),
            attributions: _basemap.attributions,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats, required this.countryCode});

  final TerritoryStats stats;
  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${stats.cellCount} territories',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${stats.areaKm2.toStringAsFixed(1)} km²',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _PercentChip(
                label: AppStrings.profileTerritoryOfEarth,
                value: stats.percentOfEarth,
              ),
              if (stats.percentOfCountry != null && countryCode != null)
                _PercentChip(
                  label: countryCode!.toUpperCase(),
                  value: stats.percentOfCountry!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PercentChip extends StatelessWidget {
  const _PercentChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.microLabel.copyWith(fontSize: 10)),
          const SizedBox(width: 6),
          Text(
            '${value.toStringAsFixed(value < 1 ? 4 : 2)}%',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
