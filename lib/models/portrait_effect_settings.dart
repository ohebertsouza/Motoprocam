enum PortraitLensMode {
  x1,
  x2,
}

enum PortraitLightingMode {
  natural,
  studio,
  ring,
  stage,
}

class PortraitEffectSettings {
  final double blurIntensity;
  final double depthSensitivity;
  final double edgeSoftness;
  final PortraitLensMode lensMode;
  final PortraitLightingMode lightingMode;

  const PortraitEffectSettings({
    this.blurIntensity = 0.55,
    this.depthSensitivity = 0.45,
    this.edgeSoftness = 0.4,
    this.lensMode = PortraitLensMode.x1,
    this.lightingMode = PortraitLightingMode.natural,
  });

  PortraitEffectSettings copyWith({
    double? blurIntensity,
    double? depthSensitivity,
    double? edgeSoftness,
    PortraitLensMode? lensMode,
    PortraitLightingMode? lightingMode,
  }) {
    return PortraitEffectSettings(
      blurIntensity: blurIntensity ?? this.blurIntensity,
      depthSensitivity: depthSensitivity ?? this.depthSensitivity,
      edgeSoftness: edgeSoftness ?? this.edgeSoftness,
      lensMode: lensMode ?? this.lensMode,
      lightingMode: lightingMode ?? this.lightingMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blurIntensity': blurIntensity,
      'depthSensitivity': depthSensitivity,
      'edgeSoftness': edgeSoftness,
      'lensMode': lensMode.name,
      'lightingMode': lightingMode.name,
    };
  }

  factory PortraitEffectSettings.fromJson(Map<String, dynamic> json) {
    return PortraitEffectSettings(
      blurIntensity: (json['blurIntensity'] as num?)?.toDouble() ?? 0.55,
      depthSensitivity: (json['depthSensitivity'] as num?)?.toDouble() ?? 0.45,
      edgeSoftness: (json['edgeSoftness'] as num?)?.toDouble() ?? 0.4,
      lensMode: PortraitLensMode.values.firstWhere(
        (mode) => mode.name == json['lensMode'],
        orElse: () => PortraitLensMode.x1,
      ),
      lightingMode: PortraitLightingMode.values.firstWhere(
        (mode) => mode.name == json['lightingMode'],
        orElse: () => PortraitLightingMode.natural,
      ),
    );
  }

  static const PortraitEffectSettings defaults = PortraitEffectSettings();
}
