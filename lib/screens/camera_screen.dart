import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/camera_settings.dart';
import '../models/image_processor_settings.dart';
import '../models/portrait_settings.dart';
import '../services/camera_service.dart';
import '../services/depth_detection_service.dart';
import '../services/device_camera_info.dart';
import '../services/image_processing_service.dart';
import 'portrait_mode_screen.dart';
import 'pro_mode_screen.dart';
import '../widgets/camera_lens_selector.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late final CameraService _cameraService;
  final ImageProcessingService _imageProcessingService = const ImageProcessingService();
  final DepthDetectionService _depthDetectionService = DepthDetectionService();

  CameraSettings _cameraSettings = const CameraSettings();
  PortraitSettings _portraitSettings = const PortraitSettings();
  ImageProcessorSettings _processorSettings = const ImageProcessorSettings();

  bool _showControls = false;
  bool _isCapturing = false;
  double _zoomPercent = 0.0;
  String _selectedMode = 'Auto';

  static const List<String> _modes = <String>['Night', 'Auto', 'Portrait', 'Pro'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraService = CameraService(widget.cameras);
    _initialize();
  }

  Future<void> _initialize() async {
    await Permission.camera.request();
    await Permission.storage.request();
    final capabilities = await DeviceCameraInfo.getNativeCapabilities();
    final modelName = capabilities['deviceModel'] as String?;

    if (widget.cameras.isEmpty) return;

    await _cameraService.initialize(modelName: modelName);
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    final controller = _cameraService.controller;
    if (_isCapturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      await _cameraService.applyManualSettings(_cameraSettings);
      final shot = await _cameraService.capturePhoto();
      final bytes = await shot.readAsBytes();

      if (_selectedMode == 'Night') {
        _processorSettings = _processorSettings.copyWith(exposure: 0.25, noiseReduction: 0.35, highlights: 0.3);
      }

      if (_selectedMode == 'Auto') {
        _processorSettings = _processorSettings.copyWith(exposure: 0.0, noiseReduction: 0.2, highlights: 0.2);
      }

      if (_selectedMode == 'Pro') {
        _processorSettings = _processorSettings.copyWith(
          exposure: _cameraSettings.exposureCompensation,
          whiteBalanceKelvin: _cameraSettings.whiteBalanceKelvin,
          enableLut: true,
        );
      }

      final previewWidth = controller.value.previewSize?.width ?? 1080;
      final previewHeight = controller.value.previewSize?.height ?? 1920;
      final Offset? faceCenter = _selectedMode == 'Portrait' && _portraitSettings.enableFacePriority
          ? await _depthDetectionService.detectPrimaryFaceCenter(
              imagePath: shot.path,
              imageWidth: previewWidth,
              imageHeight: previewHeight,
            )
          : null;

      if (faceCenter != null) {
        await controller.setFocusPoint(faceCenter);
      }

      final portraitEnabled = _selectedMode == 'Portrait';
      if (portraitEnabled) {
        _depthDetectionService.buildEstimatedDepthMap(
          width: previewWidth.toInt(),
          height: previewHeight.toInt(),
          portraitSettings: _portraitSettings,
          faceCenter: faceCenter,
        );
      }

      final processed = await _imageProcessingService.processPhoto(
        bytes,
        settings: _processorSettings,
        portraitSettings: portraitEnabled ? _portraitSettings : null,
      );

      await _save(processed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _save(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/motoprocam_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(path).writeAsBytes(bytes);
    await GallerySaver.saveImage(path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Saved to gallery'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selectLens(int cameraIndex) async {
    await _cameraService.selectLens(cameraIndex);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _depthDetectionService.dispose();
    super.dispose();
  }

  Widget _buildModePanel() {
    switch (_selectedMode) {
      case 'Portrait':
        return PortraitModeScreen(
          settings: _portraitSettings,
          onChanged: (value) => setState(() => _portraitSettings = value),
        );
      case 'Pro':
        return ProModeScreen(
          settings: _cameraSettings,
          onChanged: (value) {
            setState(() => _cameraSettings = value);
            _cameraService.applyManualSettings(value);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            CameraPreview(controller)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (_cameraSettings.showFocusPeaking)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.lightGreenAccent.withOpacity(0.65), width: 2),
                ),
              ),
            ),
          Positioned(
            top: 54,
            left: 16,
            right: 16,
            child: CameraLensSelector(
              lenses: _cameraService.lensProfiles,
              selectedCameraIndex: _cameraService.selectedCameraIndex,
              onSelect: _selectLens,
            ),
          ),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _modes
                  .map(
                    (mode) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(mode),
                        selected: _selectedMode == mode,
                        selectedColor: Colors.amber,
                        labelStyle: TextStyle(
                          color: _selectedMode == mode ? Colors.black : Colors.white,
                        ),
                        onSelected: (_) => setState(() => _selectedMode = mode),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          if (_showControls)
            Positioned(
              left: 12,
              right: 12,
              bottom: 160,
              child: _buildModePanel(),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_showControls ? Icons.tune : Icons.tune_outlined),
                  color: _showControls ? Colors.amber : Colors.white,
                  onPressed: () => setState(() => _showControls = !_showControls),
                ),
                Expanded(
                  child: Slider(
                    value: _zoomPercent,
                    min: 0,
                    max: 1,
                    activeColor: Colors.amber,
                    onChanged: (value) {
                      setState(() => _zoomPercent = value);
                      _cameraService.setZoomPercent(value);
                    },
                  ),
                ),
                GestureDetector(
                  onTap: _isCapturing ? null : _capture,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white54, width: 3),
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
