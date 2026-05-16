class CaptureMetadata {
  final int? iso;
  final int? shutterSpeedNs;
  final double? aperture;
  final double? focalLength;
  final DateTime timestamp;

  const CaptureMetadata({
    required this.timestamp,
    this.iso,
    this.shutterSpeedNs,
    this.aperture,
    this.focalLength,
  });

  factory CaptureMetadata.now({
    int? iso,
    int? shutterSpeedNs,
    double? aperture,
    double? focalLength,
  }) {
    return CaptureMetadata(
      timestamp: DateTime.now(),
      iso: iso,
      shutterSpeedNs: shutterSpeedNs,
      aperture: aperture,
      focalLength: focalLength,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'iso': iso,
      'shutterSpeedNs': shutterSpeedNs,
      'aperture': aperture,
      'focalLength': focalLength,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
