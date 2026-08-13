import 'dart:io';

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/shared/models/car_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a car make as either:
///   - The user's uploaded photo (if [photoPath] points to an existing file).
///   - The category-appropriate SVG silhouette (else).
///
/// Used in the onboarding car picker, the live tracking header avatar, the
/// stat card car tag, and the profile screen. Centralised so we never
/// duplicate the photo-or-svg fallback logic across surfaces.
class CarSilhouette extends StatelessWidget {
  const CarSilhouette({
    required this.category,
    super.key,
    this.photoPath,
    this.fit = BoxFit.contain,
    this.size,
  });

  /// Visual category — drives the SVG fallback.
  final CarCategory category;

  /// Absolute filesystem path to the user's uploaded car photo. If non-null
  /// and the file exists, takes precedence over the SVG.
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
              errorBuilder: (_, __, ___) => _buildSvg(),
            ),
          )
        : _buildSvg();

    if (size == null) return child;
    return SizedBox(width: size!.width, height: size!.height, child: child);
  }

  Widget _buildSvg() {
    return SvgPicture.asset(
      category.svgAssetPath,
      fit: fit,
      // The SVGs ship with #3ECFBF strokes — never re-tint at render time
      // unless a future theme variant needs it.
      colorFilter: null,
      placeholderBuilder: (_) => const _SvgFallback(),
    );
  }
}

/// Tiny placeholder rendered while the SVG decodes — keeps the layout
/// stable on cold start. Just a faint teal ring.
class _SvgFallback extends StatelessWidget {
  const _SvgFallback();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final side = constraints.biggest.shortestSide * 0.6;
        return Center(
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
