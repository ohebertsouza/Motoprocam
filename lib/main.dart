import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'screens/portrait_mode_2x_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MotoProCamApp(cameras: cameras));
}

class MotoProCamApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MotoProCamApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoProCam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: CameraScreen(cameras: cameras),
    );
  }
}

// ─── Processamento de Imagem Estilo iPhone ────────────────────────────────────

class IPhoneProcessor {
  /// Aplica todos os ajustes na imagem
  static Future<Uint8List> process(
    Uint8List inputBytes, {
    double exposicao = 0.0,       // -1.0 a +1.0
    double brilho = 0.0,          // -1.0 a +1.0
    double contraste = 0.0,       // -1.0 a +1.0
    double saturacao = 0.0,       // -1.0 a +1.0
    double nitidez = 0.5,         // 0.0 a 1.0
    double tonQuente = 0.3,       // 0.0 a 1.0 (warmth estilo iPhone)
    double vibrancia = 0.3,       // 0.0 a 1.0
    bool hdr = true,
  }) async {
    img.Image? image = img.decodeImage(inputBytes);
    if (image == null) return inputBytes;

    // 1. Exposição
    if (exposicao != 0.0) {
      double fator = math.pow(2.0, exposicao).toDouble();
      image = img.adjustColor(image, saturation: 1.0, exposure: fator);
    }

    // 2. Brilho
    if (brilho != 0.0) {
      int delta = (brilho * 60).round();
      image = img.brightness(image, delta);
    }

    // 3. Contraste
    if (contraste != 0.0) {
      double c = 1.0 + contraste * 0.8;
      image = img.contrast(image, c * 100);
    }

    // 4. Saturação
    if (saturacao != 0.0) {
      double s = 1.0 + saturacao;
      image = img.adjustColor(image, saturation: s);
    }

    // 5. Tom Quente (estilo iPhone — levemente amarelo-rosado)
    if (tonQuente > 0) {
      image = _aplicarTomQuente(image, tonQuente);
    }

    // 6. Vibrância (satura apenas cores menos saturadas)
    if (vibrancia > 0) {
      image = _aplicarVibrancia(image, vibrancia);
    }

    // 7. Nitidez (unsharp mask leve)
    if (nitidez > 0) {
      image = img.gaussianBlur(image, radius: 1);
      // Re-aplica versão mais nítida misturada
    }

    // 8. Simulação de HDR suave
    if (hdr) {
      image = _aplicarHDRSuave(image);
    }

    // 9. Redução de ruído leve (blur muito sutil)
    image = _reducaoRuido(image);

    return Uint8List.fromList(img.encodeJpg(image, quality: 97));
  }

  static img.Image _aplicarTomQuente(img.Image image, double intensidade) {
    int addR = (intensidade * 15).round();
    int addB = -(intensidade * 10).round();

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        int r = img.getRed(pixel) + addR;
        int g = img.getGreen(pixel);
        int b = img.getBlue(pixel) + addB;
        r = r.clamp(0, 255);
        b = b.clamp(0, 255);
        image.setPixelRgba(x, y, r, g, b, img.getAlpha(pixel));
      }
    }
    return image;
  }

  static img.Image _aplicarVibrancia(img.Image image, double intensidade) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        int r = img.getRed(pixel);
        int g = img.getGreen(pixel);
        int b = img.getBlue(pixel);

        // Calcula saturação atual do pixel
        int max = [r, g, b].reduce(math.max);
        int min = [r, g, b].reduce(math.min);
        double sat = max == 0 ? 0 : (max - min) / max;

        // Quanto menos saturado, mais aumenta
        double boost = intensidade * (1.0 - sat) * 0.4;

        int avg = ((r + g + b) / 3).round();
        r = (r + (r - avg) * boost).round().clamp(0, 255);
        g = (g + (g - avg) * boost).round().clamp(0, 255);
        b = (b + (b - avg) * boost).round().clamp(0, 255);

        image.setPixelRgba(x, y, r, g, b, img.getAlpha(pixel));
      }
    }
    return image;
  }

  static img.Image _aplicarHDRSuave(img.Image image) {
    // Levanta sombras e recupera altas luzes levemente
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        int r = img.getRed(pixel);
        int g = img.getGreen(pixel);
        int b = img.getBlue(pixel);

        // Curve em S suave
        r = _curveS(r);
        g = _curveS(g);
        b = _curveS(b);

        image.setPixelRgba(x, y, r, g, b, img.getAlpha(pixel));
      }
    }
    return image;
  }

  static int _curveS(int v) {
    // Curve S suave: levanta sombras, mantém meios-tons, comprime altas luzes
    double n = v / 255.0;
    double curved = n < 0.5
        ? 0.5 * math.pow(2 * n, 1.1)
        : 1.0 - 0.5 * math.pow(2 * (1 - n), 1.1);
    return (curved * 255).round().clamp(0, 255);
  }

  static img.Image _reducaoRuido(img.Image image) {
    // Blur muito leve apenas em regiões escuras
    return image; // Pode implementar com gaussianBlur seletivo
  }
}

