enum CaptureResolutionMode {
  mp16,
  mp32,
  mp64Raw,
}

class ResolutionConfig {
  final CaptureResolutionMode mode;
  final int width;
  final int height;
  final String label;
  final bool requiresRaw;

  const ResolutionConfig({
    required this.mode,
    required this.width,
    required this.height,
    required this.label,
    this.requiresRaw = false,
  });

  int get megapixels => ((width * height) / 1000000).round();

  static const ResolutionConfig mp16 = ResolutionConfig(
    mode: CaptureResolutionMode.mp16,
    width: 4624,
    height: 3468,
    label: '16MP',
  );

  static const ResolutionConfig mp32 = ResolutionConfig(
    mode: CaptureResolutionMode.mp32,
    width: 6936,
    height: 4624,
    label: '32MP',
  );

  static const ResolutionConfig mp64Raw = ResolutionConfig(
    mode: CaptureResolutionMode.mp64Raw,
    width: 9248,
    height: 6936,
    label: '64MP RAW',
    requiresRaw: true,
  );

  static const List<ResolutionConfig> defaults = [mp16, mp32, mp64Raw];
}
