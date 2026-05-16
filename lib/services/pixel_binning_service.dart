import 'package:image/image.dart' as img;

enum BinningMode { balanced, detail }

class PixelBinningService {
  static img.Image bin2x2(
    img.Image input, {
    BinningMode mode = BinningMode.detail,
  }) {
    final targetWidth = (input.width / 2).floor();
    final targetHeight = (input.height / 2).floor();
    final output = img.Image(width: targetWidth, height: targetHeight);

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final sx = x * 2;
        final sy = y * 2;

        final p1 = input.getPixel(sx, sy);
        final p2 = input.getPixel(sx + 1, sy);
        final p3 = input.getPixel(sx, sy + 1);
        final p4 = input.getPixel(sx + 1, sy + 1);

        output.setPixelRgba(
          x,
          y,
          _mix(img.getRed(p1), img.getRed(p2), img.getRed(p3), img.getRed(p4), mode),
          _mix(img.getGreen(p1), img.getGreen(p2), img.getGreen(p3), img.getGreen(p4), mode),
          _mix(img.getBlue(p1), img.getBlue(p2), img.getBlue(p3), img.getBlue(p4), mode),
          _mix(img.getAlpha(p1), img.getAlpha(p2), img.getAlpha(p3), img.getAlpha(p4), BinningMode.balanced),
        );
      }
    }

    return output;
  }

  static int _mix(int a, int b, int c, int d, BinningMode mode) {
    if (mode == BinningMode.balanced) {
      return ((a + b + c + d) / 4).round().clamp(0, 255);
    }

    final list = [a, b, c, d]..sort();
    final median = (list[1] + list[2]) / 2;
    final average = (a + b + c + d) / 4;
    return ((median * 0.6) + (average * 0.4)).round().clamp(0, 255);
  }
}
