import 'package:flutter/material.dart';

import '../models/camera_settings.dart';
import '../widgets/pro_controls_panel.dart';

class ProModeScreen extends StatelessWidget {
  const ProModeScreen({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final CameraSettings settings;
  final ValueChanged<CameraSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return ProControlsPanel(
      settings: settings,
      onChanged: onChanged,
    );
  }
}
