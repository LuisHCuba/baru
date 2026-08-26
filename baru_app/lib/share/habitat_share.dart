import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

class HabitatShare {
  HabitatShare._();

  static Future<Uint8List?> capturePng(GlobalKey boundaryKey) async {
    final ctx = boundaryKey.currentContext;
    if (ctx == null) return null;
    final obj = ctx.findRenderObject();
    if (obj is! RenderRepaintBoundary) return null;
    try {
      final image = await obj.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Baru share capture: $e');
      return null;
    }
  }

  static Future<bool> share({
    required GlobalKey boundaryKey,
    required String text,
  }) async {
    final png = await capturePng(boundaryKey);
    try {
      if (png != null) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(png, mimeType: 'image/png', name: 'habitat.png'),
            ],
            fileNameOverrides: const ['habitat.png'],
            text: text,
            downloadFallbackEnabled: true,
          ),
        );
        return true;
      }
    } catch (e) {
      debugPrint('Baru share file: $e');
    }
    try {
      await SharePlus.instance.share(ShareParams(text: text));
      return true;
    } catch (e) {
      debugPrint('Baru share text: $e');
      return false;
    }
  }
}
