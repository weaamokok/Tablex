import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablex/tablex.dart';
import 'package:tablex_example/features/import_export/widget/department_drop_down.dart';
import 'package:tablex_example/shared/employee_row.dart';

import '../../domain/employee.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen();

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final _controller = TablexController<Employee>();
  late final List<Employee> _initialRows = allEmployees.take(50).toList();

  // Applies an edited Employee back into the controller, keeping row.data in
  // sync so that subsequent exports reflect the latest values.
  void _applyEdit(Employee original, Employee updated) {
    final index = _controller.getAllRowData().indexOf(original);
    if (index == -1) return;
    _controller.updateRow(index, updated, rowBuilder: employeeRowBuilder);
  }

  late final _columns = <TablexColumnBase<Employee>>[
    TablexColumn<Employee, String>(
      fieldKey: 'id',
      title: 'Id',
      width: 50,
      type: TablexColumnType.id,
      valueGetter: (e) => e.id.toString(),
    ),
    TablexColumn<Employee, String>(
      fieldKey: 'name',
      title: 'Name',
      width: 180,
      enableEditing: true,
      valueGetter: (e) => e.name,
      cellRenderer: TablexRenderers.avatarTwoLine(
        secondLine: (e) => e.email,
        avatar: (_) => null,
      ),
      onEdit: (e, newName) => _applyEdit(e, e.copyWith(name: newName)),
    ),
    TablexColumn<Employee, String>(
      fieldKey: 'department',
      title: 'Department',
      width: 130,
      enableEditing: true,
      valueGetter: (e) => e.department,
      onEdit: (e, newDept) => _applyEdit(e, e.copyWith(department: newDept)),
      editRenderer: (context, employee, current, onSubmit, onCancel) =>
          DepartmentDropdown(
        current: current,
        onSubmit: onSubmit,
        onCancel: onCancel,
      ),
    ),
    TablexColumn<Employee, num>(
      fieldKey: 'salary',
      title: 'Salary',
      width: 130,
      textAlign: TextAlign.end,
      type: TablexColumnType.currency,
      enableEditing: true,
      valueGetter: (e) => e.salary,
      cellRenderer: TablexRenderers.currency(symbol: '\$'),
      onEdit: (e, newSalary) => _applyEdit(e, e.copyWith(salary: newSalary)),
    ),
    TablexColumn<Employee, DateTime?>(
      fieldKey: 'joinDate',
      title: 'Joined',
      width: 120,
      type: TablexColumnType.date,
      valueGetter: (e) => e.joinDate,
    ),
    TablexColumn<Employee, EmployeeStatus>(
      fieldKey: 'status',
      title: 'Status',
      width: 120,
      enableSorting: false,
      type: TablexColumnType.select,
      valueGetter: (e) => e.status,
      cellRenderer: TablexRenderers.statusChip(
        colors: {
          EmployeeStatus.active: Colors.green,
          EmployeeStatus.inactive: Colors.red,
          EmployeeStatus.onLeave: Colors.orange,
        },
        labels: {
          EmployeeStatus.active: 'Active',
          EmployeeStatus.inactive: 'Inactive',
          EmployeeStatus.onLeave: 'On Leave',
        },
      ),
    ),
    TablexColumn<Employee, bool>(
      fieldKey: 'isManager',
      title: 'Manager',
      width: 90,
      enableSorting: false,
      enableEditing: true,
      type: TablexColumnType.boolean,
      valueGetter: (e) => e.isManager,
      onEdit: (e, newValue) => _applyEdit(e, e.copyWith(isManager: newValue)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.replaceRows(_initialRows, rowBuilder: employeeRowBuilder);
    _loadPdfFont();
  }

  Future<void> _loadPdfFont() async {
    final font = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    _controller.pdfConfig = TablexPdfConfig(
      fontData: font,
      fontBoldData: bold,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Parses a CSV/Excel row map back into an Employee and wraps it in a
  /// [TablexRow]. Column headers match the titles defined in [_employeeColumns].
  TablexRow<Employee> _employeeFromImport(Map<String, String> map) =>
      employeeRowBuilder(Employee.fromMap(map));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import / Export',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${_controller.rowCount} rows — double-tap a cell to edit. '
            'Use the toolbar to export or import CSV / Excel.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: [
                TablexToolbar<Employee>(
                  controller: _controller,
                  columns: _columns,
                  importRowFactory: _employeeFromImport,
                ),
                Expanded(
                  child: Tablex<Employee>.static(
                    controller: _controller,
                    columns: _columns,
                    rows: _initialRows,
                    rowBuilder: employeeRowBuilder,
                    density: TablexDensity.standard,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
