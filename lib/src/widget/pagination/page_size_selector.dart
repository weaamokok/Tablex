import 'package:flutter/material.dart';
import '../../theme/grid_theme_data.dart';

class TablexPageSizeSelector extends StatelessWidget {
  const TablexPageSizeSelector({
    super.key,
    required this.currentSize,
    required this.options,
    required this.onChanged,
    required this.theme,
  });

  final int currentSize;
  final List<int> options;
  final void Function(int) onChanged;
  final TablexThemeData theme;

  @override
  Widget build(BuildContext context) {
    final effectiveValue =
        options.contains(currentSize) ? currentSize : options.first;
    return DropdownButton<int>(
      value: effectiveValue,
      items: options
          .map((s) =>
              DropdownMenuItem(value: s, child: Text('$s / page')))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
      underline: const SizedBox.shrink(),
      isDense: true,
    );
  }
}
