import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tablex/tablex.dart';
import 'package:tablex_example/domain/employee.dart';
import 'package:tablex_example/domain/fake_data.dart';
import 'package:tablex_example/shared/employee_column.dart';
import 'package:tablex_example/features/lazy_paged/widget/custom_department_filter_bar.dart';
import 'package:tablex_example/shared/employee_row.dart';

class LazyPagedGridScreen extends StatefulWidget {
  const LazyPagedGridScreen();

  @override
  State<LazyPagedGridScreen> createState() => _LazyPagedGridScreenState();
}

class _LazyPagedGridScreenState extends State<LazyPagedGridScreen> {
  Future<TablexFetchResult<Employee>> _fakePagedFetch(
    TablexQuery query,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    var data = List<Employee>.from(allEmployees);

    // Server-side department filter — values are comma-separated.
    final deptParam = query.params['department'] as String? ?? '';
    final selectedDepts =
        deptParam.split(',').where((s) => s.isNotEmpty).toSet();
    if (selectedDepts.isNotEmpty) {
      data = data.where((e) => selectedDepts.contains(e.department)).toList();
    }

    // Server-side sort
    if (query.sort != null) {
      final field = query.sort!.field;
      final asc = query.sort!.direction == TablexSortDirection.ascending;
      data.sort((a, b) {
        final cmp = switch (field) {
          'id' => a.id.compareTo(b.id),
          'name' => a.name.compareTo(b.name),
          'department' => a.department.compareTo(b.department),
          'salary' => a.salary.compareTo(b.salary),
          'joinDate' => a.joinDate == null && b.joinDate == null
              ? 0
              : a.joinDate == null
                  ? -1
                  : b.joinDate == null
                      ? 1
                      : a.joinDate!.compareTo(b.joinDate!),
          _ => 0,
        };
        return asc ? cmp : -cmp;
      });
    }

    final total = data.length;

    // Cursor encodes the start offset as a plain decimal string.
    // null cursor → first page (offset 0).
    final start = query.cursor != null ? (int.tryParse(query.cursor!) ?? 0) : 0;
    final end = (start + query.pageSize).clamp(0, total);
    final page = data.sublist(start, end);

    final nextStart = end;
    final prevStart = (start - query.pageSize).clamp(0, total);

    return TablexFetchResult(
      rows: page,
      totalRows: total,
      // Return a nextCursor only when more rows follow — this activates cursor
      // mode in the footer, which shows clickable page pills bounded to the
      // highest known page instead of the offset-mode "1 ... N" range.
      nextCursor: nextStart < total ? nextStart.toString() : null,
      prevCursor: start > 0 ? prevStart.toString() : null,
      meta: TablexResponseMeta(
        filters: [
          TablexActiveFilter(
            key: 'department',
            label: 'Department',
            values: departments
                .map((d) => TablexActiveFilterValue(value: d, label: d))
                .toList(),
          ),
        ],
      ),
    );
  }

  final _controller = TablexController<Employee>();
  late final _columns = buildEmployeeColumns();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lazy Paged Grid',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '200 total employees — server-side pagination, sorting, and '
            'department filter chips.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TablexConsumer<Employee>(
              controller: _controller,
              columns: _columns,
              fetchTask: _fakePagedFetch,
              rowBuilder: employeeRowBuilder,
              initialPageSize: 13,
              enablePageJump: true,
              fetchWithSorting: true,
              pageSizeSelectorBuilder:
                  (context, currentSize, options, onChanged) => SizedBox(),
              loadingBuilder: TablexLoadingBuilder(
                skeletonData:
                    List.generate(13, (i) => makeEmployee(i + 1, Random(i))),
                builder: (context, table) =>
                    Skeletonizer(enabled: true, child: table),
              ),
              tableHeader: TablexToolbar<Employee>(
                controller: _controller,
                columns: _columns,
              ),
              // Replace the built-in chip-dialog filter bar with our own
              // inline toggle-chip row so the user can filter without a dialog.
              filterBarBuilder: (context, filters, controller) =>
                  CustomDepartmentFilterBar(
                filters: filters,
                controller: controller,
              ),
              theme: const TablexThemeData(
                showVerticalCellBorders: false,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
