import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/sensor_capabilities.dart';

class Camera2NativeService {
  const Camera2NativeService();

  static const MethodChannel _channel = MethodChannel('com.moto.procam/camera2');

  Future<List<Map<String, int>>> getAvailableResolutions() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('getAvailableResolutions');
    if (raw == null) return const [];

    return raw
        .whereType<Map>()
        .map(
          (e) => {
            'width': (e['width'] as num?)?.toInt() ?? 0,
            'height': (e['height'] as num?)?.toInt() ?? 0,
          },
        )
        .toList();
  }

  Future<SensorCapabilities?> getSensorInfo() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSensorInfo');
    if (raw == null) return null;
    return SensorCapabilities.fromMap(raw);
  }

  Future<void> setManualExposure({required int iso, required int shutterSpeedNs}) {
    return _channel.invokeMethod<void>('setManualExposure', {
      'iso': iso,
      'shutterSpeedNs': shutterSpeedNs,
    });
  }

  Future<Uint8List?> captureRaw({required int width, required int height, int? iso, int? shutterSpeedNs}) async {
    final raw = await _channel.invokeMethod<Uint8List>('captureRaw', {
      'width': width,
      'height': height,
      'iso': iso,
      'shutterSpeedNs': shutterSpeedNs,
    });
    return raw;
  }
}
