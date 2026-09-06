import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsRow;
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/shared/models/car_category.dart';
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

  /// The viewer's settings row, for their own car art. Only the viewer's
  /// identity is known locally; other real drivers arrive with the
  /// remote phase and will carry their own.
  final UserSettingsRow? viewer;

  /// Overrides the default ring — the podium passes medal colours so
  /// first, second and third read as places rather than as three
  /// identical circles.
  final Color? ringColor;

  /// Whether to badge the circle with the viewer's country flag.
  ///
  /// Only ever true for the viewer, and only when they've set a country.
  /// A benchmark is not from anywhere — giving one a flag would invent a
  /// nationality for a constant, and the absence is itself the signal
  /// that this entry isn't a person.
  final bool showFlag;

  @override
  Widget build(BuildContext context) {
    final defaultRing = entry.isCurrentUser
        ? AppColors.teal
        : AppColors.border2;
    final flag = showFlag && !entry.isBenchmark
        ? countryFromCode(viewer?.country ?? '')?.flag
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
          : _CarArt(diameter: diameter, viewer: viewer),
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
  const _CarArt({required this.diameter, required this.viewer});

  final double diameter;
  final UserSettingsRow? viewer;

  @override
  Widget build(BuildContext context) {
    final settings = viewer;
    if (settings == null) {
      // A real driver whose vehicle we don't know (only possible for
      // someone other than the viewer, i.e. once remote entries exist).
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
