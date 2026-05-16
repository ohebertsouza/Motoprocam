import 'package:flutter/material.dart';

import '../services/device_camera_info.dart';

class CameraLensSelector extends StatelessWidget {
  const CameraLensSelector({
    super.key,
    required this.lenses,
    required this.selectedCameraIndex,
    required this.onSelect,
  });

  final List<LensProfile> lenses;
  final int selectedCameraIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (lenses.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: lenses
          .map(
            (lens) => ChoiceChip(
              label: Text(lens.name),
              selected: lens.cameraIndex == selectedCameraIndex,
              selectedColor: Colors.amber,
              labelStyle: TextStyle(
                color: lens.cameraIndex == selectedCameraIndex ? Colors.black : Colors.white,
              ),
              onSelected: (_) => onSelect(lens.cameraIndex),
            ),
          )
          .toList(growable: false),
    );
  }
}
