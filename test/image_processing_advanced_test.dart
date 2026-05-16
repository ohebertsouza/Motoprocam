import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:moto_pro_cam/models/resolution_config.dart';
import 'package:moto_pro_cam/utils/image_processing_advanced.dart';

void main() {
  test('processToResolution gera saída no alvo selecionado', () {
    final image = img.Image(width: 4624, height: 3468);

    final output = ImageProcessingAdvanced.processToResolution(
      image,
      ResolutionConfig.mp32,
    );

    expect(output.width, ResolutionConfig.mp32.width);
    expect(output.height, ResolutionConfig.mp32.height);
  });
}
