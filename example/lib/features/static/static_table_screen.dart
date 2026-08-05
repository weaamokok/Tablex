import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablex/tablex.dart';
import 'package:tablex_example/shared/employee_column.dart';

import '../../domain/employee.dart';

class StaticGridScreen extends StatefulWidget {
  const StaticGridScreen();

  @override
  State<StaticGridScreen> createState() => _StaticGridScreenState();
}

class _StaticGridScreenState extends State<StaticGridScreen> {
  late List<Employee> _rows;
  final _controller = TablexController<Employee>();

  @override
  void initState() {
    super.initState();
    _rows = allEmployees.take(20).toList();
    _loadPdfFont();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPdfFont() async {
    final font = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    _controller.pdfConfig = TablexPdfConfig(
      fontData: font,
      fontBoldData: bold,
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final columns = buildEmployeeColumns(
      showActions: true,
      onEdit: (e) => _showSnack('Edit: ${e.name}'),
      onDelete: (e) {
        setState(() => _rows.removeWhere((r) => r.id == e.id));
        _showSnack('Deleted: ${e.name}');
      },
    );
    TablexRow<Employee> _employeeRowBuilder(Employee e) => TablexRow(
          data: e,
          key: e.id.toString(),
          cells: {
            'id': e.id,
            'name': e.name,
            'department': e.department,
            'salary': e.salary,
            'joinDate': e.joinDate,
            'status': e.status,
            'isManager': e.isManager,
            'actions': null,
          },
        );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Static Grid',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_rows.length} employees — all data loaded at once. '
            'Supports sort arrows, column resize, and action buttons.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Tablex<Employee>.static(
              controller: _controller,
              columns: columns,
              rows: _rows,
              showSelectionSummary: true,
              selectionActions: [
                TablexSelectionAction(
                  label: '',
                  icon: Icons.import_export_outlined,
                  onPressed: (selected) {
                    _showSnack('Exporting ${selected.length} rows: '
                        '${selected.map((e) => e.name).join(', ')}');
                  },
                )
              ],
              theme: TablexThemeData(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12)),
                  checkboxTheme: TablexCheckboxTheme(
                      checkColor: Colors.white,
                      activeColor: Colors.blue,
                      size: 16,
                      doubleBorder: true)),
              rowBuilder: _employeeRowBuilder,
              density: TablexDensity.comfortable,
              selectionMode: TablexSelectionMode.multiple,
              noDataWidget: Center(
                  child: Icon(
                Icons.email, size: 100,
                //style: TextStyle(color: Colors.black),
              )),
              onRowTap: (e) => _showSnack('Tapped: ${e.name}'),
              onRowDoubleTap: (e) => _showSnack('Double-tap: ${e.name}'),
            ),
          ),
        ],
      ),
    );
  }
}
