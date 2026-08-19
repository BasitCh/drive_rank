import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a `RepaintBoundary` to a PNG and hands it to the OS share
/// sheet (Twitter, WhatsApp, TikTok save, …) or saves to a temp file.
///
/// 3× pixel ratio matches the spec — looks crisp on 3x device screens
/// when re-shared and still uploads in <500 KB on a typical stat card.
@lazySingleton
class CardExportService {
  CardExportService();

  /// Render the boundary attached to [boundaryKey] to a PNG byte buffer.
  Future<Uint8List?> capture(GlobalKey boundaryKey) async {
    final ctx = boundaryKey.currentContext;
    if (ctx == null) return null;
    final renderObj = ctx.findRenderObject();
    if (renderObj is! RenderRepaintBoundary) return null;

    final image = await renderObj.toImage(
      pixelRatio: AppConstants.cardExportPixelRatio,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  /// Write [bytes] to a temp file and call the OS share sheet.
  Future<void> share(Uint8List bytes, {String? subject}) async {
    final file = await _writeTempPng(bytes);
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'image/png'),
    ], subject: subject ?? AppStrings.tripSummaryShareSubject);
  }

  /// Capture-and-share in one call. Returns false if capture failed (boundary
  /// not mounted yet) — the caller can surface a toast.
  Future<bool> captureAndShare(GlobalKey boundaryKey, {String? subject}) async {
    final bytes = await capture(boundaryKey);
    if (bytes == null) return false;
    await share(bytes, subject: subject);
    return true;
  }

  /// Captures every boundary in [boundaryKeys] and shares whichever
  /// ones succeed as a single multi-image share sheet — e.g. the top
  /// speed card plus the speed-over-time chart card in one tap.
  /// Boundaries that fail to capture (not mounted, e.g. a chart hidden
  /// for a too-short trip) are silently skipped rather than aborting
  /// the whole share. Returns false only if nothing could be captured.
  Future<bool> captureMultipleAndShare(
    List<GlobalKey> boundaryKeys, {
    String? subject,
  }) async {
    final files = <XFile>[];
    for (final key in boundaryKeys) {
      final bytes = await capture(key);
      if (bytes == null) continue;
      final file = await _writeTempPng(bytes);
      files.add(XFile(file.path, mimeType: 'image/png'));
    }
    if (files.isEmpty) return false;
    await Share.shareXFiles(
      files,
      subject: subject ?? AppStrings.tripSummaryShareSubject,
    );
    return true;
  }

  Future<File> _writeTempPng(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'driverank-trip-$stamp.png'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
