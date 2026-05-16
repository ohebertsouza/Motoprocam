import 'package:camera/camera.dart';

import '../models/camera_settings.dart';
import 'device_camera_info.dart';

class CameraService {
  CameraService(this.cameras);

  final List<CameraDescription> cameras;
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  List<LensProfile> _lensProfiles = const <LensProfile>[];

  CameraController? get controller => _controller;
  int get selectedCameraIndex => _selectedCameraIndex;
  List<LensProfile> get lensProfiles => _lensProfiles;

  Future<void> initialize({String? modelName}) async {
    if (cameras.isEmpty) return;
    _lensProfiles = DeviceCameraInfo.buildLensProfiles(cameras);
    final mainLens = _lensProfiles.where((lens) => lens.name == 'Main').firstOrNull;
    _selectedCameraIndex = mainLens?.cameraIndex ?? 0;
    await _initializeController(modelName: modelName);
  }

  Future<void> selectLens(int cameraIndex, {String? modelName}) async {
    if (cameraIndex < 0 || cameraIndex >= cameras.length || cameraIndex == _selectedCameraIndex) {
      return;
    }
    _selectedCameraIndex = cameraIndex;
    await _initializeController(modelName: modelName);
  }

  Future<void> _initializeController({String? modelName}) async {
    await _controller?.dispose();
    _controller = CameraController(
      cameras[_selectedCameraIndex],
      DeviceCameraInfo.optimizedPresetFor(modelName),
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.off);
  }

  Future<void> applyManualSettings(CameraSettings settings) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.setExposureOffset(settings.exposureCompensation);
    await _controller!.setFocusMode(
      settings.focusDistance > 0 ? FocusMode.locked : FocusMode.auto,
    );
    switch (settings.meteringMode) {
      case ExposureMeteringMode.spot:
        await _controller!.setExposureMode(ExposureMode.locked);
        break;
      case ExposureMeteringMode.centerWeighted:
      case ExposureMeteringMode.matrix:
        await _controller!.setExposureMode(ExposureMode.auto);
        break;
    }
  }

  Future<void> setZoomPercent(double percent) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final min = await _controller!.getMinZoomLevel();
    final max = await _controller!.getMaxZoomLevel();
    final value = min + (max - min) * percent.clamp(0.0, 1.0);
    await _controller!.setZoomLevel(value);
  }

  Future<XFile> capturePhoto() async {
    return _controller!.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
