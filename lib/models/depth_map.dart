class DepthMap {
  final int width;
  final int height;
  final List<double> values;

  const DepthMap({
    required this.width,
    required this.height,
    required this.values,
  });

  double depthAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) {
      return 1.0;
    }
    return values[(y * width) + x];
  }

  DepthMap normalized() {
    if (values.isEmpty) return this;
    double min = values.first;
    double max = values.first;
    for (final value in values) {
      if (value < min) min = value;
      if (value > max) max = value;
    }
    final range = max - min;
    if (range <= 0.00001) {
      return DepthMap(
        width: width,
        height: height,
        values: List<double>.filled(values.length, 0.5),
      );
    }

    return DepthMap(
      width: width,
      height: height,
      values: values.map((value) => ((value - min) / range).clamp(0.0, 1.0)).toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'values': values,
  };

  factory DepthMap.fromJson(Map<String, dynamic> json) {
    return DepthMap(
      width: json['width'] as int,
      height: json['height'] as int,
      values: (json['values'] as List).cast<num>().map((value) => value.toDouble()).toList(growable: false),
    );
  }
}
