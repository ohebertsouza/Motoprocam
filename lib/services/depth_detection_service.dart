import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui';

import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/portrait_settings.dart';

class DepthDetectionService {
  DepthDetectionService()
      : _faceDetector = GoogleMlKit.vision.faceDetector(
          FaceDetectorOptions(
            enableContours: false,
            enableClassification: false,
            performanceMode: FaceDetectorMode.fast,
          ),
        );

  final FaceDetector _faceDetector;

  Future<Offset?> detectPrimaryFaceCenter({
    required String imagePath,
    required double imageWidth,
    required double imageHeight,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;

    faces.sort(
      (a, b) => (b.boundingBox.width * b.boundingBox.height).compareTo(
        a.boundingBox.width * a.boundingBox.height,
      ),
    );
    final largest = faces.first;
    final center = largest.boundingBox.center;
    final normalizedX = (center.dx / imageWidth).clamp(0.0, 1.0).toDouble();
    final normalizedY = (center.dy / imageHeight).clamp(0.0, 1.0).toDouble();
    return Offset(normalizedX, normalizedY);
  }

  Float32List buildEstimatedDepthMap({
    required int width,
    required int height,
    required PortraitSettings portraitSettings,
    Offset? faceCenter,
  }) {
    final data = Float32List(width * height);
    final centerX = (faceCenter?.dx ?? 0.5) * width;
    final centerY = (faceCenter?.dy ?? 0.42) * height;
    final maxDistance = math.sqrt(width * width + height * height) / 2;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final distance = math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));
        final normalized = (distance / maxDistance).clamp(0.0, 1.0).toDouble();
        data[y * width + x] = normalized * portraitSettings.depthStrength;
      }
    }
    return data;
  }

  Future<void> dispose() async {
    await _faceDetector.close();
  }
}
