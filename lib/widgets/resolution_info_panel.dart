import 'package:flutter/material.dart';

import '../models/resolution_config.dart';
import '../models/sensor_capabilities.dart';

class ResolutionInfoPanel extends StatelessWidget {
  final ResolutionConfig selected;
  final SensorCapabilities? sensor;

  const ResolutionInfoPanel({
    super.key,
    required this.selected,
    this.sensor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saída: ${selected.label} (~${selected.megapixels}MP)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sensor != null)
            Text(
              'Sensor: ${sensor!.maxWidth}x${sensor!.maxHeight} | RAW: ${sensor!.supportsRaw ? 'sim' : 'não'}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
