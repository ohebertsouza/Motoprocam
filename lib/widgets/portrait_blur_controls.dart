import 'package:flutter/material.dart';

import '../models/portrait_effect_settings.dart';

class PortraitBlurControls extends StatelessWidget {
  final PortraitEffectSettings settings;
  final ValueChanged<PortraitEffectSettings> onChanged;
  final VoidCallback onReset;

  const PortraitBlurControls({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSlider(
            label: 'Blur',
            value: settings.blurIntensity,
            onChanged: (value) => onChanged(settings.copyWith(blurIntensity: value)),
          ),
          _buildSlider(
            label: 'Profundidade',
            value: settings.depthSensitivity,
            onChanged: (value) => onChanged(settings.copyWith(depthSensitivity: value)),
          ),
          _buildSlider(
            label: 'Suavidade',
            value: settings.edgeSoftness,
            onChanged: (value) => onChanged(settings.copyWith(edgeSoftness: value)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Luz', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PortraitLightingMode>(
                    isExpanded: true,
                    dropdownColor: Colors.black,
                    value: settings.lightingMode,
                    items: PortraitLightingMode.values
                        .map(
                          (mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(
                              switch (mode) {
                                PortraitLightingMode.natural => 'Natural',
                                PortraitLightingMode.studio => 'Studio',
                                PortraitLightingMode.ring => 'Ring',
                                PortraitLightingMode.stage => 'Stage',
                              },
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (mode) {
                      if (mode == null) return;
                      onChanged(settings.copyWith(lightingMode: mode));
                    },
                  ),
                ),
              ),
              TextButton(
                onPressed: onReset,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            activeColor: Colors.amber,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '${(value * 100).round()}%',
            style: const TextStyle(color: Colors.amber, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
