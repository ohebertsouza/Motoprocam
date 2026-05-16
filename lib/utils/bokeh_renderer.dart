import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/depth_map.dart';
import '../models/portrait_effect_settings.dart';

class BokehRenderer {
  static Uint8List render({
    required Uint8List inputBytes,
    required DepthMap depthMap,
    required PortraitEffectSettings settings,
  }) {
    final image = img.decodeImage(inputBytes);
    if (image == null) return inputBytes;

    final normalizedDepth = depthMap.normalized();
    final depthValues = _fitDepthToImage(normalizedDepth, image.width, image.height);

    final blurLow = img.gaussianBlur(img.Image.from(image), radius: 2);
    final blurMid = img.gaussianBlur(img.Image.from(image), radius: 5);
    final blurHigh = img.gaussianBlur(img.Image.from(image), radius: 10);

    final sharpness = _sharpnessMap(image);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final idx = y * image.width + x;
        final d = depthValues[idx];
        final focusThreshold = settings.depthSensitivity.clamp(0.05, 0.95);
        final softness = settings.edgeSoftness.clamp(0.05, 0.95);
        final transition = ((d - focusThreshold) / softness).clamp(0.0, 1.0);

        final motionAware = 1.0 - sharpness[idx].clamp(0.0, 1.0);
        final intensity = (settings.blurIntensity * transition * motionAware).clamp(0.0, 1.0);

        final source = image.getPixel(x, y);
        final c1 = blurLow.getPixel(x, y);
        final c2 = blurMid.getPixel(x, y);
        final c3 = blurHigh.getPixel(x, y);

        final blurColor = _blendPixel(_blendPixel(c1, c2, intensity), c3, intensity * 0.8);
        final finalColor = _blendPixel(source, blurColor, intensity);

        image.setPixel(x, y, finalColor);
      }
    }

    _applyLighting(image, depthValues, settings.lightingMode);

    return Uint8List.fromList(img.encodeJpg(image, quality: 97));
  }

  static List<double> _fitDepthToImage(DepthMap map, int targetWidth, int targetHeight) {
    if (map.width == targetWidth && map.height == targetHeight) return map.values;

    final output = List<double>.filled(targetWidth * targetHeight, 1.0);
    for (int y = 0; y < targetHeight; y++) {
      final sy = ((y / targetHeight) * map.height).floor().clamp(0, map.height - 1);
      for (int x = 0; x < targetWidth; x++) {
        final sx = ((x / targetWidth) * map.width).floor().clamp(0, map.width - 1);
        output[y * targetWidth + x] = map.values[sy * map.width + sx];
      }
    }
    return output;
  }

  static List<double> _sharpnessMap(img.Image image) {
    final output = List<double>.filled(image.width * image.height, 0.0);

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final c = image.getPixel(x, y);
        final l = image.getPixel(x - 1, y);
        final r = image.getPixel(x + 1, y);
        final t = image.getPixel(x, y - 1);
        final b = image.getPixel(x, y + 1);

        final center = (img.getRed(c) + img.getGreen(c) + img.getBlue(c)) / 3.0;
        final laplacian = ((img.getRed(l) + img.getGreen(l) + img.getBlue(l)) / 3.0) +
            ((img.getRed(r) + img.getGreen(r) + img.getBlue(r)) / 3.0) +
            ((img.getRed(t) + img.getGreen(t) + img.getBlue(t)) / 3.0) +
            ((img.getRed(b) + img.getGreen(b) + img.getBlue(b)) / 3.0) -
            (4 * center);

        output[y * image.width + x] = (laplacian.abs() / 255.0).clamp(0.0, 1.0);
      }
    }

    return output;
  }

  static void _applyLighting(
    img.Image image,
    List<double> depthValues,
    PortraitLightingMode mode,
  ) {
    if (mode == PortraitLightingMode.natural) return;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final idx = y * image.width + x;
        final depth = depthValues[idx];
        final backgroundFactor = (depth - 0.45).clamp(0.0, 1.0);

        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel).toDouble();
        final g = img.getGreen(pixel).toDouble();
        final b = img.getBlue(pixel).toDouble();

        double nr = r;
        double ng = g;
        double nb = b;

        switch (mode) {
          case PortraitLightingMode.studio:
            nr = r + (14 * backgroundFactor);
            ng = g + (14 * backgroundFactor);
            nb = b + (14 * backgroundFactor);
            break;
          case PortraitLightingMode.ring:
            nr = r + (20 * backgroundFactor);
            ng = g + (10 * backgroundFactor);
            nb = b + (6 * backgroundFactor);
            break;
          case PortraitLightingMode.stage:
            nr = r * (1 - (0.45 * backgroundFactor));
            ng = g * (1 - (0.45 * backgroundFactor));
            nb = b * (1 - (0.45 * backgroundFactor));
            break;
          case PortraitLightingMode.natural:
            break;
        }

        image.setPixelRgba(
          x,
          y,
          nr.round().clamp(0, 255),
          ng.round().clamp(0, 255),
          nb.round().clamp(0, 255),
          img.getAlpha(pixel),
        );
      }
    }
  }

  static int _blendPixel(int a, int b, double t) {
    t = t.clamp(0.0, 1.0);
    final ar = img.getRed(a).toDouble();
    final ag = img.getGreen(a).toDouble();
    final ab = img.getBlue(a).toDouble();
    final aa = img.getAlpha(a).toDouble();

    final br = img.getRed(b).toDouble();
    final bg = img.getGreen(b).toDouble();
    final bb = img.getBlue(b).toDouble();
    final ba = img.getAlpha(b).toDouble();

    return img.getColor(
      (ar + ((br - ar) * t)).round().clamp(0, 255),
      (ag + ((bg - ag) * t)).round().clamp(0, 255),
      (ab + ((bb - ab) * t)).round().clamp(0, 255),
      (aa + ((ba - aa) * t)).round().clamp(0, 255),
    );
  }
}
