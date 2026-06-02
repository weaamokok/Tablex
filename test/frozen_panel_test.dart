import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tablex/tablex.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

class _Employee {
  const _Employee(this.id, this.name, this.department);
  final int id;
  final String name;
  final String department;
}

const _e1 = _Employee(1, 'Alice', 'Engineering');
const _e2 = _Employee(2, 'Bob', 'Design');
const _e3 = _Employee(3, 'Carol', 'Marketing');

final _items = [_e1, _e2, _e3];

TablexRow<_Employee> _row(_Employee e) => TablexRow<_Employee>(
      data: e,
      key: '${e.id}',
      cells: {'id': e.id, 'name': e.name, 'dept': e.department},
    );

// Columns: id (frozen-start), name (scrollable), dept (frozen-end)
final _colId = TablexColumn<_Employee, int>(
  fieldKey: 'id',
  title: 'ID',
  valueGetter: (e) => e.id,
  frozen: TablexColumnFrozen.start,
  width: 60,
);
final _colName = TablexColumn<_Employee, String>(
  fieldKey: 'name',
  title: 'Name',
  valueGetter: (e) => e.name,
  width: 200,
);
final _colDept = TablexColumn<_Employee, String>(
  fieldKey: 'dept',
  title: 'Dept',
  valueGetter: (e) => e.department,
  frozen: TablexColumnFrozen.end,
  width: 120,
);

// All three columns, none frozen — baseline for comparison
final _colsNoFreeze = <TablexColumnBase<_Employee>>[
  TablexColumn<_Employee, int>(
    fieldKey: 'id',
    title: 'ID',
    valueGetter: (e) => e.id,
    width: 60,
  ),
  TablexColumn<_Employee, String>(
    fieldKey: 'name',
    title: 'Name',
    valueGetter: (e) => e.name,
    width: 200,
  ),
  TablexColumn<_Employee, String>(
    fieldKey: 'dept',
    title: 'Dept',
    valueGetter: (e) => e.department,
    width: 120,
  ),
];

final _colsWithFreeze = [_colId, _colName, _colDept];

Widget _harness(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 800, height: 600, child: child),
      ),
    );

Widget _staticTable(List<TablexColumnBase<_Employee>> cols) =>
    Tablex<_Employee>.static(
      columns: cols,
      rows: _items,
      rowBuilder: _row,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('frozen columns — panel presence', () {
    testWidgets('frozen-start header title appears in DOM', (tester) async {
      await tester.pumpWidget(_harness(_staticTable(_colsWithFreeze)));
      await tester.pumpAndSettle();

      // 'ID' appears in the frozen panel header
      expect(find.text('ID'), findsWidgets);
    });

    testWidgets('frozen-end header title appears in DOM', (tester) async {
      await tester.pumpWidget(_harness(_staticTable(_colsWithFreeze)));
      await tester.pumpAndSettle();

      expect(find.text('Dept'), findsWidgets);
    });

    testWidgets('scrollable column header still appears', (tester) async {
      await tester.pumpWidget(_harness(_staticTable(_colsWithFreeze)));
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('all three header titles appear with frozen columns',
        (tester) async {
      await tester.pumpWidget(_harness(_staticTable(_colsWithFreeze)));
      await tester.pumpAndSettle();

      expect(find.text('ID'), findsWidgets);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Dept'), findsWidgets);
    });
  });

  group('frozen columns — cell data rendered', () {
    testWidgets('frozen-start cell values appear for each row', (tester) async {
      await tester.pumpWidget(_harness(_staticTable(_colsWithFreeze)));
      await tester.pumpAndSettle();

      // IDs from frozen-start panel
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('frozen-end cell values appear for each row', (tester) async {
      await tester.pumpWidget(_harness(_staticTable(_colsWithFreeze)));
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsWidgets);
      expect(find.text('Design'), findsWidgets);
      expect(find.text('Marketing'), findsWidgets);
    });

    testWidgets('scrollable cell values appear for each row', (tester) async {
      await tester.pumpWidget(_harness(_staticTable(_colsWithFreeze)));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
    });
  });

  group('frozen columns — no frozen columns keeps original behavior', () {
    testWidgets('all headers and cells render without frozen columns',
        (tester) async {
      await tester.pumpWidget(_harness(_staticTable(_colsNoFreeze)));
      await tester.pumpAndSettle();

      expect(find.text('ID'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Dept'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });
  });

  group('frozen columns — only frozen-start, no frozen-end', () {
    testWidgets('only start panel appears, end side is clean', (tester) async {
      final cols = [_colId, _colName];
      await tester.pumpWidget(_harness(_staticTable(cols)));
      await tester.pumpAndSettle();

      expect(find.text('ID'), findsWidgets);
      expect(find.text('Name'), findsOneWidget);
    });
  });

  group('frozen columns — only frozen-end, no frozen-start', () {
    testWidgets('only end panel appears', (tester) async {
      final cols = [_colName, _colDept];
      await tester.pumpWidget(_harness(_staticTable(cols)));
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Dept'), findsWidgets);
    });
  });

  group('frozen columns — sort from frozen header', () {
    testWidgets('tapping frozen-start column header triggers sort',
        (tester) async {
      final ctrl = TablexController<_Employee>();
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(
        _harness(
          Tablex<_Employee>.static(
            columns: _colsWithFreeze,
            rows: _items,
            rowBuilder: _row,
            controller: ctrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The ID header appears twice (frozen panel + possible extra). Tap the
      // first 'ID' text — it is inside the frozen panel.
      final idHeaders = find.text('ID');
      expect(idHeaders, findsWidgets);
      await tester.tap(idHeaders.first);
      await tester.pumpAndSettle();

      // After tapping, the controller should have a sort set.
      expect(ctrl.state.query.sort, isNotNull);
      expect(ctrl.state.query.sort!.field, 'id');
    });
  });

  group('frozen columns — hidden frozen column collapses panel', () {
    testWidgets('panel returns empty when all its columns are hidden',
        (tester) async {
      // Start with just the frozen-start column but mark it hidden
      final hiddenFrozen = TablexColumn<_Employee, int>(
        fieldKey: 'id',
        title: 'ID',
        valueGetter: (e) => e.id,
        frozen: TablexColumnFrozen.start,
        hide: true,
        width: 60,
      );
      final cols = [hiddenFrozen, _colName];
      await tester.pumpWidget(_harness(_staticTable(cols)));
      await tester.pumpAndSettle();

      // 'ID' header should not appear (column is hidden)
      expect(find.text('ID'), findsNothing);
      // Scrollable column still renders
      expect(find.text('Name'), findsOneWidget);
    });
  });

  group('frozen columns — RTL locale', () {
    testWidgets('frozen columns render in RTL without errors', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: _staticTable(_colsWithFreeze),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All headers still present in RTL
      expect(find.text('ID'), findsWidgets);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Dept'), findsWidgets);
    });
  });
}
