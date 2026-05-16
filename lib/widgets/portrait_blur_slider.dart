import 'package:flutter/material.dart';

class PortraitBlurSlider extends StatelessWidget {
  const PortraitBlurSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bokeh ${value.toString()}%', style: const TextStyle(color: Colors.white)),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: '$value%',
          activeColor: Colors.amber,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
