import 'dart:typed_data';

import 'package:image/image.dart' as img;

class SuperResolutionService {
  Uint8List upscale2xTelephoto(Uint8List inputBytes) {
    final image = img.decodeImage(inputBytes);
    if (image == null) return inputBytes;

    final cropWidth = (image.width / 2).round();
    final cropHeight = (image.height / 2).round();
    final left = ((image.width - cropWidth) / 2).round().clamp(0, image.width - 1);
    final top = ((image.height - cropHeight) / 2).round().clamp(0, image.height - 1);

    final cropped = img.copyCrop(
      image,
      x: left,
      y: top,
      width: cropWidth.clamp(1, image.width),
      height: cropHeight.clamp(1, image.height),
    );

    final upscaled = img.copyResize(
      cropped,
      width: image.width,
      height: image.height,
      interpolation: img.Interpolation.cubic,
    );

    final denoised = img.gaussianBlur(img.Image.from(upscaled), radius: 1);
    final sharpened = _unsharpMask(upscaled, denoised, 0.45);

    return Uint8List.fromList(img.encodeJpg(sharpened, quality: 97));
  }

  img.Image _unsharpMask(img.Image base, img.Image blurred, double amount) {
    final output = img.Image.from(base);
    for (int y = 0; y < output.height; y++) {
      for (int x = 0; x < output.width; x++) {
        final src = base.getPixel(x, y);
        final blur = blurred.getPixel(x, y);

        final r = _applySharp(img.getRed(src), img.getRed(blur), amount);
        final g = _applySharp(img.getGreen(src), img.getGreen(blur), amount);
        final b = _applySharp(img.getBlue(src), img.getBlue(blur), amount);

        output.setPixelRgba(x, y, r, g, b, img.getAlpha(src));
      }
    }
    return output;
  }

  int _applySharp(int source, int blur, double amount) {
    final value = source + ((source - blur) * amount);
    return value.round().clamp(0, 255);
  }
}
