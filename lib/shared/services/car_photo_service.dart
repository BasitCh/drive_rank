import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Picks a car photo from the camera or the gallery and persists it
/// to the app's documents directory under `car_photos/`.
///
/// **Why the copy step matters:** `image_picker` returns a path in
/// the OS's temp cache. Android wipes that cache aggressively (OS
/// cleanup, app updates, low-storage events) so a path stored in
/// Drift could point at a missing file after the next boot. Copying
/// to documents — which Android promises to keep for the app's
/// lifetime — guarantees the photo survives.
@lazySingleton
class CarPhotoService {
  CarPhotoService();

  /// Picks an image from [source] and returns the persisted path.
  /// Returns `null` if the user cancels or the OS denies access.
  Future<String?> pickAndStore(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        // 1600px keeps the photo crisp on a 3× exported stat card
        // without bloating storage on cheap Android devices.
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (picked == null) return null;
      return persist(picked.path);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CarPhotoService] pickAndStore failed: $e\n$st');
      }
      return null;
    }
  }

  /// Copies [tempPath] into the documents directory and returns the
  /// new absolute path. Visible so tests / wrappers can persist a
  /// pre-picked file without going through the picker.
  Future<String?> persist(String tempPath) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final carDir = Directory(p.join(docs.path, 'car_photos'));
      if (!carDir.existsSync()) {
        await carDir.create(recursive: true);
      }
      final ext = p.extension(tempPath).isEmpty
          ? '.jpg'
          : p.extension(tempPath);
      final dest = p.join(
        carDir.path,
        'car_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      final src = File(tempPath);
      if (!src.existsSync()) return null;
      final saved = await src.copy(dest);
      if (kDebugMode) {
        debugPrint('[CarPhotoService] ✓ persisted ${saved.path}');
      }
      return saved.path;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CarPhotoService] ✗ persist failed: $e\n$st');
      }
      return null;
    }
  }

  /// Deletes the persisted photo at [path] if it exists in our
  /// documents directory. Safe to call with `null` or a path outside
  /// the car_photos dir (no-op then).
  Future<void> tryDelete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final carDir = p.join(docs.path, 'car_photos');
      if (!path.startsWith(carDir)) return;
      final f = File(path);
      if (f.existsSync()) {
        await f.delete();
        if (kDebugMode) {
          debugPrint('[CarPhotoService] deleted $path');
        }
      }
    } catch (_) {
      // Best-effort; orphan files are harmless.
    }
  }
}
