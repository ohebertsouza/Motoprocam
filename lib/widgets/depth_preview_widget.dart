import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/depth_map.dart';

class DepthPreviewWidget extends StatelessWidget {
  final DepthMap depthMap;
  final double opacity;

  const DepthPreviewWidget({
    super.key,
    required this.depthMap,
    this.opacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = _buildPreview(depthMap.normalized());
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  Uint8List _buildPreview(DepthMap map) {
    final preview = img.Image(width: map.width, height: map.height);
    for (int y = 0; y < map.height; y++) {
      for (int x = 0; x < map.width; x++) {
        final d = map.depthAt(x, y);
        final g = ((1.0 - d) * 255).round().clamp(0, 255);
        preview.setPixelRgba(x, y, g, g, g, 255);
      }
    }
    return Uint8List.fromList(img.encodeJpg(preview, quality: 70));
  }
}
