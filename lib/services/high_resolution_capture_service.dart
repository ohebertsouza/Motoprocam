import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/capture_metadata.dart';
import '../models/resolution_config.dart';
import '../models/sensor_capabilities.dart';
import '../utils/image_processing_advanced.dart';
import 'camera2_native_service.dart';

class HighResolutionCaptureResult {
  final Uint8List image;
  final CaptureMetadata metadata;
  final ResolutionConfig outputResolution;

  const HighResolutionCaptureResult({
    required this.image,
    required this.metadata,
    required this.outputResolution,
  });
}

class HighResolutionCaptureService {
  final Camera2NativeService _camera2NativeService;

  const HighResolutionCaptureService({
    Camera2NativeService? camera2NativeService,
  }) : _camera2NativeService = camera2NativeService ?? const Camera2NativeService();

  Future<HighResolutionCaptureResult> captureWithProcessing({
    required CameraController controller,
    required ResolutionConfig resolution,
    int? iso,
    int? shutterSpeedNs,
  }) async {
    Uint8List bytes;

    if (resolution.requiresRaw) {
      bytes = await _camera2NativeService.captureRaw(
            width: resolution.width,
            height: resolution.height,
            iso: iso,
            shutterSpeedNs: shutterSpeedNs,
          ) ??
          await _captureJpeg(controller);
    } else {
      bytes = await _captureJpeg(controller);
    }

    final processed = await compute(_processIsolate, {
      'bytes': bytes,
      'mode': resolution.mode.name,
      'width': resolution.width,
      'height': resolution.height,
    });

    return HighResolutionCaptureResult(
      image: processed,
      metadata: CaptureMetadata.now(iso: iso, shutterSpeedNs: shutterSpeedNs),
      outputResolution: resolution,
    );
  }

  Future<HighResolutionCaptureResult> capture64MP({
    required CameraController controller,
    int? iso,
    int? shutterSpeedNs,
  }) {
    return captureWithProcessing(
      controller: controller,
      resolution: ResolutionConfig.mp32,
      iso: iso,
      shutterSpeedNs: shutterSpeedNs,
    );
  }

  Future<Uint8List?> captureRAW({
    int? iso,
    int? shutterSpeedNs,
  }) {
    return _camera2NativeService.captureRaw(
      width: ResolutionConfig.mp64Raw.width,
      height: ResolutionConfig.mp64Raw.height,
      iso: iso,
      shutterSpeedNs: shutterSpeedNs,
    );
  }

  Future<List<Map<String, int>>> getAvailableResolutions() {
    return _camera2NativeService.getAvailableResolutions();
  }

  Future<SensorCapabilities?> getSensorCapabilities() {
    return _camera2NativeService.getSensorInfo();
  }

  Future<Uint8List> _captureJpeg(CameraController controller) async {
    final file = await controller.takePicture();
    return file.readAsBytes();
  }
}

Future<Uint8List> _processIsolate(Map<String, dynamic> payload) async {
  final bytes = payload['bytes'] as Uint8List;
  final width = payload['width'] as int;
  final height = payload['height'] as int;
  final modeName = payload['mode'] as String;
  final target = ResolutionConfig.defaults.firstWhere(
    (config) => config.mode.name == modeName,
    orElse: () => ResolutionConfig.mp32,
  );

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }

  final resolvedTarget = ResolutionConfig(
    mode: target.mode,
    width: width,
    height: height,
    label: target.label,
    requiresRaw: target.requiresRaw,
  );

  final processed = ImageProcessingAdvanced.processToResolution(decoded, resolvedTarget);
  return Uint8List.fromList(img.encodeJpg(processed, quality: 98));
}
