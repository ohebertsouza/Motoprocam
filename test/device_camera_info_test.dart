import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_pro_cam/services/device_camera_info.dart';

void main() {
  test('buildLensProfiles classifies lens names and direction', () {
    const cameras = <CameraDescription>[
      CameraDescription(
        name: '0 ultra',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
      CameraDescription(
        name: '1 tele',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
      CameraDescription(
        name: '2 main',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
      CameraDescription(
        name: '3 front',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      ),
    ];

    final profiles = DeviceCameraInfo.buildLensProfiles(cameras);

    expect(profiles[0].name, 'Ultra-wide');
    expect(profiles[1].name, 'Telephoto');
    expect(profiles[2].name, 'Main');
    expect(profiles[3].name, 'Front');
  });
}
