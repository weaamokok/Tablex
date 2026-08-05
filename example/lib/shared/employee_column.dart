import 'package:flutter/material.dart';
import 'package:tablex/tablex.dart';
import 'package:tablex_example/domain/employee.dart';

List<TablexColumnBase<Employee>> buildEmployeeColumns({
  bool showActions = false,
  void Function(Employee)? onEdit,
  void Function(Employee)? onDelete,
}) {
  return [
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
      valueGetter: (e) => e.name,
      cellRenderer: TablexRenderers.twoLine(
        secondLine: (e) => e.email,
        //  avatar: (_) => null,
      ),
    ),
    TablexColumn<Employee, String>(
      fieldKey: 'department',
      title: 'Department',
      width: 130,
      valueGetter: (e) => e.department,
    ),
    TablexColumn<Employee, num>(
      fieldKey: 'salary',
      title: 'Salary',
      width: 130,
      textAlign: TextAlign.end,
      type: TablexColumnType.currency,
      valueGetter: (e) => e.salary,
      cellRenderer: TablexRenderers.currency(symbol: '\$'),
    ),
    TablexColumn<Employee, DateTime?>(
      fieldKey: 'joinDate',
      title: 'Joined',
      width: 120,
      hideIfEmpty: true,
      valueGetter: (e) => e.joinDate,
      cellRenderer: TablexRenderers.date(),
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
      type: TablexColumnType.boolean,
      valueGetter: (e) => e.isManager,
    ),
    if (showActions && onEdit != null && onDelete != null)
      TablexColumn<Employee, dynamic>(
        fieldKey: 'actions',
        title: '',
        width: 90,
        enableSorting: false,
        type: TablexColumnType.action,
        valueGetter: (_) => null,
        cellRenderer: TablexRenderers.actions(
          actions: [
            TablexAction(
              icon: Icons.edit_outlined,
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            TablexAction(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onPressed: onDelete,
              isEnabled: (e) => !e.isManager,
            ),
          ],
        ),
      ),
  ];
}
