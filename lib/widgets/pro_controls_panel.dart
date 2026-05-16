import 'package:flutter/material.dart';

import '../models/camera_settings.dart';
import 'manual_adjustment_sliders.dart';

class ProControlsPanel extends StatelessWidget {
  const ProControlsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final CameraSettings settings;
  final ValueChanged<CameraSettings> onChanged;

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
          ManualAdjustmentSlider(
            label: 'ISO',
            value: settings.iso.toDouble(),
            min: 100,
            max: 6400,
            onChanged: (v) => onChanged(settings.copyWith(iso: v.round())),
          ),
          ManualAdjustmentSlider(
            label: 'Shutter',
            value: settings.shutterSpeedMs,
            min: 0.125,
            max: 1000,
            format: (v) => '${v.toStringAsFixed(v < 1 ? 2 : 1)}ms',
            onChanged: (v) => onChanged(settings.copyWith(shutterSpeedMs: v)),
          ),
          ManualAdjustmentSlider(
            label: 'WB',
            value: settings.whiteBalanceKelvin.toDouble(),
            min: 2000,
            max: 9000,
            format: (v) => '${v.round()}K',
            onChanged: (v) => onChanged(settings.copyWith(whiteBalanceKelvin: v.round())),
          ),
          ManualAdjustmentSlider(
            label: 'Focus',
            value: settings.focusDistance,
            min: 0,
            max: 1,
            format: (v) => v.toStringAsFixed(2),
            onChanged: (v) => onChanged(settings.copyWith(focusDistance: v)),
          ),
          ManualAdjustmentSlider(
            label: 'EV',
            value: settings.exposureCompensation,
            min: -2,
            max: 2,
            format: (v) => v.toStringAsFixed(1),
            onChanged: (v) => onChanged(settings.copyWith(exposureCompensation: v)),
          ),
          Row(
            children: [
              const Expanded(child: Text('RAW', style: TextStyle(color: Colors.white))),
              Switch(
                value: settings.enableRawCapture,
                onChanged: (value) => onChanged(settings.copyWith(enableRawCapture: value)),
                activeColor: Colors.amber,
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Peaking', style: TextStyle(color: Colors.white))),
              Switch(
                value: settings.showFocusPeaking,
                onChanged: (value) => onChanged(settings.copyWith(showFocusPeaking: value)),
                activeColor: Colors.amber,
              ),
            ],
          ),
          DropdownButtonFormField<ExposureMeteringMode>(
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Metering',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            value: settings.meteringMode,
            items: ExposureMeteringMode.values
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Text(mode.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onChanged(settings.copyWith(meteringMode: value));
              }
            },
          ),
        ],
      ),
    );
  }
}
