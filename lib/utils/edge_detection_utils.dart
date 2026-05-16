import 'dart:math' as math;

class EdgeDetectionUtils {
  static List<double> sobelMagnitude(List<double> luminance, int width, int height) {
    final output = List<double>.filled(width * height, 0.0);
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final idx = y * width + x;
        final gx =
            -luminance[(y - 1) * width + (x - 1)] +
            luminance[(y - 1) * width + (x + 1)] +
            -2 * luminance[y * width + (x - 1)] +
            2 * luminance[y * width + (x + 1)] +
            -luminance[(y + 1) * width + (x - 1)] +
            luminance[(y + 1) * width + (x + 1)];

        final gy =
            luminance[(y - 1) * width + (x - 1)] +
            2 * luminance[(y - 1) * width + x] +
            luminance[(y - 1) * width + (x + 1)] -
            luminance[(y + 1) * width + (x - 1)] -
            2 * luminance[(y + 1) * width + x] -
            luminance[(y + 1) * width + (x + 1)];

        output[idx] = math.sqrt((gx * gx) + (gy * gy));
      }
    }

    double max = 0;
    for (final value in output) {
      if (value > max) max = value;
    }
    if (max <= 0.000001) return output;

    return output.map((value) => (value / max).clamp(0.0, 1.0)).toList(growable: false);
  }

  static List<double> cannyLikeMap(
    List<double> luminance,
    int width,
    int height, {
    double lowThreshold = 0.12,
    double highThreshold = 0.28,
  }) {
    final sobel = sobelMagnitude(luminance, width, height);
    final output = List<double>.filled(width * height, 0.0);

    for (int i = 0; i < sobel.length; i++) {
      final value = sobel[i];
      if (value >= highThreshold) {
        output[i] = 1.0;
      } else if (value >= lowThreshold) {
        output[i] = 0.55;
      }
    }

    return output;
  }
}
