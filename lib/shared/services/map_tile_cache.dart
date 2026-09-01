import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

/// Disk-backed cache manager for map tiles, separate from the default
/// cache manager (shared with car photos etc.) so tile eviction doesn't
/// compete with other cached images.
///
/// Tiles are kept for 60 days and up to 8,000 of them — generous for a
/// driving app since a single trip's replay can touch a few hundred
/// tiles across zoom levels. Once a trip's route has been viewed with
/// a connection, its tiles stay on disk and render from there with no
/// network required, giving offline access to previously-seen trips
/// without needing to pre-download whole regions.
class MapTileCacheManager extends CacheManager {
  factory MapTileCacheManager() => _instance;

  MapTileCacheManager._()
    : super(
        Config(
          _key,
          stalePeriod: const Duration(days: 60),
          maxNrOfCacheObjects: 8000,
        ),
      );

  static const _key = 'mapTileCache';
  static final MapTileCacheManager _instance = MapTileCacheManager._();
}

/// [TileProvider] that serves tiles through [MapTileCacheManager] instead
/// of a bare network fetch, so every tile that's ever been displayed is
/// available offline afterwards.
class OfflineCachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      cacheManager: MapTileCacheManager(),
      headers: headers,
    );
  }
}
