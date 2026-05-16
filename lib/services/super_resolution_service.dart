import 'package:image/image.dart' as img;

import '../models/resolution_config.dart';

enum SuperResolutionMode { bicubic, lanczosLike }

class SuperResolutionService {
  static img.Image upscale(
    img.Image input, {
    ResolutionConfig target = ResolutionConfig.mp32,
    SuperResolutionMode mode = SuperResolutionMode.bicubic,
  }) {
    final interpolation = mode == SuperResolutionMode.bicubic
        ? img.Interpolation.cubic
        : img.Interpolation.linear;

    return img.copyResize(
      input,
      width: target.width,
      height: target.height,
      interpolation: interpolation,
    );
  }
}
