import 'package:flutter_test/flutter_test.dart';
import 'package:moto_pro_cam/models/depth_map.dart';
import 'package:moto_pro_cam/utils/depth_algorithm.dart';

void main() {
  test('DepthMap normalized keeps values in [0,1]', () {
    const map = DepthMap(width: 2, height: 2, values: [2.0, 6.0, 8.0, 4.0]);
    final normalized = map.normalized();

    expect(normalized.values.every((value) => value >= 0 && value <= 1), isTrue);
  });

  test('DepthAlgorithm prioritizes face boxes as foreground', () {
    const width = 12;
    const height = 12;
    final luminance = List<double>.filled(width * height, 0.5);

    final depth = DepthAlgorithm.estimateDepth(
      luminance,
      width,
      height,
      faceBoxes: const [
        [0.3, 0.3, 0.7, 0.7],
      ],
    );

    final center = depth.depthAt(6, 6);
    final corner = depth.depthAt(0, 0);
    expect(center < corner, isTrue);
  });
}
