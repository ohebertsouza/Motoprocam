import 'package:image/image.dart' as img;

class DenoiseFilter {
  static img.Image applyAdaptive(img.Image input) {
    if (input.width < 2 || input.height < 2) {
      return input;
    }

    final blurred = img.gaussianBlur(img.Image.from(input), radius: 1);
    final output = img.Image.from(input);

    for (int y = 0; y < input.height; y++) {
      for (int x = 0; x < input.width; x++) {
        final source = input.getPixel(x, y);
        final blur = blurred.getPixel(x, y);

        final sourceLuma =
            (img.getRed(source) * 0.2126 + img.getGreen(source) * 0.7152 + img.getBlue(source) * 0.0722) /
                255.0;

        final blend = sourceLuma < 0.35 ? 0.35 : 0.1;

        output.setPixelRgba(
          x,
          y,
          (img.getRed(source) * (1 - blend) + img.getRed(blur) * blend).round().clamp(0, 255),
          (img.getGreen(source) * (1 - blend) + img.getGreen(blur) * blend).round().clamp(0, 255),
          (img.getBlue(source) * (1 - blend) + img.getBlue(blur) * blend).round().clamp(0, 255),
          img.getAlpha(source),
        );
      }
    }

    return output;
  }
}
