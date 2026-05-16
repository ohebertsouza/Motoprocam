import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/depth_map.dart';
import '../models/portrait_effect_settings.dart';
import '../utils/bokeh_renderer.dart';
import 'depth_detection_service.dart';
import 'super_resolution_service.dart';

class PortraitProcessingResult {
  final Uint8List imageBytes;
  final DepthMap depthMap;

  const PortraitProcessingResult({
    required this.imageBytes,
    required this.depthMap,
  });
}

class PortraitProcessingService {
  final DepthDetectionService depthDetectionService;
  final SuperResolutionService superResolutionService;

  const PortraitProcessingService({
    required this.depthDetectionService,
    required this.superResolutionService,
  });

  Future<PortraitProcessingResult> process(
    Uint8List imageBytes, {
    required PortraitEffectSettings settings,
    String? imagePath,
  }) async {
    Uint8List working = imageBytes;

    if (settings.lensMode == PortraitLensMode.x2) {
      working = superResolutionService.upscale2xTelephoto(working);
    }

    final depthMap = await depthDetectionService.detectDepthMap(
      working,
      imagePath: imagePath,
    );

    final processed = await compute<Map<String, dynamic>, Uint8List>(
      _renderPortraitIsolate,
      {
        'bytes': working,
        'depth': depthMap.toJson(),
        'settings': settings.toJson(),
      },
    );

    return PortraitProcessingResult(imageBytes: processed, depthMap: depthMap);
  }
}

Uint8List _renderPortraitIsolate(Map<String, dynamic> payload) {
  final bytes = payload['bytes'] as Uint8List;
  final depth = DepthMap.fromJson((payload['depth'] as Map).cast<String, dynamic>());
  final settings = PortraitEffectSettings.fromJson((payload['settings'] as Map).cast<String, dynamic>());

  return BokehRenderer.render(
    inputBytes: bytes,
    depthMap: depth,
    settings: settings,
  );
}
