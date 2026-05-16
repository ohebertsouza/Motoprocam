import 'dart:math' as math;

import '../models/depth_map.dart';
import 'edge_detection_utils.dart';

class DepthAlgorithm {
  static DepthMap estimateDepth(
    List<double> luminance,
    int width,
    int height, {
    List<List<double>> faceBoxes = const [],
  }) {
    final edges = EdgeDetectionUtils.cannyLikeMap(luminance, width, height);
    final texture = _textureEnergy(luminance, width, height);
    final depth = List<double>.filled(width * height, 0.6);

    final centerX = width / 2;
    final centerY = height / 2;
    final maxRadius = math.sqrt((centerX * centerX) + (centerY * centerY));

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final dx = x - centerX;
        final dy = y - centerY;
        final radial = math.sqrt((dx * dx) + (dy * dy)) / maxRadius;

        final edgeWeight = edges[idx];
        final textureWeight = texture[idx];
        final focusWeight = 1.0 - (radial * 0.75);

        final estimated =
            (0.55 * radial) +
            (0.25 * (1.0 - edgeWeight)) +
            (0.2 * (1.0 - textureWeight)) -
            (0.25 * focusWeight);

        depth[idx] = estimated.clamp(0.0, 1.0);
      }
    }

    if (faceBoxes.isNotEmpty) {
      _applyFacePriority(depth, width, height, faceBoxes);
    }

    final smoothed = _smooth(depth, width, height);
    return DepthMap(width: width, height: height, values: smoothed).normalized();
  }

  static List<double> _textureEnergy(List<double> luminance, int width, int height) {
    final output = List<double>.filled(width * height, 0.0);
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final idx = y * width + x;
        final center = luminance[idx];
        final local = <double>[
          luminance[(y - 1) * width + x],
          luminance[(y + 1) * width + x],
          luminance[y * width + (x - 1)],
          luminance[y * width + (x + 1)],
        ];

        double variance = 0;
        for (final value in local) {
          final diff = value - center;
          variance += diff * diff;
        }
        output[idx] = (variance / local.length).clamp(0.0, 1.0);
      }
    }

    double max = 0;
    for (final value in output) {
      if (value > max) max = value;
    }
    if (max <= 0.000001) return output;

    return output.map((value) => (value / max).clamp(0.0, 1.0)).toList(growable: false);
  }

  static void _applyFacePriority(
    List<double> depth,
    int width,
    int height,
    List<List<double>> faceBoxes,
  ) {
    for (final face in faceBoxes) {
      if (face.length < 4) continue;
      final left = (face[0] * width).round().clamp(0, width - 1);
      final top = (face[1] * height).round().clamp(0, height - 1);
      final right = (face[2] * width).round().clamp(0, width - 1);
      final bottom = (face[3] * height).round().clamp(0, height - 1);

      final faceWidth = (right - left).clamp(1, width);
      final faceHeight = (bottom - top).clamp(1, height);
      final cx = left + (faceWidth / 2);
      final cy = top + (faceHeight / 2);
      final radius = math.max(faceWidth, faceHeight) / 2;

      for (int y = top; y <= bottom; y++) {
        for (int x = left; x <= right; x++) {
          final idx = y * width + x;
          final dx = x - cx;
          final dy = y - cy;
          final d = math.sqrt((dx * dx) + (dy * dy));
          final influence = 1.0 - (d / (radius + 0.001)).clamp(0.0, 1.0);
          depth[idx] = (depth[idx] * 0.35) - (0.45 * influence);
        }
      }
    }
  }

  static List<double> _smooth(List<double> values, int width, int height) {
    final output = List<double>.filled(width * height, 0.0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double sum = 0;
        double weight = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final px = x + kx;
            final py = y + ky;
            if (px < 0 || py < 0 || px >= width || py >= height) continue;
            final w = (kx == 0 && ky == 0) ? 0.25 : 0.09375;
            sum += values[py * width + px] * w;
            weight += w;
          }
        }

        output[y * width + x] = (sum / (weight == 0 ? 1 : weight)).clamp(0.0, 1.0);
      }
    }

    return output;
  }
}
