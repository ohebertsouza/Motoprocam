import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class LensProfile {
  const LensProfile({
    required this.cameraIndex,
    required this.name,
    required this.description,
  });

  final int cameraIndex;
  final String name;
  final String description;
}

class DeviceCameraInfo {
  static const MethodChannel _channel = MethodChannel('motoprocam/camera2');

  static Future<Map<String, dynamic>> getNativeCapabilities() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getCapabilities');
      return result ?? const <String, dynamic>{};
    } on PlatformException {
      return const <String, dynamic>{};
    }
  }

  static List<LensProfile> buildLensProfiles(List<CameraDescription> cameras) {
    return cameras.asMap().entries.map((entry) {
      final index = entry.key;
      final camera = entry.value;
      final lower = camera.name.toLowerCase();
      if (lower.contains('ultra')) {
        return LensProfile(
          cameraIndex: index,
          name: 'Ultra-wide',
          description: '0.5x landscape lens',
        );
      }
      if (lower.contains('tele')) {
        return LensProfile(
          cameraIndex: index,
          name: 'Telephoto',
          description: 'Zoom portrait lens',
        );
      }
      if (camera.lensDirection == CameraLensDirection.front) {
        return LensProfile(
          cameraIndex: index,
          name: 'Front',
          description: 'Selfie lens',
        );
      }
      return LensProfile(
        cameraIndex: index,
        name: 'Main',
        description: 'Primary lens',
      );
    }).toList(growable: false);
  }

  static ResolutionPreset optimizedPresetFor(String? modelName) {
    final normalized = modelName?.toLowerCase() ?? '';
    if (normalized.contains('edge 30')) {
      return ResolutionPreset.veryHigh;
    }
    return ResolutionPreset.max;
  }
}
