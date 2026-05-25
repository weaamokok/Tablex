import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tablex/tablex.dart';

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

class _Item {
  const _Item(this.id, this.name);
  final int id;
  final String name;
  @override
  bool operator ==(Object other) => other is _Item && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

const _alice = _Item(1, 'Alice');
const _bob = _Item(2, 'Bob');
const _carol = _Item(3, 'Carol');

final _cols = <TablexColumnBase<_Item>>[
  TablexColumn<_Item, int>(
      fieldKey: 'id', title: 'ID', valueGetter: (i) => i.id),
  TablexColumn<_Item, String>(
      fieldKey: 'name', title: 'Name', valueGetter: (i) => i.name),
];

TablexRow<_Item> _row(_Item item) =>
    TablexRow<_Item>(data: item, cells: {'id': item.id, 'name': item.name});

/// Wraps [widget] in a standard test harness with a bounded 800×600 surface.
Widget _harness(Widget widget) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 800, height: 600, child: widget)),
    );

/// Builds a [Tablex.static] with sensible defaults for selection tests.
Widget _table({
  List<_Item> rows = const [_alice, _bob, _carol],
  TablexSelectionMode mode = TablexSelectionMode.multiple,
  TablexController<_Item>? controller,
  bool showSelectionSummary = false,
  List<TablexSelectionAction<_Item>>? selectionActions,
  TablexSelectionSummaryBuilder<_Item>? selectionSummaryBuilder,
  void Function(List<_Item>)? onSelectionChanged,
}) =>
    _harness(Tablex.static(
      columns: _cols,
      rows: rows,
      rowBuilder: _row,
      controller: controller,
      selectionMode: mode,
      showSelectionSummary: showSelectionSummary,
      selectionActions: selectionActions,
      selectionSummaryBuilder: selectionSummaryBuilder,
      onSelectionChanged: onSelectionChanged,
    ));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Taps the [GestureDetector] that is the closest ancestor of [cbFinder].
