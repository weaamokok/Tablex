import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tablex/tablex.dart';

void main() {
  runApp(const TablexExampleApp());
}

// ============================================================================
// App shell
// ============================================================================

class TablexExampleApp extends StatelessWidget {
  const TablexExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tablex Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C6BC0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _ExampleHome(),
    );
  }
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  int _tabIndex = 0;

  static const _tabs = [
    (icon: Icons.table_rows_outlined, label: 'Static'),
    (icon: Icons.cloud_outlined, label: 'Paged'),
    (icon: Icons.all_inclusive_outlined, label: 'Infinite'),
    (icon: Icons.checklist_outlined, label: 'Select'),
    (icon: Icons.import_export_outlined, label: 'I/O'),
  ];

  static const _screens = [
    _StaticGridScreen(),
    _LazyPagedGridScreen(),
    _InfiniteScrollScreen(),
    _SelectPickerScreen(),
    _ImportExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablex Demo'),
        centerTitle: false,
        elevation: 0,
      ),
      body: _screens[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ============================================================================
// Fake data models
// ============================================================================

enum EmployeeStatus { active, inactive, onLeave }

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.salary,
    required this.joinDate,
    required this.status,
    required this.isManager,
    this.avatarInitial = '',
  });

  final int id;
  final String name;
  final String email;
  final String department;
  final double salary;
  final DateTime joinDate;
  final EmployeeStatus status;
  final bool isManager;
  final String avatarInitial;
}

class Country {
  const Country({
    required this.code,
    required this.name,
    required this.region,
    required this.population,
  });

  final String code;
  final String name;
  final String region;
  final int population;
}

// ============================================================================
// Fake data generators
// ============================================================================

const _firstNames = [
  'Alice',
  'Bob',
  'Carol',
  'David',
  'Eva',
  'Frank',
  'Grace',
  'Henry',
  'Iris',
  'Jack',
  'Kate',
  'Leo',
  'Mia',
  'Noah',
  'Olivia',
  'Peter',
  'Quinn',
  'Rachel',
  'Sam',
  'Tina',
  'Uma',
  'Victor',
  'Wendy',
  'Xander',
  'Yara',
  'Zoe',
];
const _lastNames = [
  'Smith',
  'Johnson',
  'Williams',
  'Brown',
  'Jones',
  'Garcia',
  'Miller',
  'Davis',
  'Martinez',
  'Wilson',
  'Anderson',
  'Taylor',
  'Thomas',
  'Hernandez',
  'Moore',
  'Martin',
  'Jackson',
  'Thompson',
  'White',
  'Lopez',
];
const _departments = [
  'Engineering',
  'Design',
  'Marketing',
  'Sales',
  'HR',
  'Finance',
  'Legal',
];

Employee _makeEmployee(int id, Random rng) {
  final first = _firstNames[rng.nextInt(_firstNames.length)];
  final last = _lastNames[rng.nextInt(_lastNames.length)];
  final name = '$first $last';
  return Employee(
    id: id,
    name: name,
    email: '${first.toLowerCase()}.${last.toLowerCase()}@corp.io',
    department: _departments[rng.nextInt(_departments.length)],
    salary: (50000 + rng.nextInt(100000).toDouble()),
    joinDate: DateTime.now().subtract(Duration(days: rng.nextInt(3650))),
    status: EmployeeStatus.values[rng.nextInt(EmployeeStatus.values.length)],
    isManager: rng.nextBool(),
    avatarInitial: first[0],
  );
}

// Stable dataset shared by all fetch functions. 500 rows for infinite scroll,
// paged tabs use a subset or the full list depending on their page size.
List<Employee> _allEmployees = List.generate(
  500,
  (i) => _makeEmployee(i + 1, Random(i * 31)),
);

const _countries = [
  Country(
      code: 'US',
      name: 'United States',
      region: 'Americas',
      population: 331000000),
  Country(code: 'CN', name: 'China', region: 'Asia', population: 1411000000),
  Country(code: 'IN', name: 'India', region: 'Asia', population: 1380000000),
  Country(
      code: 'BR', name: 'Brazil', region: 'Americas', population: 214000000),
  Country(code: 'ID', name: 'Indonesia', region: 'Asia', population: 273000000),
  Country(code: 'PK', name: 'Pakistan', region: 'Asia', population: 220000000),
  Country(code: 'NG', name: 'Nigeria', region: 'Africa', population: 206000000),
  Country(
      code: 'BD', name: 'Bangladesh', region: 'Asia', population: 165000000),
  Country(code: 'RU', name: 'Russia', region: 'Europe', population: 144000000),
  Country(
      code: 'MX', name: 'Mexico', region: 'Americas', population: 128000000),
  Country(
      code: 'ET', name: 'Ethiopia', region: 'Africa', population: 115000000),
  Country(code: 'JP', name: 'Japan', region: 'Asia', population: 126000000),
  Country(
      code: 'PH', name: 'Philippines', region: 'Asia', population: 110000000),
  Country(
      code: 'CD', name: 'D.R. Congo', region: 'Africa', population: 90000000),
  Country(code: 'DE', name: 'Germany', region: 'Europe', population: 83000000),
  Country(code: 'TR', name: 'Turkey', region: 'Europe', population: 84000000),
  Country(
      code: 'GB',
      name: 'United Kingdom',
      region: 'Europe',
      population: 67000000),
  Country(code: 'FR', name: 'France', region: 'Europe', population: 65000000),
  Country(code: 'TZ', name: 'Tanzania', region: 'Africa', population: 60000000),
  Country(
      code: 'ZA', name: 'South Africa', region: 'Africa', population: 59000000),
];

