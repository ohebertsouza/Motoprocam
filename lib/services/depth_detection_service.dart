import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;

import '../models/depth_map.dart';
import '../utils/depth_algorithm.dart';

class DepthDetectionService {
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
      enableTracking: true,
    ),
  );

  final Map<int, DepthMap> _cache = <int, DepthMap>{};

  Future<DepthMap> detectDepthMap(
    Uint8List imageBytes, {
    String? imagePath,
  }) async {
    final key = _cacheKey(imageBytes);
    final cached = _cache[key];
    if (cached != null) return cached;

    final faceBoxes = await _detectFaces(imagePath);
    final result = await compute<Map<String, dynamic>, Map<String, dynamic>>(
      _detectDepthMapIsolate,
      {
        'bytes': imageBytes,
        'faces': faceBoxes,
      },
    );

    final map = DepthMap.fromJson(result).normalized();
    _cache[key] = map;

    if (_cache.length > 8) {
      _cache.remove(_cache.keys.first);
    }

    return map;
  }

  int _cacheKey(Uint8List bytes) {
    if (bytes.isEmpty) return 0;
    return Object.hash(bytes.length, bytes.first, bytes.last);
  }

  Future<List<List<double>>> _detectFaces(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return const <List<double>>[];
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);
      return faces
          .map(
            (face) => <double>[
              face.boundingBox.left,
              face.boundingBox.top,
              face.boundingBox.right,
              face.boundingBox.bottom,
            ],
          )
          .toList(growable: false);
    } catch (_) {
      return const <List<double>>[];
    }
  }

  Future<void> dispose() async {
    await _faceDetector.close();
  }
}

Map<String, dynamic> _detectDepthMapIsolate(Map<String, dynamic> payload) {
  final bytes = payload['bytes'] as Uint8List;
  final facesRaw = (payload['faces'] as List?) ?? const [];
  final image = img.decodeImage(bytes);

  if (image == null) {
    return const {
      'width': 1,
      'height': 1,
      'values': <double>[0.5],
    };
  }

  final luminance = List<double>.filled(image.width * image.height, 0.0);
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final gray = ((img.getRed(p) * 0.299) + (img.getGreen(p) * 0.587) + (img.getBlue(p) * 0.114)) / 255.0;
      luminance[y * image.width + x] = gray.clamp(0.0, 1.0);
    }
  }

  final normalizedFaces = <List<double>>[];
  for (final faceRaw in facesRaw) {
    final box = (faceRaw as List).cast<num>();
    if (box.length < 4) continue;
    normalizedFaces.add([
      (box[0].toDouble() / image.width).clamp(0.0, 1.0),
      (box[1].toDouble() / image.height).clamp(0.0, 1.0),
      (box[2].toDouble() / image.width).clamp(0.0, 1.0),
      (box[3].toDouble() / image.height).clamp(0.0, 1.0),
    ]);
  }

  final depthMap = DepthAlgorithm.estimateDepth(
    luminance,
    image.width,
    image.height,
    faceBoxes: normalizedFaces,
  );

  return depthMap.toJson();
}
