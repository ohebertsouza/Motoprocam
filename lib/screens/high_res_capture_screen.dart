import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/resolution_config.dart';
import '../models/sensor_capabilities.dart';
import '../services/camera2_native_service.dart';
import '../services/high_resolution_capture_service.dart';
import '../widgets/resolution_info_panel.dart';
import '../widgets/resolution_selector.dart';

class HighResCaptureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HighResCaptureScreen({
    super.key,
    required this.cameras,
  });

  @override
  State<HighResCaptureScreen> createState() => _HighResCaptureScreenState();
}

class _HighResCaptureScreenState extends State<HighResCaptureScreen>
    with WidgetsBindingObserver {
  final HighResolutionCaptureService _captureService =
      HighResolutionCaptureService();
  final Camera2NativeService _camera2NativeService = Camera2NativeService();

  CameraController? _controller;
  SensorCapabilities? _sensor;
  bool _isCapturing = false;
  int _cameraIndex = 0;
  ResolutionConfig _selectedResolution = ResolutionConfig.mp32;
  List<ResolutionConfig> _resolutionOptions = ResolutionConfig.defaults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    await Permission.camera.request();
    await Permission.storage.request();

    await Future.wait([
      _initCamera(),
      _loadSensorInfo(),
    ]);
  }

  Future<void> _loadSensorInfo() async {
    try {
      final info = await _camera2NativeService.getSensorInfo();
      if (!mounted) return;
      setState(() {
        _sensor = info;
        _resolutionOptions = info?.supportsRaw == true
            ? ResolutionConfig.defaults
            : ResolutionConfig.defaults.where((e) => !e.requiresRaw).toList();
        if (!_resolutionOptions.contains(_selectedResolution)) {
          _selectedResolution = ResolutionConfig.mp32;
        }
      });
    } catch (_) {
      // mantém fallback silencioso
    }
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;

    final controller = CameraController(
      widget.cameras[_cameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final result = await _captureService.captureWithProcessing(
        controller: _controller!,
        resolution: _selectedResolution,
      );

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/motoprocam_${_selectedResolution.label}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(result.image);
      await GallerySaver.saveImage(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 ${result.outputResolution.label} salva na galeria'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isCapturing = false);
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;
    _cameraIndex = _cameraIndex == 0 ? 1 : 0;
    await _controller?.dispose();
    setState(() => _controller = null);
    await _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            top: 54,
            left: 0,
            right: 0,
            child: Center(
              child: ResolutionSelector(
                options: _resolutionOptions,
                selected: _selectedResolution,
                onChanged: (v) => setState(() => _selectedResolution = v),
              ),
            ),
          ),
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: ResolutionInfoPanel(
              selected: _selectedResolution,
              sensor: _sensor,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _roundButton(
                  icon: Icons.flip_camera_ios,
                  onTap: _switchCamera,
                ),
                GestureDetector(
                  onTap: _isCapturing ? null : _capture,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: _isCapturing ? 70 : 78,
                    height: _isCapturing ? 70 : 78,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 4),
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.black,
                            ),
                          )
                        : null,
                  ),
                ),
                _roundButton(
                  icon: Icons.high_quality,
                  onTap: () {
                    setState(() {
                      _selectedResolution = _selectedResolution.mode ==
                              CaptureResolutionMode.mp32 &&
                              _resolutionOptions.contains(ResolutionConfig.mp64Raw)
                          ? ResolutionConfig.mp64Raw
                          : ResolutionConfig.mp32;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white24,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