/// Use this instead of tapping the [Checkbox] directly because the Checkbox is
/// wrapped in [IgnorePointer] — tapping its bounds hits the GestureDetector
/// above, not the Checkbox widget itself.
Future<void> _tapCheckbox(
    WidgetTester tester, Finder cbFinder) async {
  final gd = find
      .ancestor(of: cbFinder, matching: find.byType(GestureDetector))
      .first;
  await tester.tap(gd);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  group('checkbox visibility', () {
    testWidgets('no checkboxes in TablexSelectionMode.none', (tester) async {
      await tester.pumpWidget(_table(mode: TablexSelectionMode.none));
      await tester.pump();
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('no checkboxes in TablexSelectionMode.single', (tester) async {
      await tester.pumpWidget(_table(mode: TablexSelectionMode.single));
      await tester.pump();
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('checkboxes present in TablexSelectionMode.multiple',
        (tester) async {
      // 3 rows + 1 header checkbox = 4 total
      await tester.pumpWidget(_table());
      await tester.pump();
      expect(find.byType(Checkbox), findsNWidgets(4));
    });

    testWidgets('header checkbox is tristate, row checkboxes are not',
        (tester) async {
      await tester.pumpWidget(_table());
      await tester.pump();

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      final tristateList = checkboxes.map((c) => c.tristate).toList();
      // exactly one tristate checkbox (the header)
      expect(tristateList.where((t) => t).length, 1);
      // the remaining three are regular (not tristate)
      expect(tristateList.where((t) => !t).length, 3);
    });
  });

  // =========================================================================
  group('header checkbox — tri-state logic', () {
    testWidgets('header checkbox is unchecked when nothing selected',
        (tester) async {
      await tester.pumpWidget(_table());
      await tester.pump();

      final header = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .first; // first = header (rendered before rows)
      expect(header.value, false);
    });

    testWidgets(
        'header checkbox is indeterminate (null) when some rows selected',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(controller: ctrl));
      await tester.pump();

      ctrl.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      final header = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .first;
      expect(header.value, isNull); // indeterminate
    });

    testWidgets('header checkbox is checked when all rows selected',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(controller: ctrl));
      await tester.pump();

      ctrl.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      ctrl.selectAll(ctrl.getAllRowData());
      await tester.pump();

      final header = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .first;
      expect(header.value, true);
    });

    testWidgets(
        'tapping header checkbox when nothing selected calls selectAll',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(controller: ctrl));
      await tester.pump();

      await _tapCheckbox(tester, find.byType(Checkbox).first);
      await tester.pump();

      expect(ctrl.selectedRows.length, 3);
      expect(ctrl.isSelected(_alice), true);
      expect(ctrl.isSelected(_bob), true);
      expect(ctrl.isSelected(_carol), true);
    });

    testWidgets(
        'tapping header checkbox when all selected calls deselectAll',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(controller: ctrl));
      await tester.pump();

      ctrl.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      ctrl.selectAll(ctrl.getAllRowData());
      await tester.pump();

      await _tapCheckbox(tester, find.byType(Checkbox).first);
      await tester.pump();

      expect(ctrl.selectedRows, isEmpty);
    });
  });

  // =========================================================================
  group('row checkbox interaction', () {
    testWidgets('tapping row checkbox toggles selection', (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(controller: ctrl));
      await tester.pump();

      // Second Checkbox = first row's checkbox (header is index 0)
      final firstRowCb = find.byType(Checkbox).at(1);
      expect(ctrl.selectedRows, isEmpty);

      await _tapCheckbox(tester, firstRowCb);
      await tester.pump();
      expect(ctrl.selectedRows.length, 1);

      await _tapCheckbox(tester, firstRowCb);
      await tester.pump();
      expect(ctrl.selectedRows, isEmpty);
    });

    testWidgets('tapping two row checkboxes accumulates selection',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(controller: ctrl));
      await tester.pump();

      await _tapCheckbox(tester, find.byType(Checkbox).at(1)); // row 0
      await tester.pump();
      await _tapCheckbox(tester, find.byType(Checkbox).at(2)); // row 1
      await tester.pump();

      expect(ctrl.selectedRows.length, 2);
    });

    testWidgets('row checkbox selection fires onSelectionChanged',
        (tester) async {
      List<_Item>? received;
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        onSelectionChanged: (sel) => received = sel,
      ));
      await tester.pump();

      await _tapCheckbox(tester, find.byType(Checkbox).at(1));
      await tester.pump();

      expect(received, isNotNull);
      expect(received!.length, 1);
    });
  });

  // =========================================================================
  group('row tap behavior', () {
    testWidgets(
        'in single mode: tapping a row selects it via onSelectionChanged',
        (tester) async {
      List<_Item>? received;
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.single;
      await tester.pumpWidget(_table(
        mode: TablexSelectionMode.single,
        controller: ctrl,
        onSelectionChanged: (sel) => received = sel,
      ));
      await tester.pump();

      // Tap the first data row (find by cell text)
      await tester.tap(find.text('Alice'));
      await tester.pump();

      expect(ctrl.selectedRows.length, 1);
      expect(received, isNotNull);
    });

    testWidgets(
        'in multiple mode: tapping a row does NOT toggle selection',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(controller: ctrl));
      await tester.pump();

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      // Only checkbox should select; row tap should be a no-op for selection
      expect(ctrl.selectedRows, isEmpty);
    });
  });

  // =========================================================================
  group('selection summary bar', () {
    testWidgets('summary NOT shown when showSelectionSummary is false',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: false,
      ));
      await tester.pump();

      ctrl.replaceRows([_alice, _bob], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      // Column headers still visible, no selection count text
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('summary NOT shown when no rows are selected', (tester) async {
      await tester.pumpWidget(_table(showSelectionSummary: true));
      await tester.pump();

      // Nothing selected → header row should be visible
      expect(find.text('ID'), findsOneWidget);
      expect(find.textContaining('selected'), findsNothing);
    });

    testWidgets(
        'summary appears when showSelectionSummary: true and rows selected',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
      ));
      await tester.pump();

      ctrl.replaceRows([_alice, _bob], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      expect(find.text('1 selected'), findsOneWidget);
      // Column headers are replaced by the summary bar
      expect(find.text('ID'), findsNothing);
    });

    testWidgets('summary shows correct count for multiple selections',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
      ));
      await tester.pump();

      ctrl.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      ctrl.selectAll(ctrl.getAllRowData());
      await tester.pump();

      expect(find.text('3 selected'), findsOneWidget);
    });

    testWidgets('clear button in summary calls clearSelection', (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
      ));
      await tester.pump();

      ctrl.replaceRows([_alice], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      // Tap the close/clear icon button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(ctrl.selectedRows, isEmpty);
    });

    testWidgets(
        'header row returns after selection is cleared',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
      ));
      await tester.pump();

      ctrl.replaceRows([_alice], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      // Summary showing
      expect(find.text('1 selected'), findsOneWidget);

      ctrl.clearSelection();
      await tester.pump();

      // Column headers back
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('action buttons are rendered and fire with selected rows',
        (tester) async {
      List<_Item>? pressed;
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
        selectionActions: [
          TablexSelectionAction<_Item>(
            label: 'Delete',
            icon: Icons.delete_outline,
            onPressed: (rows) => pressed = rows,
          ),
        ],
      ));
      await tester.pump();

      ctrl.replaceRows([_alice, _bob], rowBuilder: _row);
      ctrl.selectRow(_alice);
      ctrl.selectRow(_bob);
      await tester.pump();

      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(pressed, isNotNull);
      expect(pressed!.length, 2);
      expect(pressed, containsAll([_alice, _bob]));
    });
  });

  // =========================================================================
  group('selection summary builder override', () {
    testWidgets('custom builder widget is shown instead of default',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
        selectionSummaryBuilder: (ctx, rows, clear) =>
            const Text('CUSTOM_SUMMARY'),
      ));
      await tester.pump();

      ctrl.replaceRows([_alice], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      expect(find.text('CUSTOM_SUMMARY'), findsOneWidget);
    });

    testWidgets('default summary NOT shown when builder is provided',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
        selectionSummaryBuilder: (ctx, rows, clear) =>
            const Text('CUSTOM_SUMMARY'),
      ));
      await tester.pump();

      ctrl.replaceRows([_alice], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      // The default "N selected" text should NOT be present
      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('builder receives correct selectedRows', (tester) async {
      List<_Item>? builderRows;
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
        selectionSummaryBuilder: (ctx, rows, clear) {
          builderRows = rows;
          return Text('${rows.length} custom');
        },
      ));
      await tester.pump();

      ctrl.replaceRows([_alice, _bob], rowBuilder: _row);
      ctrl.selectRow(_alice);
      ctrl.selectRow(_bob);
      await tester.pump();

      expect(builderRows, isNotNull);
      expect(builderRows!.length, 2);
      expect(builderRows, containsAll([_alice, _bob]));
    });

    testWidgets('builder receives a working clearSelection callback',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
        selectionSummaryBuilder: (ctx, rows, clear) =>
            ElevatedButton(onPressed: clear, child: const Text('CLEAR')),
      ));
      await tester.pump();

      ctrl.replaceRows([_alice], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      expect(ctrl.selectedRows.length, 1);
      await tester.tap(find.text('CLEAR'));
      await tester.pump();
      expect(ctrl.selectedRows, isEmpty);
    });

    testWidgets(
        'selectionActions are ignored when builder is provided',
        (tester) async {
      bool actionFired = false;
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
        selectionActions: [
          TablexSelectionAction<_Item>(
            label: 'ShouldNotAppear',
            icon: Icons.delete,
            onPressed: (_) => actionFired = true,
          ),
        ],
        selectionSummaryBuilder: (ctx, rows, clear) =>
            const Text('CUSTOM_SUMMARY'),
      ));
      await tester.pump();

      ctrl.replaceRows([_alice], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      // The action label should not appear anywhere
      expect(find.text('ShouldNotAppear'), findsNothing);
      expect(actionFired, false);
    });
  });

  // =========================================================================
  group('layout — width stability', () {
    testWidgets(
        'table width is the same before and after selection summary appears',
        (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(_table(
        controller: ctrl,
        showSelectionSummary: true,
      ));
      await tester.pump();

      // Measure the Tablex widget before any selection
      final beforeSize = tester.getSize(find.byType(Tablex<_Item>));

      ctrl.replaceRows([_alice, _bob], rowBuilder: _row);
      ctrl.selectRow(_alice);
      await tester.pump();

      // Measure after selection summary replaces the header
      final afterSize = tester.getSize(find.byType(Tablex<_Item>));

      expect(afterSize.width, beforeSize.width);
    });
  });

  // =========================================================================
  group('i18n strings', () {
    testWidgets('English selected(n) formats correctly', (tester) async {
      final ctrl = TablexController<_Item>()
        ..selectionMode = TablexSelectionMode.multiple;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: Tablex.static(
              columns: _cols,
              rows: [_alice, _bob, _carol],
              rowBuilder: _row,
              controller: ctrl,
              selectionMode: TablexSelectionMode.multiple,
              showSelectionSummary: true,
            ),
          ),
        ),
      ));
      await tester.pump();

      ctrl.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      ctrl.selectRow(_alice);
      ctrl.selectRow(_bob);
      await tester.pump();

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('noData string shown when rows list is empty', (tester) async {
      await tester.pumpWidget(_harness(Tablex<_Item>.static(
        columns: _cols,
        rows: const [],
        rowBuilder: _row,
      )));
      await tester.pump();
      expect(find.text('No data'), findsOneWidget);
    });

    testWidgets('custom noDataWidget overrides default', (tester) async {
      await tester.pumpWidget(_harness(Tablex<_Item>.static(
        columns: _cols,
        rows: const [],
        rowBuilder: _row,
        noDataWidget: const Text('Nothing here'),
      )));
      await tester.pump();
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('No data'), findsNothing);
    });
  });
}
