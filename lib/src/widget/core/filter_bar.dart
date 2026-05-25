import 'package:flutter/material.dart';
import '../../controller/controller.dart';
import '../../model/response.dart';
import '../../../i18n/strings.g.dart';

class TablexFilterBar<T> extends StatelessWidget {
  const TablexFilterBar({
    super.key,
    required this.controller,
    required this.filters,
  });

  final TablexController<T> controller;
  final List<TablexActiveFilter> filters;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters
                    .map(
                      (f) => _FilterPill<T>(
                        filter: f,
                        controller: controller,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              for (final f in filters) {
                controller.removeParam(f.key);
              }
            },
            child: Text(tablexStrings(context).clearAll),
          ),
        ],
      ),
    );
  }
}

class _FilterPill<T> extends StatelessWidget {
  const _FilterPill({required this.filter, required this.controller});

  final TablexActiveFilter filter;
  final TablexController<T> controller;

  @override
  Widget build(BuildContext context) {
    final rawParam =
        controller.state.query.params[filter.key] as String? ?? '';
    final selectedValues = rawParam
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          selectedValues.isEmpty
              ? filter.label
              : '${filter.label}: ${selectedValues.join(', ')}',
          style: const TextStyle(fontSize: 12),
        ),
        selected: selectedValues.isNotEmpty,
        onSelected: (_) => _openMenu(context, selectedValues),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: selectedValues.isNotEmpty
            ? () => controller.removeParam(filter.key)
            : null,
      ),
    );
  }

  void _openMenu(BuildContext context, List<String> current) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _FilterDialog(
        filter: filter,
        currentValues: current,
        onApply: (selected) {
          if (selected.isEmpty) {
            controller.removeParam(filter.key);
          } else {
            controller.setParam(filter.key, selected.join(','));
          }
        },
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.filter,
    required this.currentValues,
    required this.onApply,
  });

  final TablexActiveFilter filter;
  final List<String> currentValues;
  final void Function(List<String>) onApply;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late final List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentValues);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.filter.label),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.filter.values
              .map(
                (v) => widget.filter.singleSelect
                    ? ListTile(
                        title: Text(v.label),
                        leading: Radio<String>(
                          value: v.value,
                          // ignore: deprecated_member_use
                          groupValue: _selected.firstOrNull,
                          // ignore: deprecated_member_use
                          onChanged: (s) => setState(() {
                            _selected
                              ..clear()
                              ..addAll([if (s != null) s]);
                          }),
                        ),
                        onTap: () => setState(() {
                          _selected
                            ..clear()
                            ..add(v.value);
                        }),
                        dense: true,
                      )
                    : CheckboxListTile(
                        title: Text(v.label),
                        value: _selected.contains(v.value),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _selected.add(v.value);
                          } else {
                            _selected.remove(v.value);
                          }
                        }),
                      ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tablexStrings(context).cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onApply(_selected);
            Navigator.pop(context);
          },
          child: Text(tablexStrings(context).apply),
        ),
      ],
    );
  }
}
