import 'package:flutter/material.dart';

import '../models/portrait_effect_settings.dart';

class LensSelector2x extends StatelessWidget {
  final PortraitLensMode lensMode;
  final ValueChanged<PortraitLensMode> onChanged;

  const LensSelector2x({
    super.key,
    required this.lensMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: PortraitLensMode.values.map((mode) {
          final isSelected = mode == lensMode;
          final label = mode == PortraitLensMode.x1 ? '1x' : '2x';
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
