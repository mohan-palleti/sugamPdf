import 'package:flutter/material.dart';
import '../models/annotation.dart';

class AnnotationToolbar extends StatelessWidget {
  final AnnotationType selectedTool;
  final Color selectedColor;
  final double strokeWidth;
  final Function(AnnotationType) onToolSelected;
  final Function(Color) onColorSelected;
  final Function(double) onStrokeWidthChanged;

  const AnnotationToolbar({
    Key? key,
    required this.selectedTool,
    required this.selectedColor,
    required this.strokeWidth,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onStrokeWidthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(
                context,
                AnnotationType.drawing,
                Icons.edit,
                'Draw',
              ),
              _buildToolButton(
                context,
                AnnotationType.text,
                Icons.text_fields,
                'Text',
              ),
              _buildToolButton(
                context,
                AnnotationType.highlight,
                Icons.highlight,
                'Highlight',
              ),
              _buildToolButton(
                context,
                AnnotationType.shape,
                Icons.rectangle_outlined,
                'Shape',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 8),
              const Text('Color:'),
              const SizedBox(width: 8),
              ..._buildColorButtons(),
              const SizedBox(width: 16),
              const Text('Width:'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: strokeWidth,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: strokeWidth.toStringAsFixed(1),
                  onChanged: onStrokeWidthChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context,
    AnnotationType type,
    IconData icon,
    String tooltip,
  ) {
    final isSelected = selectedTool == type;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onToolSelected(type),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildColorButtons() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
    ];

    return colors.map((color) {
      final isSelected = selectedColor.value == color.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.grey,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }).toList();
  }
}