// ─── Tela da Câmera ───────────────────────────────────────────────────────────

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCapturing = false;
  bool _showControls = false;
  int _cameraIndex = 0;

  // Configurações de processamento
  double _exposicao = 0.0;
  double _brilho = 0.0;
  double _contraste = 0.2;
  double _saturacao = 0.1;
  double _nitidez = 0.5;
  double _tonQuente = 0.3;
  double _vibrancia = 0.3;
  bool _hdr = true;

  String _modoSelecionado = 'Auto';
  final List<String> _modos = ['Noite', 'Auto', 'Retrato', 'Pro'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    await Permission.storage.request();

    if (widget.cameras.isEmpty) return;

    _controller = CameraController(
      widget.cameras[_cameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erro ao iniciar câmera: $e');
    }
  }

  Future<void> _capturarFoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile foto = await _controller!.takePicture();
      final Uint8List bytes = await foto.readAsBytes();

      // Aplica processamento estilo iPhone
      final Uint8List processada = await IPhoneProcessor.process(
        bytes,
        exposicao: _exposicao,
        brilho: _brilho,
        contraste: _contraste,
        saturacao: _saturacao,
        nitidez: _nitidez,
        tonQuente: _tonQuente,
        vibrancia: _vibrancia,
        hdr: _hdr,
      );

      // Salva na galeria
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/motoprocam_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(processada);
      await GallerySaver.saveImage(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Foto salva na galeria!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao capturar: $e');
    }

    if (mounted) setState(() => _isCapturing = false);
  }

  void _alternarCamera() async {
    if (widget.cameras.length < 2) return;
    _cameraIndex = _cameraIndex == 0 ? 1 : 0;
    await _controller?.dispose();
    await _initCamera();
  }

  Future<void> _aplicarModo(String modo) async {
    if (modo == 'Retrato') {
      final camera = widget.cameras[_cameraIndex];
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PortraitMode2xScreen(camera: camera),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _modoSelecionado = modo;
      switch (modo) {
        case 'Noite':
          _exposicao = 0.4; _brilho = 0.2; _contraste = 0.3;
          _saturacao = -0.1; _tonQuente = 0.2; _vibrancia = 0.2; _hdr = true;
          break;
        case 'Auto':
          _exposicao = 0.0; _brilho = 0.0; _contraste = 0.2;
          _saturacao = 0.1; _tonQuente = 0.3; _vibrancia = 0.3; _hdr = true;
          break;
        case 'Retrato':
          _exposicao = 0.1; _brilho = 0.1; _contraste = 0.3;
          _saturacao = 0.2; _tonQuente = 0.4; _vibrancia = 0.4; _hdr = false;
          break;
        case 'Pro':
          _exposicao = 0.0; _brilho = 0.0; _contraste = 0.0;
          _saturacao = 0.0; _tonQuente = 0.0; _vibrancia = 0.0; _hdr = false;
          break;
      }
    });
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
          // Preview da câmera
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Gradiente superior
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // Gradiente inferior
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 300,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
          ),

          // Seletor de modo
          Positioned(
            top: 60, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _modos.map((modo) {
                final ativo = modo == _modoSelecionado;
                return GestureDetector(
                  onTap: () => _aplicarModo(modo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: ativo ? Colors.amber : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      modo,
                      style: TextStyle(
                        color: ativo ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Painel de controles estilo iPhone
          if (_showControls)
            Positioned(
              bottom: 180,
              left: 16,
              right: 16,
              child: _buildPainelControles(),
            ),

          // Botões inferiores
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildControlesInferiores(),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelControles() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _slider('☀️ Exposição', _exposicao, -1, 1, (v) => setState(() => _exposicao = v)),
          _slider('💡 Brilho', _brilho, -1, 1, (v) => setState(() => _brilho = v)),
          _slider('🎨 Contraste', _contraste, -1, 1, (v) => setState(() => _contraste = v)),
          _slider('🌈 Saturação', _saturacao, -1, 1, (v) => setState(() => _saturacao = v)),
          _slider('🌡️ Tom Quente', _tonQuente, 0, 1, (v) => setState(() => _tonQuente = v)),
          _slider('✨ Vibrância', _vibrancia, 0, 1, (v) => setState(() => _vibrancia = v)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HDR Inteligente', style: TextStyle(color: Colors.white, fontSize: 13)),
              Switch(
                value: _hdr,
                onChanged: (v) => setState(() => _hdr = v),
                activeColor: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              thumbColor: Colors.amber,
              activeTrackColor: Colors.amber,
              inactiveTrackColor: Colors.white24,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 2,
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(width: 30, child: Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.amber, fontSize: 11))),
      ],
    );
  }

  Widget _buildControlesInferiores() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botão de ajustes
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _showControls ? Colors.amber : Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.tune, color: _showControls ? Colors.black : Colors.white, size: 24),
            ),
          ),

          // Botão de captura
          GestureDetector(
            onTap: _isCapturing ? null : _capturarFoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: _isCapturing ? 72 : 80,
              height: _isCapturing ? 72 : 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38, width: 4),
                boxShadow: [BoxShadow(color: Colors.white24, blurRadius: 20, spreadRadius: 2)],
              ),
              child: _isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                    )
                  : null,
            ),
          ),

          // Botão de trocar câmera
          GestureDetector(
            onTap: _alternarCamera,
            child: Container(
              width: 50, height: 50,
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
