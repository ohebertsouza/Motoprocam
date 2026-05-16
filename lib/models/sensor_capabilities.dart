class SensorCapabilities {
  final String cameraId;
  final int maxWidth;
  final int maxHeight;
  final bool supportsRaw;
  final List<Map<String, int>> availableResolutions;

  const SensorCapabilities({
    required this.cameraId,
    required this.maxWidth,
    required this.maxHeight,
    required this.supportsRaw,
    required this.availableResolutions,
  });

  factory SensorCapabilities.fromMap(Map<dynamic, dynamic> map) {
    final resolutions = <Map<String, int>>[];
    final dynamic rawResolutions = map['availableResolutions'];
    if (rawResolutions is List) {
      for (final item in rawResolutions) {
        if (item is Map) {
          final width = (item['width'] as num?)?.toInt();
          final height = (item['height'] as num?)?.toInt();
          if (width != null && height != null) {
            resolutions.add({'width': width, 'height': height});
          }
        }
      }
    }

    return SensorCapabilities(
      cameraId: (map['cameraId'] ?? '0').toString(),
      maxWidth: (map['maxWidth'] as num?)?.toInt() ?? 0,
      maxHeight: (map['maxHeight'] as num?)?.toInt() ?? 0,
      supportsRaw: map['supportsRaw'] == true,
      availableResolutions: resolutions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cameraId': cameraId,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'supportsRaw': supportsRaw,
      'availableResolutions': availableResolutions,
    };
  }
}
