import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsRow;
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/shared/models/car_category.dart';
import 'package:drive_rank/shared/models/car_make_icons.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/widgets/car_silhouette.dart';
import 'package:flutter/material.dart';

/// The circular identity on a leaderboard row or podium tile.
///
/// A real driver gets their own vehicle — their uploaded photo, or the
/// make/category silhouette `CarSilhouette` already renders everywhere
/// else — inside a teal ring, so the board shows their driving identity
/// rather than an anonymous initial.
///
/// A benchmark gets a **stylized gauge glyph and never an avatar**: no
/// photo, no silhouette, no flag, nothing that could be mistaken for a
/// person's likeness. That's the whole point of the distinction, and it
/// holds at every size the podium and list use.
///
/// Two sources of identity, and which one applies is decided by whose
/// row it is:
///  * the **viewer** is drawn from their settings row, which is always
///    fresher than anything they published and is the only place a
///    photo exists;
///  * a **friend** is drawn from what they published — their make, and
///    their country for the flag. No photo, because the mirror
///    deliberately doesn't carry one.
class RankIdentity extends StatelessWidget {
  const RankIdentity({
    required this.entry,
    required this.diameter,
    this.viewer,
    this.ringColor,
    this.showFlag = false,
    super.key,
  });

  final LeaderboardEntry entry;
  final double diameter;

  /// The viewer's settings row, for their own car art. Used only on the
  /// viewer's own row — a friend's art comes off their entry, so passing
  /// this down every row can't leak the viewer's photo onto somebody
  /// else's circle.
  final UserSettingsRow? viewer;

  /// Overrides the default ring — the podium passes medal colours so
  /// first, second and third read as places rather than as three
  /// identical circles.
  final Color? ringColor;

  /// Whether to badge the circle with this driver's country flag.
  ///
  /// True for a person who has a country — the viewer's from settings, a
  /// friend's from their mirror. **Never for a benchmark**, which is not
  /// from anywhere: giving one a flag would invent a nationality for a
  /// constant, and the absence is itself the signal that this entry
  /// isn't a person.
  final bool showFlag;

  @override
  Widget build(BuildContext context) {
    final defaultRing = entry.isCurrentUser
        ? AppColors.teal
        : AppColors.border2;
    // The viewer's country comes from settings, everyone else's from
    // what they published — never the other way round, or one person's
    // flag would end up on another's row.
    final countryCode = entry.isCurrentUser
        ? (viewer?.country ?? '')
        : entry.countryCode;
    final flag = showFlag && !entry.isBenchmark
        ? countryFromCode(countryCode)?.flag
        : null;

    final circle = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(
          color: ringColor ?? defaultRing,
          width: entry.isCurrentUser || ringColor != null ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: entry.isBenchmark
          ? Center(
              child: Icon(
                Icons.speed_rounded,
                size: diameter * 0.44,
                color: AppColors.textTertiary,
              ),
            )
          : _CarArt(
              diameter: diameter,
              viewer: entry.isCurrentUser ? viewer : null,
              entry: entry,
            ),
    );

    if (flag == null) return circle;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          Positioned(
            right: -3,
            bottom: -3,
            // Fixed square with the glyph centred inside it: an emoji's
            // drawn width is wider than its font size, so sizing the
            // badge from the text clipped the flag against the circle.
            child: Container(
              width: diameter * 0.42,
              height: diameter * 0.42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bg,
                border: Border.all(color: AppColors.bg, width: 2),
              ),
              child: Text(
                flag,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: diameter * 0.24, height: 1.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarArt extends StatelessWidget {
  const _CarArt({
    required this.diameter,
    required this.viewer,
    required this.entry,
  });

  final double diameter;

  /// Non-null only on the viewer's own row.
  final UserSettingsRow? viewer;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final settings = viewer;
    if (settings == null) {
      // Somebody else: their make is all we have, because the mirror
      // publishes no photo and no vehicle category. A make we hold art
      // for gets its own outline; anything else gets the generic car
      // rather than a person glyph, since what's known about them is
      // that they drive, not what they look like.
      if (entry.carMake.trim().isNotEmpty) {
        return Padding(
          padding: EdgeInsets.all(diameter * 0.16),
          child: CarSilhouette(
            category: CarCategory.defaultCategory,
            makeId: makeIdFromDisplayName(entry.carMake),
          ),
        );
      }
      // A driver who hasn't set a car at all.
      return const Center(
        child: Icon(
          Icons.person_rounded,
          size: 20,
          color: AppColors.textTertiary,
        ),
      );
    }

    final hasPhoto =
        settings.carPhotoPath != null && settings.carPhotoPath!.isNotEmpty;
    final category = settings.vehicleType == VehicleType.motorbike.id
        ? CarCategory.motorbike
        : CarCategory.defaultCategory;

    return Padding(
      // Line-art silhouettes need breathing room inside the ring; a
      // photo should fill it.
      padding: EdgeInsets.all(hasPhoto ? 0 : diameter * 0.16),
      child: CarSilhouette(
        category: category,
        photoPath: settings.carPhotoPath,
        fit: hasPhoto ? BoxFit.cover : BoxFit.contain,
      ),
    );
  }
}
