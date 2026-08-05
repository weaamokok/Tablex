import 'package:flutter/material.dart';
import 'package:tablex_example/domain/fake_data.dart';

class DepartmentDropdown extends StatelessWidget {
  const DepartmentDropdown({
    required this.current,
    required this.onSubmit,
    required this.onCancel,
  });

  final String current;
  final void Function(String) onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        initialValue: departments.contains(current) ? current : null,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          border: UnderlineInputBorder(),
        ),
        items: departments
            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
            .toList(),
        onChanged: (v) {
          if (v != null) onSubmit(v);
        },
      ),
    );
  }
}
