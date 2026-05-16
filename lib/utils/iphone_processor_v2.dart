import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/image_processor_settings.dart';
import '../models/portrait_settings.dart';

const double _defaultPortraitCenterY = 0.42;
const int _portraitBlurRadiusScale = 12;
const int _portraitMaxBlurRadius = 12;
const double _shadowBoostFactor = 0.45;
const double _highlightCompressionFactor = 0.35;

class IphoneProcessorV2 {
  static Future<Uint8List> process(
    Uint8List inputBytes, {
    required ImageProcessorSettings settings,
    PortraitSettings? portraitSettings,
  }) async {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      return inputBytes;
    }

    var image = decoded;
    final exposureFactor = math.pow(2, settings.exposure).toDouble();
    image = img.adjustColor(
      image,
      exposure: exposureFactor,
      contrast: 1.0 + settings.contrast,
      saturation: 1.0 + settings.saturation,
    );

    if (settings.enableCurves) {
      image = _applyCurves(image, settings.shadows, settings.highlights);
    }

    image = _applyWhiteBalance(image, settings.whiteBalanceKelvin);

    if (settings.enableLut) {
      image = _applySoftLut(image);
    }

    if (settings.noiseReduction > 0) {
      final radius = (settings.noiseReduction * 2).round();
      if (radius > 0) {
        image = img.gaussianBlur(image, radius: radius);
      }
    }

    if (portraitSettings != null && portraitSettings.blurPercent > 0) {
      image = _applyPortraitBlur(image, portraitSettings);
      image = _applyPortraitLighting(image, portraitSettings.lightingEffect);
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 96));
  }

  static img.Image _applyCurves(img.Image source, double shadows, double highlights) {
    final shadowBoost = 1.0 + (shadows * _shadowBoostFactor);
    final highlightCompression = 1.0 - (highlights * _highlightCompressionFactor);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final r = _curveChannel(img.getRed(pixel), shadowBoost, highlightCompression);
        final g = _curveChannel(img.getGreen(pixel), shadowBoost, highlightCompression);
        final b = _curveChannel(img.getBlue(pixel), shadowBoost, highlightCompression);
        source.setPixelRgba(x, y, r, g, b, img.getAlpha(pixel));
      }
    }
    return source;
  }

  static int _curveChannel(int value, double shadowBoost, double highlightCompression) {
    final normalized = value / 255.0;
    final curved = normalized < 0.5
        ? math.pow(normalized, 1.0 / shadowBoost).toDouble()
        : 1 - math.pow(1 - normalized, highlightCompression).toDouble();
    return (curved * 255).round().clamp(0, 255);
  }

  static img.Image _applyWhiteBalance(img.Image source, int kelvin) {
    final normalized = ((kelvin - 5500) / 3500).clamp(-1.0, 1.0);
    final addR = (normalized * 22).round();
    final addB = (-normalized * 20).round();

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final r = (img.getRed(pixel) + addR).clamp(0, 255).toInt();
        final g = img.getGreen(pixel);
        final b = (img.getBlue(pixel) + addB).clamp(0, 255).toInt();
        source.setPixelRgba(x, y, r, g, b, img.getAlpha(pixel));
      }
    }
    return source;
  }

  static img.Image _applySoftLut(img.Image source) {
    return img.adjustColor(source, gamma: 0.98, saturation: 1.05);
  }

  static img.Image _applyPortraitBlur(img.Image source, PortraitSettings settings) {
    final blurRadius =
        (settings.blurAmount * _portraitBlurRadiusScale).round().clamp(1, _portraitMaxBlurRadius).toInt();
    final blurred = img.gaussianBlur(img.Image.from(source), radius: blurRadius);

    final centerX = source.width / 2;
    final centerY = source.height * _defaultPortraitCenterY;
    final maxDistance = math.sqrt(source.width * source.width + source.height * source.height) / 2;

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final distance = math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));
        final depthWeight = (distance / maxDistance).clamp(0.0, 1.0).toDouble();
        final alpha = depthWeight * settings.blurAmount * settings.depthStrength;

        final original = source.getPixel(x, y);
        final back = blurred.getPixel(x, y);

        final r = _mix(img.getRed(original), img.getRed(back), alpha);
        final g = _mix(img.getGreen(original), img.getGreen(back), alpha);
        final b = _mix(img.getBlue(original), img.getBlue(back), alpha);

        source.setPixelRgba(x, y, r, g, b, img.getAlpha(original));
      }
    }

    return source;
  }

  static int _mix(int a, int b, double t) {
    return (a + (b - a) * t).round().clamp(0, 255);
  }

  static img.Image _applyPortraitLighting(img.Image source, PortraitLightingEffect effect) {
    switch (effect) {
      case PortraitLightingEffect.natural:
        return source;
      case PortraitLightingEffect.studio:
        return img.adjustColor(source, contrast: 1.08, brightness: 0.04);
      case PortraitLightingEffect.ring:
        return img.adjustColor(source, brightness: 0.08, saturation: 1.03);
      case PortraitLightingEffect.stage:
        return img.adjustColor(source, contrast: 1.18, saturation: 0.92);
      case PortraitLightingEffect.contour:
        return img.adjustColor(source, contrast: 1.15, gamma: 0.95);
    }
  }
}
