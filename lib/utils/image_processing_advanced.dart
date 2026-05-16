import 'package:image/image.dart' as img;

import '../models/resolution_config.dart';
import '../services/pixel_binning_service.dart';
import '../services/super_resolution_service.dart';
import 'denoise_filter.dart';
import 'sharpening_utils.dart';

class ImageProcessingAdvanced {
  static img.Image processToResolution(
    img.Image input,
    ResolutionConfig target,
  ) {
    img.Image current = DenoiseFilter.applyAdaptive(input);

    final canUseBinning =
        current.width >= target.width * 1.9 && current.height >= target.height * 1.9;

    if (target.mode == CaptureResolutionMode.mp32 && canUseBinning) {
      current = PixelBinningService.bin2x2(current);
    } else if (current.width != target.width || current.height != target.height) {
      current = SuperResolutionService.upscale(current, target: target);
    }

    current = _applyIphoneLikeWhiteBalance(current);
    current = SharpeningUtils.unsharpMask(current, amount: 0.55);
    return current;
  }

  static img.Image _applyIphoneLikeWhiteBalance(img.Image image) {
    final output = img.Image.from(image);

    for (int y = 0; y < output.height; y++) {
      for (int x = 0; x < output.width; x++) {
        final p = image.getPixel(x, y);
        final r = (img.getRed(p) * 1.02).round().clamp(0, 255);
        final g = img.getGreen(p);
        final b = (img.getBlue(p) * 0.98).round().clamp(0, 255);
        output.setPixelRgba(x, y, r, g, b, img.getAlpha(p));
      }
    }

    return output;
  }
}
