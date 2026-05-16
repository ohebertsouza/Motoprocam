import 'package:image/image.dart' as img;

class SharpeningUtils {
  static img.Image unsharpMask(img.Image input, {double amount = 0.6}) {
    final blurred = img.gaussianBlur(img.Image.from(input), radius: 1);
    final output = img.Image.from(input);

    for (int y = 0; y < input.height; y++) {
      for (int x = 0; x < input.width; x++) {
        final source = input.getPixel(x, y);
        final blur = blurred.getPixel(x, y);

        output.setPixelRgba(
          x,
          y,
          _apply(img.getRed(source), img.getRed(blur), amount),
          _apply(img.getGreen(source), img.getGreen(blur), amount),
          _apply(img.getBlue(source), img.getBlue(blur), amount),
          img.getAlpha(source),
        );
      }
    }

    return output;
  }

  static int _apply(int source, int blur, double amount) {
    final detail = source - blur;
    return (source + detail * amount).round().clamp(0, 255);
  }
}
