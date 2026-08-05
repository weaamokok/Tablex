import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tablex/tablex.dart';
import 'package:tablex_example/domain/employee.dart';

Future<TablexFetchResult<Employee>> _fakeInfiniteFetch(
  TablexQuery query,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));

  var data = List<Employee>.from(allEmployees);

  if (query.sort != null) {
    final field = query.sort!.field;
    final asc = query.sort!.direction == TablexSortDirection.ascending;
    data.sort((a, b) {
      final cmp = switch (field) {
        'name' => a.name.compareTo(b.name),
        'department' => a.department.compareTo(b.department),
        'salary' => a.salary.compareTo(b.salary),
        _ => 0,
      };
      return asc ? cmp : -cmp;
    });
  }

  final total = data.length;
  final start = (query.page - 1) * query.pageSize;
  final end = (start + query.pageSize).clamp(0, total);
  return TablexFetchResult(
    rows: data.sublist(start, end),
    totalRows: total,
  );
}

class InfiniteScrollScreen extends StatelessWidget {
  const InfiniteScrollScreen();

  @override
  Widget build(BuildContext context) {
    TablexRow<Employee> employeeRowBuilder(Employee e) => TablexRow(
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
            'Infinite Scroll',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'New rows are fetched automatically as you scroll down. '
            'Total dataset: 500 items, loaded 50 at a time.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Tablex<Employee>.infinite(
              columns: [
                TablexColumn<Employee, String>(
                  fieldKey: 'name',
                  title: 'Name',
                  width: 180,
                  valueGetter: (e) => e.name,
                  cellRenderer: TablexRenderers.twoLine(
                    secondLine: (e) => e.email,
                  ),
                ),
                TablexColumn<Employee, String>(
                  fieldKey: 'department',
                  title: 'Department',
                  width: 140,
                  valueGetter: (e) => e.department,
                ),
                TablexColumn<Employee, num>(
                  fieldKey: 'salary',
                  title: 'Salary',
                  width: 140,
                  textAlign: TextAlign.end,
                  valueGetter: (e) => e.salary,
                  cellRenderer: TablexRenderers.currency(
                      symbol: '\$',
                      negativeColor: Colors.redAccent,
                      positiveColor: Colors.green),
                ),
                TablexColumn<Employee, EmployeeStatus>(
                  fieldKey: 'status',
                  title: 'Status',
                  width: 120,
                  enableSorting: false,
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
              ],
              fetchTask: _fakeInfiniteFetch,
              fetchWithSorting: true,
              rowBuilder: employeeRowBuilder,
              density: TablexDensity.compact,
              fetchSize: 50,
              loadingBuilder: TablexLoadingBuilder(
                skeletonData:
                    List.generate(20, (i) => makeEmployee(i + 1, Random(i))),
                builder: (context, table) =>
                    Skeletonizer(enabled: true, child: table),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