// ============================================================================
// Shared employee columns
// ============================================================================

List<TablexColumnBase<Employee>> _employeeColumns({
  bool showActions = false,
  void Function(Employee)? onEdit,
  void Function(Employee)? onDelete,
}) {
  return [
    TablexColumn<Employee, String>(
      fieldKey: 'id',
      title: 'Id',
      width: 180,
      type: TablexColumnType.id,
      valueGetter: (e) => e.id.toString(),
    ),
    TablexColumn<Employee, String>(
      fieldKey: 'name',
      title: 'Name',
      width: 180,
      valueGetter: (e) => e.name,
      cellRenderer: TablexRenderers.avatarTwoLine(
        secondLine: (e) => e.email,
        avatar: (_) => null,
      ),
    ),
    TablexColumn<Employee, String>(
      fieldKey: 'department',
      title: 'Department',
      width: 130,
      valueGetter: (e) => e.department,
    ),
    TablexColumn<Employee, double>(
      fieldKey: 'salary',
      title: 'Salary',
      width: 130,
      textAlign: TextAlign.end,
      valueGetter: (e) => e.salary,
      cellRenderer: TablexRenderers.currency(symbol: '\$'),
    ),
    TablexColumn<Employee, DateTime>(
      fieldKey: 'joinDate',
      title: 'Joined',
      width: 120,
      valueGetter: (e) => e.joinDate,
      cellRenderer: TablexRenderers.date(),
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
    TablexColumn<Employee, bool>(
      fieldKey: 'isManager',
      title: 'Manager',
      width: 90,
      enableSorting: false,
      valueGetter: (e) => e.isManager,
      cellRenderer: (row, value, context) => Text(
        value ? 'Yes' : 'No',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    if (showActions && onEdit != null && onDelete != null)
      TablexColumn<Employee, dynamic>(
        fieldKey: 'actions',
        title: '',
        width: 90,
        enableSorting: false,
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

// ============================================================================
// Tab 1 — Static grid (20 employees, actions column)
// ============================================================================

class _StaticGridScreen extends StatefulWidget {
  const _StaticGridScreen();

  @override
  State<_StaticGridScreen> createState() => _StaticGridScreenState();
}

class _StaticGridScreenState extends State<_StaticGridScreen> {
  late List<Employee> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _allEmployees.take(20).toList();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final columns = _employeeColumns(
      showActions: true,
      onEdit: (e) => _showSnack('Edit: ${e.name}'),
      onDelete: (e) {
        setState(() => _rows.removeWhere((r) => r.id == e.id));
        _showSnack('Deleted: ${e.name}');
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
                  checkboxTheme: TablexCheckboxTheme(
                checkColor: Colors.white,
                activeColor: Colors.blue,
              )),
              rowBuilder: _employeeRowBuilder,
              density: TablexDensity.comfortable,
              selectionMode: TablexSelectionMode.multiple,
              onRowTap: (e) => _showSnack('Tapped: ${e.name}'),
              onRowDoubleTap: (e) => _showSnack('Double-tap: ${e.name}'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Tab 2 — Lazy paged grid (simulated server fetch)
// ============================================================================

Future<TablexFetchResult<Employee>> _fakePagedFetch(
  TablexQuery query,
) async {
  // Simulate network latency
  await Future<void>.delayed(const Duration(milliseconds: 400));

  var data = List<Employee>.from(_allEmployees);

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
        'joinDate' => a.joinDate.compareTo(b.joinDate),
        _ => 0,
      };
      return asc ? cmp : -cmp;
    });
  }

  final total = data.length;
  final start = (query.page - 1) * query.pageSize;
  final end = (start + query.pageSize).clamp(0, total);
  final page = data.sublist(start, end);

  return TablexFetchResult(
    rows: page,
    totalRows: total,
  );
}

class _LazyPagedGridScreen extends StatelessWidget {
  const _LazyPagedGridScreen();

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
            '200 total employees — fetched page-by-page from a fake server. '
            'Includes pagination footer with page size selector.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Tablex<Employee>.lazyPaged(
              columns: _employeeColumns(),
              fetchTask: _fakePagedFetch,
              rowBuilder: _employeeRowBuilder,
              density: TablexDensity.standard,
              initialPageSize: 13,
              fetchWithSorting: true,
              errorBuilder: (context, error) => Center(
                child: Text(
                  'Error loading data: $error',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              enablePageJump: true,
              loadingBuilder: TablexLoadingBuilder(
                skeletonData:
                    List.generate(13, (i) => _makeEmployee(i + 1, Random(i))),
                builder: (context, table) =>
                    Skeletonizer(enabled: true, child: table),
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

// ============================================================================
// Tab 3 — Infinite scroll
// ============================================================================

Future<TablexFetchResult<Employee>> _fakeInfiniteFetch(
  TablexQuery query,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));

  var data = List<Employee>.from(_allEmployees);

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

class _InfiniteScrollScreen extends StatelessWidget {
  const _InfiniteScrollScreen();

  @override
  Widget build(BuildContext context) {
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
                TablexColumn<Employee, double>(
                  fieldKey: 'salary',
                  title: 'Salary',
                  width: 140,
                  textAlign: TextAlign.end,
                  valueGetter: (e) => e.salary,
                  cellRenderer: TablexRenderers.currency(symbol: '\$'),
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
              rowBuilder: _employeeRowBuilder,
              density: TablexDensity.compact,
              fetchSize: 50,
              loadingBuilder: TablexLoadingBuilder(
                skeletonData:
                    List.generate(20, (i) => _makeEmployee(i + 1, Random(i))),
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

// ============================================================================
// Tab 4 — Select picker (list of countries)
// ============================================================================

class _SelectPickerScreen extends StatefulWidget {
  const _SelectPickerScreen();

  @override
  State<_SelectPickerScreen> createState() => _SelectPickerScreenState();
}

class _SelectPickerScreenState extends State<_SelectPickerScreen> {
  List<Country> _selected = [];

  @override
  Widget build(BuildContext context) {
    final countryColumns = <TablexColumnBase<Country>>[
      TablexColumn<Country, String>(
        fieldKey: 'code',
        title: 'Code',
        width: 70,
        valueGetter: (c) => c.code,
      ),
      TablexColumn<Country, String>(
        fieldKey: 'name',
        title: 'Country',
        width: 180,
        valueGetter: (c) => c.name,
      ),
      TablexColumn<Country, String>(
        fieldKey: 'region',
        title: 'Region',
        width: 110,
        valueGetter: (c) => c.region,
        cellRenderer: TablexRenderers.statusChip(
          colors: {
            'Americas': Colors.blue,
            'Asia': Colors.purple,
            'Europe': Colors.teal,
            'Africa': Colors.orange,
          },
        ),
      ),
      TablexColumn<Country, int>(
        fieldKey: 'population',
        title: 'Population',
        width: 140,
        textAlign: TextAlign.end,
        valueGetter: (c) => c.population,
        formatter: (v) {
          if (v >= 1000000000) {
            return '${(v / 1000000000).toStringAsFixed(1)}B';
          } else if (v >= 1000000) {
            return '${(v / 1000000).toStringAsFixed(0)}M';
          }
          return v.toString();
        },
      ),
    ];

    TablexRow<Country> countryRowBuilder(Country c) => TablexRow(
          data: c,
          key: c.code,
          cells: {
            'code': c.code,
            'name': c.name,
            'region': c.region,
            'population': c.population,
          },
        );

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
              rows: const [..._countries],
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

// ============================================================================
// Tab 5 — Import / Export
// ============================================================================

/// Parses a CSV/Excel row map back into an Employee and wraps it in a
/// [TablexRow]. Column headers match the titles defined in [_employeeColumns].
TablexRow<Employee> _employeeFromImport(Map<String, String> map) {
  final id = int.tryParse(map['Id'] ?? '') ?? 0;
  final name = map['Name'] ?? '';
  final department = map['Department'] ?? '';
  final salary = double.tryParse(map['Salary'] ?? '') ?? 0.0;

  DateTime joinDate = DateTime.now();
  try {
    joinDate = DateTime.parse(map['Joined'] ?? '');
  } catch (_) {}

  EmployeeStatus status = EmployeeStatus.active;
  final statusStr = (map['Status'] ?? '').toLowerCase();
  if (statusStr.contains('inactive')) {
    status = EmployeeStatus.inactive;
  } else if (statusStr.contains('leave')) {
    status = EmployeeStatus.onLeave;
  }

  final isManager = (map['Manager'] ?? 'false').toLowerCase() == 'true';

  final parts = name.split(' ');
  final first = parts.isNotEmpty ? parts.first.toLowerCase() : 'user';
  final last = parts.length > 1 ? parts.last.toLowerCase() : 'unknown';

  return _employeeRowBuilder(Employee(
    id: id,
    name: name,
    email: '$first.$last@corp.io',
    department: department,
    salary: salary,
    joinDate: joinDate,
    status: status,
    isManager: isManager,
    avatarInitial: name.isNotEmpty ? name[0] : '',
  ));
}

class _ImportExportScreen extends StatefulWidget {
  const _ImportExportScreen();

  @override
  State<_ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<_ImportExportScreen> {
  final _controller = TablexController<Employee>();
  late final List<Employee> _initialRows = _allEmployees.take(50).toList();
  late final _columns = _employeeColumns();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.replaceRows(_initialRows, rowBuilder: _employeeRowBuilder);
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
            '${_controller.rowCount} rows — use the toolbar to export or '
            'import CSV / Excel, or toggle column visibility.',
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
                    rowBuilder: _employeeRowBuilder,
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
