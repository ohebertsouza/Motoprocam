enum ExposureMeteringMode { spot, centerWeighted, matrix }

class CameraSettings {
  const CameraSettings({
    this.iso = 100,
    this.shutterSpeedMs = 16.7,
    this.whiteBalanceKelvin = 5500,
    this.focusDistance = 0.0,
    this.exposureCompensation = 0.0,
    this.enableRawCapture = false,
    this.showFocusPeaking = false,
    this.meteringMode = ExposureMeteringMode.matrix,
  });

  final int iso;
  final double shutterSpeedMs;
  final int whiteBalanceKelvin;
  final double focusDistance;
  final double exposureCompensation;
  final bool enableRawCapture;
  final bool showFocusPeaking;
  final ExposureMeteringMode meteringMode;

  CameraSettings copyWith({
    int? iso,
    double? shutterSpeedMs,
    int? whiteBalanceKelvin,
    double? focusDistance,
    double? exposureCompensation,
    bool? enableRawCapture,
    bool? showFocusPeaking,
    ExposureMeteringMode? meteringMode,
  }) {
    return CameraSettings(
      iso: (iso ?? this.iso).clamp(100, 6400).toInt(),
      shutterSpeedMs: (shutterSpeedMs ?? this.shutterSpeedMs).clamp(0.125, 1000.0),
      whiteBalanceKelvin: (whiteBalanceKelvin ?? this.whiteBalanceKelvin).clamp(2000, 9000).toInt(),
      focusDistance: (focusDistance ?? this.focusDistance).clamp(0.0, 1.0),
      exposureCompensation: (exposureCompensation ?? this.exposureCompensation).clamp(-2.0, 2.0),
      enableRawCapture: enableRawCapture ?? this.enableRawCapture,
      showFocusPeaking: showFocusPeaking ?? this.showFocusPeaking,
      meteringMode: meteringMode ?? this.meteringMode,
    );
  }
}
