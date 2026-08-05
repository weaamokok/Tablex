import 'package:flutter/material.dart';
import 'package:tablex/tablex.dart';
import 'package:tablex_example/domain/employee.dart';

class CustomDepartmentFilterBar extends StatelessWidget {
  const CustomDepartmentFilterBar({
    required this.filters,
    required this.controller,
  });

  final List<TablexActiveFilter> filters;
  final TablexController<Employee> controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final filter in filters)
            _FilterRow(filter: filter, controller: controller),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.controller});

  final TablexActiveFilter filter;
  final TablexController<Employee> controller;

  Set<String> _activeValues() {
    final raw = controller.state.query.params[filter.key] as String? ?? '';
    return raw.split(',').where((s) => s.isNotEmpty).toSet();
  }

  void _toggle(String value) {
    final active = _activeValues();
    if (filter.singleSelect) {
      controller.setParam(filter.key, active.contains(value) ? '' : value);
    } else {
      final next = Set<String>.from(active);
      if (next.contains(value)) {
        next.remove(value);
      } else {
        next.add(value);
      }
      controller.setParam(filter.key, next.join(','));
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeValues();
    final colorScheme = Theme.of(context).colorScheme;
    final hasActive = active.isNotEmpty;

    return Row(
      children: [
        Text(
          '${filter.label}:',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filter.values.map((v) {
                final selected = active.contains(v.value);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(v.label),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => _toggle(v.value),
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (hasActive)
          TextButton(
            onPressed: () => controller.setParam(filter.key, ''),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
