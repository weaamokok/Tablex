import 'package:flutter/material.dart';
import 'package:tablex/tablex.dart';
import 'package:tablex_example/domain/country.dart';
import 'package:tablex_example/domain/fake_data.dart';
import 'package:tablex_example/features/select_picker/country_column_builder.dart';
import 'package:tablex_example/features/select_picker/country_row_builder.dart';

class SelectPickerScreen extends StatefulWidget {
  const SelectPickerScreen();

  @override
  State<SelectPickerScreen> createState() => _SelectPickerScreenState();
}

class _SelectPickerScreenState extends State<SelectPickerScreen> {
  List<Country> _selected = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Picker',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Multi-select mode. Tap a row to add it to your selection.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          // Selection summary chip row
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...(_selected.map(
                    (c) => Chip(
                      label: Text(c.name),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(
                          () => _selected.removeWhere((s) => s.code == c.code)),
                    ),
                  )),
                  ActionChip(
                    label: const Text('Clear all'),
                    onPressed: () => setState(() => _selected.clear()),
                    avatar: const Icon(Icons.clear_all, size: 16),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Tablex<Country>.select(
              columns: countryColumns,
              rows: const [...countries],
              rowBuilder: countryRowBuilder,
              multiSelect: true,
              density: TablexDensity.compact,
              onSelectionChanged: (selected) =>
                  setState(() => _selected = selected),
              theme: const TablexThemeData(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          // Bottom action bar
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Text(
                    '${_selected.length} countries selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              'Selected: ${_selected.map((c) => c.name).join(', ')}',
                            ),
                          ),
                        );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
