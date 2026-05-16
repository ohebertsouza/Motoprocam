import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/depth_map.dart';
import '../models/portrait_effect_settings.dart';
import '../services/depth_detection_service.dart';
import '../services/portrait_processing_service.dart';
import '../services/super_resolution_service.dart';
import '../widgets/depth_preview_widget.dart';
import '../widgets/lens_selector_2x.dart';
import '../widgets/portrait_blur_controls.dart';

class PortraitMode2xScreen extends StatefulWidget {
  final CameraDescription camera;

  const PortraitMode2xScreen({
    super.key,
    required this.camera,
  });

  @override
  State<PortraitMode2xScreen> createState() => _PortraitMode2xScreenState();
}

class _PortraitMode2xScreenState extends State<PortraitMode2xScreen> {
  late final DepthDetectionService _depthService;
  late final PortraitProcessingService _processingService;
  CameraController? _controller;

  bool _isCapturing = false;
  bool _showControls = true;
  bool _showDepthPreview = false;

  String _recommendation = '1x é ideal para grupos; 2x para retratos individuais.';
  PortraitEffectSettings _settings = PortraitEffectSettings.defaults;
  DepthMap? _lastDepthMap;

  @override
  void initState() {
    super.initState();
    _depthService = DepthDetectionService();
    _processingService = PortraitProcessingService(
      depthDetectionService: _depthService,
      superResolutionService: SuperResolutionService(),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    await Permission.storage.request();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Erro ao iniciar modo retrato: $e');
    }
  }

  Future<void> _capturePortrait() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final raw = await _controller!.takePicture();
      final bytes = await raw.readAsBytes();

      final result = await _processingService.process(
        bytes,
        settings: _settings,
        imagePath: raw.path,
      );

      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/portrait_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(savePath).writeAsBytes(result.imageBytes);
      await GallerySaver.saveImage(savePath);

      if (!mounted) return;
      setState(() {
        _lastDepthMap = result.depthMap;
        _recommendation = _settings.lensMode == PortraitLensMode.x2
            ? '2x ativo: compressão óptica simulada para rosto natural.'
            : '1x ativo: melhor para cenas amplas e múltiplas pessoas.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Retrato processado com mapa de profundidade'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Erro no retrato: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao processar retrato.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isCapturing = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _depthService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Retrato Pro 1x/2x'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          if (_showDepthPreview && _lastDepthMap != null)
            Positioned.fill(
              child: DepthPreviewWidget(depthMap: _lastDepthMap!),
            ),

          Positioned(
            top: 16,
            left: 16,
            child: LensSelector2x(
              lensMode: _settings.lensMode,
              onChanged: (mode) {
                setState(() {
                  _settings = _settings.copyWith(lensMode: mode);
                  _recommendation = mode == PortraitLensMode.x2
                      ? '2x recomendado para subject único e fundo comprimido.'
                      : '1x recomendado para grupos e ambientes amplos.';
                });
              },
            ),
          ),

          Positioned(
            top: 20,
            right: 12,
            child: IconButton(
              onPressed: () => setState(() => _showDepthPreview = !_showDepthPreview),
              icon: Icon(
                _showDepthPreview ? Icons.layers_clear : Icons.layers,
                color: Colors.white,
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 170,
            child: Text(
              _recommendation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          if (_showControls)
            Positioned(
              left: 14,
              right: 14,
              bottom: 210,
              child: PortraitBlurControls(
                settings: _settings,
                onChanged: (settings) => setState(() => _settings = settings),
                onReset: () => setState(() => _settings = PortraitEffectSettings.defaults),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => setState(() => _showControls = !_showControls),
                  icon: Icon(
                    _showControls ? Icons.tune : Icons.tune_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                GestureDetector(
                  onTap: _capturePortrait,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: _isCapturing ? 72 : 82,
                    height: _isCapturing ? 72 : 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white38, width: 4),
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                          )
                        : null,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
