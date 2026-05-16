import 'package:flutter_test/flutter_test.dart';
import 'package:moto_pro_cam/models/camera_settings.dart';
import 'package:moto_pro_cam/models/portrait_settings.dart';

void main() {
  test('camera settings clamp to pro mode ranges', () {
    final settings = const CameraSettings().copyWith(
      iso: 99999,
      shutterSpeedMs: 0.01,
      whiteBalanceKelvin: 1000,
      focusDistance: 9,
      exposureCompensation: -5,
    );

    expect(settings.iso, 6400);
    expect(settings.shutterSpeedMs, 0.125);
    expect(settings.whiteBalanceKelvin, 2000);
    expect(settings.focusDistance, 1.0);
    expect(settings.exposureCompensation, -2.0);
  });

  test('portrait settings map blur percent to 0-1 amount', () {
    final settings = const PortraitSettings().copyWith(blurPercent: 95);
    expect(settings.blurAmount, 0.95);
  });
}
