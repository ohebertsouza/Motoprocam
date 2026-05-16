import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:moto_pro_cam/services/pixel_binning_service.dart';

void main() {
  test('bin2x2 reduz resolução pela metade', () {
    final image = img.Image(width: 4, height: 4);
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 4; x++) {
        image.setPixelRgb(x, y, 100, 100, 100);
      }
    }

    final binned = PixelBinningService.bin2x2(image);

    expect(binned.width, 2);
    expect(binned.height, 2);
  });
}
