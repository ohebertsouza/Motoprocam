import 'package:flutter/material.dart';

import '../models/portrait_settings.dart';
import '../widgets/portrait_blur_slider.dart';

class PortraitModeScreen extends StatelessWidget {
  const PortraitModeScreen({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final PortraitSettings settings;
  final ValueChanged<PortraitSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PortraitBlurSlider(
            value: settings.blurPercent,
            onChanged: (value) => onChanged(settings.copyWith(blurPercent: value)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Depth strength', style: TextStyle(color: Colors.white70)),
              Text(
                settings.depthStrength.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Slider(
            value: settings.depthStrength,
            min: 0,
            max: 1,
            activeColor: Colors.amber,
            onChanged: (value) => onChanged(settings.copyWith(depthStrength: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Face priority focus', style: TextStyle(color: Colors.white70)),
            value: settings.enableFacePriority,
            activeColor: Colors.amber,
            onChanged: (value) => onChanged(settings.copyWith(enableFacePriority: value)),
          ),
          DropdownButtonFormField<PortraitLightingEffect>(
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Portrait light',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            value: settings.lightingEffect,
            items: PortraitLightingEffect.values
                .map(
                  (effect) => DropdownMenuItem(
                    value: effect,
                    child: Text(effect.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onChanged(settings.copyWith(lightingEffect: value));
              }
            },
          ),
        ],
      ),
    );
  }
}
