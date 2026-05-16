import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:moto_pro_cam/services/super_resolution_service.dart';

void main() {
  test('2x telephoto upscale keeps original output resolution', () {
    final source = img.Image(width: 64, height: 48);
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, 120, 100, 90, 255);
      }
    }

    final input = Uint8List.fromList(img.encodeJpg(source));
    final output = SuperResolutionService().upscale2xTelephoto(input);
    final decoded = img.decodeImage(output);

    expect(decoded, isNotNull);
    expect(decoded!.width, 64);
    expect(decoded.height, 48);
  });
}
