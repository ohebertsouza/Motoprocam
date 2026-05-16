import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/image_processor_settings.dart';
import '../models/portrait_settings.dart';
import '../utils/iphone_processor_v2.dart';

class ImageProcessingService {
  const ImageProcessingService();

  Future<Uint8List> processPhoto(
    Uint8List bytes, {
    required ImageProcessorSettings settings,
    PortraitSettings? portraitSettings,
  }) {
    return compute(
      _processImageInIsolate,
      <String, dynamic>{
        'bytes': bytes,
        'settings': <String, dynamic>{
          'exposure': settings.exposure,
          'contrast': settings.contrast,
          'saturation': settings.saturation,
          'shadows': settings.shadows,
          'highlights': settings.highlights,
          'noiseReduction': settings.noiseReduction,
          'whiteBalanceKelvin': settings.whiteBalanceKelvin,
          'enableCurves': settings.enableCurves,
          'enableLut': settings.enableLut,
        },
        'portrait': portraitSettings == null
            ? null
            : <String, dynamic>{
                'blurPercent': portraitSettings.blurPercent,
                'depthStrength': portraitSettings.depthStrength,
                'enableFacePriority': portraitSettings.enableFacePriority,
                'lightingEffect': portraitSettings.lightingEffect.name,
              },
      },
    );
  }
}

Future<Uint8List> _processImageInIsolate(Map<String, dynamic> payload) async {
  final settingsMap = payload['settings'] as Map<String, dynamic>;
  final portraitMap = payload['portrait'] as Map<String, dynamic>?;
  return IphoneProcessorV2.process(
    payload['bytes'] as Uint8List,
    settings: ImageProcessorSettings(
      exposure: settingsMap['exposure'] as double,
      contrast: settingsMap['contrast'] as double,
      saturation: settingsMap['saturation'] as double,
      shadows: settingsMap['shadows'] as double,
      highlights: settingsMap['highlights'] as double,
      noiseReduction: settingsMap['noiseReduction'] as double,
      whiteBalanceKelvin: settingsMap['whiteBalanceKelvin'] as int,
      enableCurves: settingsMap['enableCurves'] as bool,
      enableLut: settingsMap['enableLut'] as bool,
    ),
    portraitSettings: portraitMap == null
        ? null
        : PortraitSettings(
            blurPercent: portraitMap['blurPercent'] as int,
            depthStrength: portraitMap['depthStrength'] as double,
            enableFacePriority: portraitMap['enableFacePriority'] as bool,
            lightingEffect: PortraitLightingEffect.values.firstWhere(
              (effect) => effect.name == portraitMap['lightingEffect'],
              orElse: () => PortraitLightingEffect.natural,
            ),
          ),
  );
}
