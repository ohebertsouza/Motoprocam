class ImageProcessorSettings {
  const ImageProcessorSettings({
    this.exposure = 0.0,
    this.contrast = 0.1,
    this.saturation = 0.1,
    this.shadows = 0.2,
    this.highlights = 0.2,
    this.noiseReduction = 0.2,
    this.whiteBalanceKelvin = 5500,
    this.enableCurves = true,
    this.enableLut = false,
  });

  final double exposure;
  final double contrast;
  final double saturation;
  final double shadows;
  final double highlights;
  final double noiseReduction;
  final int whiteBalanceKelvin;
  final bool enableCurves;
  final bool enableLut;

  ImageProcessorSettings copyWith({
    double? exposure,
    double? contrast,
    double? saturation,
    double? shadows,
    double? highlights,
    double? noiseReduction,
    int? whiteBalanceKelvin,
    bool? enableCurves,
    bool? enableLut,
  }) {
    return ImageProcessorSettings(
      exposure: (exposure ?? this.exposure).clamp(-1.0, 1.0),
      contrast: (contrast ?? this.contrast).clamp(-1.0, 1.0),
      saturation: (saturation ?? this.saturation).clamp(-1.0, 1.0),
      shadows: (shadows ?? this.shadows).clamp(0.0, 1.0),
      highlights: (highlights ?? this.highlights).clamp(0.0, 1.0),
      noiseReduction: (noiseReduction ?? this.noiseReduction).clamp(0.0, 1.0),
      whiteBalanceKelvin: (whiteBalanceKelvin ?? this.whiteBalanceKelvin).clamp(2000, 9000).toInt(),
      enableCurves: enableCurves ?? this.enableCurves,
      enableLut: enableLut ?? this.enableLut,
    );
  }
}
