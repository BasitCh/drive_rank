import 'dart:io';

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/shared/models/car_category.dart';
import 'package:flutter/material.dart';

/// Renders a car make as either:
///   - The user's uploaded photo (if [photoPath] points to an existing file).
///   - A solid teal circle with a white category glyph (else) — motorbikes
///     get a motorcycle icon, every 4-wheel category shares one filled car
///     icon. A third-party vehicle-icon package would let each body style
///     (sedan/SUV/hatchback/pickup/sports) get its own silhouette, but every
///     option evaluated (`phosphor_flutter`, `iconsax_flutter`,
///     `solar_icons`) either fails to build against the current Flutter SDK
///     (`IconData` is now a `final` class; packages that subclass it don't
///     compile) or is missing a motorcycle glyph — so this uses Flutter's
///     own bundled icons instead, in a solid-fill badge rather than a thin
///     outline, which reads as considerably more polished than the old
///     hand-drawn per-category line-art SVGs it replaces.
///
/// Used in the onboarding car picker, the live tracking header avatar, the
/// stat card car tag, and the profile screen. Centralised so we never
/// duplicate the photo-or-icon fallback logic across surfaces.
class CarSilhouette extends StatelessWidget {
  const CarSilhouette({
    required this.category,
    super.key,
    this.photoPath,
    this.fit = BoxFit.contain,
    this.size,
  });

  /// Visual category — drives the icon fallback.
  final CarCategory category;

  /// Absolute filesystem path to the user's uploaded car photo. If non-null
  /// and the file exists, takes precedence over the icon.
  final String? photoPath;

  final BoxFit fit;

  /// Optional fixed size. When omitted the widget fills its parent —
  /// callers wrap in `SizedBox` / `AspectRatio` to size it responsively.
  final Size? size;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        photoPath != null &&
        photoPath!.trim().isNotEmpty &&
        File(photoPath!).existsSync();

    final child = hasPhoto
        ? ClipOval(
            child: Image.file(
              File(photoPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _CategoryBadge(category: category),
            ),
          )
        : _CategoryBadge(category: category);

    if (size == null) return child;
    return SizedBox(width: size!.width, height: size!.height, child: child);
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final CarCategory category;

  @override
  Widget build(BuildContext context) {
    final icon = category == CarCategory.motorbike
        ? Icons.motorcycle_rounded
        : Icons.directions_car_filled_rounded;
    return LayoutBuilder(
      builder: (_, constraints) {
        final side = constraints.biggest.shortestSide;
        // Falls back to a sane default when the parent gives unbounded
        // constraints (e.g. no SizedBox/AspectRatio wrapper).
        final boxSide = side.isFinite ? side : 40.0;
        return Container(
          width: boxSide,
          height: boxSide,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.teal,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: boxSide * 0.56, color: Colors.white),
        );
      },
    );
  }
}
