enum PortraitLightingEffect { natural, studio, ring, stage, contour }

class PortraitSettings {
  const PortraitSettings({
    this.blurPercent = 40,
    this.depthStrength = 0.5,
    this.enableFacePriority = true,
    this.lightingEffect = PortraitLightingEffect.natural,
  });

  final int blurPercent;
  final double depthStrength;
  final bool enableFacePriority;
  final PortraitLightingEffect lightingEffect;

  double get blurAmount => blurPercent / 100.0;

  PortraitSettings copyWith({
    int? blurPercent,
    double? depthStrength,
    bool? enableFacePriority,
    PortraitLightingEffect? lightingEffect,
  }) {
    return PortraitSettings(
      blurPercent: (blurPercent ?? this.blurPercent).clamp(0, 100).toInt(),
      depthStrength: (depthStrength ?? this.depthStrength).clamp(0.0, 1.0),
      enableFacePriority: enableFacePriority ?? this.enableFacePriority,
      lightingEffect: lightingEffect ?? this.lightingEffect,
    );
  }
}
