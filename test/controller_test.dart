import 'package:flutter_test/flutter_test.dart';
import 'package:tablex/tablex.dart';

// ---------------------------------------------------------------------------
// Shared test fixtures
// ---------------------------------------------------------------------------

class _Item {
  const _Item(this.id, this.name);
  final int id;
  final String name;

  @override
  bool operator ==(Object other) => other is _Item && other.id == id;
  @override
  int get hashCode => id.hashCode;
  @override
  String toString() => '_Item($id, $name)';
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

TablexController<_Item> _ctrl({
  TablexSelectionMode mode = TablexSelectionMode.none,
}) {
  final c = TablexController<_Item>();
  c.selectionMode = mode;
  return c;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  group('row management', () {
    test('replaceRows stores rows in order', () {
      final c = _ctrl();
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      expect(c.rowCount, 2);
      expect(c.getAllRowData(), [_alice, _bob]);
    });

    test('replaceRows clears previous rows', () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row);
      c.replaceRows([_bob, _carol], rowBuilder: _row);
      expect(c.rowCount, 2);
      expect(c.getAllRowData(), [_bob, _carol]);
    });

    test('replaceRows clears selection by default', () {
      final c = _ctrl(mode: TablexSelectionMode.multiple);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      c.selectRow(_alice);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      expect(c.selectedRows, isEmpty);
    });

    test('replaceRows preserves selection when clearSelection: false', () {
      final c = _ctrl(mode: TablexSelectionMode.multiple);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      c.selectRow(_alice);
      c.replaceRows([_alice, _bob],
          rowBuilder: _row, clearSelection: false);
      expect(c.selectedRows, [_alice]);
    });

    test('replaceRows marks initialized by default', () {
      final c = _ctrl();
      expect(c.state.isInitialized, false);
      c.replaceRows([_alice], rowBuilder: _row);
      expect(c.state.isInitialized, true);
    });

    test('replaceRows with markInitialized: false does not mark initialized',
        () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row, markInitialized: false);
      expect(c.state.isInitialized, false);
    });

    test('appendRows adds to existing rows', () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row);
      c.appendRows([_bob, _carol], rowBuilder: _row);
      expect(c.rowCount, 3);
      expect(c.getAllRowData(), [_alice, _bob, _carol]);
    });

    test('updateRow replaces data at index', () {
      final c = _ctrl();
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      c.updateRow(0, _carol, rowBuilder: _row);
      expect(c.getAllRowData().first, _carol);
      expect(c.getAllRowData()[1], _bob);
    });

    test('updateRow out of bounds throws RangeError', () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row);
      expect(() => c.updateRow(5, _bob, rowBuilder: _row),
          throwsRangeError);
    });

    test('removeRow removes at index', () {
      final c = _ctrl();
      c.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      c.removeRow(1);
      expect(c.rowCount, 2);
      expect(c.getAllRowData(), [_alice, _carol]);
    });

    test('removeRow out of bounds throws RangeError', () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row);
      expect(() => c.removeRow(99), throwsRangeError);
    });

    test('removeRowsByKey removes matching rows', () {
      final c = _ctrl();
      c.replaceRows(
        [_alice, _bob],
        rowBuilder: (i) => TablexRow<_Item>(
          data: i, cells: {'id': i.id, 'name': i.name}, key: 'key_${i.id}',
        ),
      );
      c.removeRowsByKey(['key_1']);
      expect(c.rowCount, 1);
      expect(c.getAllRowData(), [_bob]);
    });

    test('clearRows empties and marks uninitialized', () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row);
      c.clearRows();
      expect(c.rowCount, 0);
      expect(c.state.isInitialized, false);
    });

    test('getRowAt returns correct row', () {
      final c = _ctrl();
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      expect(c.getRowAt(0)?.data, _alice);
      expect(c.getRowAt(1)?.data, _bob);
    });

    test('getRowAt out of range returns null', () {
      final c = _ctrl();
      expect(c.getRowAt(0), isNull);
    });
  });

  // =========================================================================
  group('selection', () {
    test('selectRow in none mode is a no-op', () {
      final c = _ctrl(mode: TablexSelectionMode.none);
      c.replaceRows([_alice], rowBuilder: _row);
      c.selectRow(_alice);
      expect(c.selectedRows, isEmpty);
    });

    test('selectRow in single mode replaces previous selection', () {
      final c = _ctrl(mode: TablexSelectionMode.single);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      c.selectRow(_alice);
      expect(c.selectedRows, [_alice]);
      c.selectRow(_bob);
      expect(c.selectedRows, [_bob]);
      expect(c.selectedRows.length, 1);
    });

    test('selectRow in multiple mode accumulates', () {
      final c = _ctrl(mode: TablexSelectionMode.multiple);
      c.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      c.selectRow(_alice);
      c.selectRow(_carol);
      expect(c.selectedRows, containsAll([_alice, _carol]));
      expect(c.selectedRows.length, 2);
    });

    test('selectRow duplicate in multiple mode is a no-op', () {
      int notifications = 0;
      final c = _ctrl(mode: TablexSelectionMode.multiple)
        ..addListener(() => notifications++);
      c.replaceRows([_alice], rowBuilder: _row);
      notifications = 0;
      c.selectRow(_alice);
      expect(notifications, 1);
      c.selectRow(_alice); // already selected
      expect(notifications, 1); // no extra notification
    });

    test('deselectRow removes from selection', () {
      final c = _ctrl(mode: TablexSelectionMode.multiple);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      c.selectRow(_alice);
      c.selectRow(_bob);
      c.deselectRow(_alice);
      expect(c.selectedRows, [_bob]);
    });

    test('deselectRow when not selected is a no-op', () {
      int notifications = 0;
      final c = _ctrl(mode: TablexSelectionMode.multiple)
        ..addListener(() => notifications++);
      c.replaceRows([_alice], rowBuilder: _row);
      notifications = 0;
      c.deselectRow(_alice); // not selected
      expect(notifications, 0);
    });

    test('toggleRowSelection selects then deselects', () {
      final c = _ctrl(mode: TablexSelectionMode.multiple);
      c.replaceRows([_alice], rowBuilder: _row);
      expect(c.isSelected(_alice), false);
      c.toggleRowSelection(_alice);
      expect(c.isSelected(_alice), true);
      c.toggleRowSelection(_alice);
      expect(c.isSelected(_alice), false);
    });

    test('setSelection replaces entire selection', () {
      final c = _ctrl(mode: TablexSelectionMode.multiple);
      c.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      c.selectRow(_alice);
      c.setSelection([_bob, _carol]);
      expect(c.selectedRows, containsAll([_bob, _carol]));
      expect(c.isSelected(_alice), false);
    });

    test('clearSelection empties the selection', () {
      final c = _ctrl(mode: TablexSelectionMode.multiple);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      c.selectRow(_alice);
      c.selectRow(_bob);
      c.clearSelection();
      expect(c.selectedRows, isEmpty);
    });

    test('clearSelection on empty selection is a no-op (no notification)', () {
      int notifications = 0;
      final c = _ctrl(mode: TablexSelectionMode.multiple)
        ..addListener(() => notifications++);
      c.replaceRows([_alice], rowBuilder: _row);
      notifications = 0;
      c.clearSelection(); // nothing selected
      expect(notifications, 0);
    });

    test('selectAll in multiple mode selects all items', () {
      final c = _ctrl(mode: TablexSelectionMode.multiple);
      c.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      c.selectAll(c.getAllRowData());
      expect(c.selectedRows.length, 3);
      expect(c.isSelected(_alice), true);
      expect(c.isSelected(_bob), true);
      expect(c.isSelected(_carol), true);
    });

    test('selectAll in single mode is a no-op', () {
      final c = _ctrl(mode: TablexSelectionMode.single);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      c.selectAll(c.getAllRowData());
      expect(c.selectedRows, isEmpty);
    });

    test('isSelected returns correct value', () {
      final c = _ctrl(mode: TablexSelectionMode.multiple);
      c.replaceRows([_alice], rowBuilder: _row);
      expect(c.isSelected(_alice), false);
      c.selectRow(_alice);
      expect(c.isSelected(_alice), true);
    });
  });

  // =========================================================================
  group('query management', () {
    test('goToPage updates page number', () {
      final c = _ctrl();
      c.goToPage(5);
      expect(c.state.query.page, 5);
    });

    test('goToPage same page is a no-op', () {
      int notifications = 0;
      final c = _ctrl()..addListener(() => notifications++);
      c.goToPage(1); // already on page 1
      expect(notifications, 0);
    });

    test('nextPage increments page', () {
      final c = _ctrl();
      expect(c.state.query.page, 1);
      c.nextPage();
      expect(c.state.query.page, 2);
    });

    test('previousPage decrements page', () {
      final c = _ctrl();
      c.goToPage(3);
      c.previousPage();
      expect(c.state.query.page, 2);
    });

    test('previousPage at page 1 is a no-op', () {
      int notifications = 0;
      final c = _ctrl()..addListener(() => notifications++);
      notifications = 0;
      c.previousPage();
      expect(notifications, 0);
      expect(c.state.query.page, 1);
    });

    test('setSort updates sort and resets to page 1', () {
      final c = _ctrl();
      c.goToPage(3);
      const sort = TablexColumnSort(
          field: 'name', direction: TablexSortDirection.ascending);
      c.setSort(sort);
      expect(c.state.query.sort, sort);
      expect(c.state.query.page, 1);
    });

    test('setSort null clears sort', () {
      final c = _ctrl();
      c.setSort(const TablexColumnSort(
          field: 'name', direction: TablexSortDirection.ascending));
      c.setSort(null);
      expect(c.state.query.sort, isNull);
    });

    test('setFilters updates filters', () {
      final c = _ctrl();
      final filters = [
        const TablexColumnFilter(
          field: 'name',
          operator: TablexFilterOperator.contains,
          value: 'Ali',
        ),
      ];
      c.setFilters(filters);
      expect(c.state.query.filters, filters);
    });

    test('setPageSize updates size and resets to page 1', () {
      final c = _ctrl();
      c.goToPage(4);
      c.setPageSize(50);
      expect(c.state.query.pageSize, 50);
      expect(c.state.query.page, 1);
    });

    test('setParam stores value and resets page', () {
      final c = _ctrl();
      c.goToPage(3);
      c.setParam('status', 'active');
      expect(c.state.query.params['status'], 'active');
      expect(c.state.query.page, 1);
    });

    test('removeParam removes key', () {
      final c = _ctrl();
      c.setParam('status', 'active');
      c.removeParam('status');
      expect(c.state.query.params.containsKey('status'), false);
    });

    test('clearParams removes all params', () {
      final c = _ctrl();
      c.setParam('a', 1);
      c.setParam('b', 2);
      c.clearParams();
      expect(c.state.query.params, isEmpty);
    });
  });

  // =========================================================================
  group('column management', () {
    test('setColumnHidden hides a column', () {
      final c = _ctrl();
      c.setColumnHidden('name', true);
      expect(c.isColumnHidden('name'), true);
    });

    test('setColumnHidden reveals a column', () {
      final c = _ctrl();
      c.setColumnHidden('name', true);
      c.setColumnHidden('name', false);
      expect(c.isColumnHidden('name'), false);
    });

    test('setColumnHidden same state is a no-op', () {
      int notifications = 0;
      final c = _ctrl()..addListener(() => notifications++);
      notifications = 0;
      c.setColumnHidden('name', false); // already visible
      expect(notifications, 0);
    });

    test('toggleColumnHidden flips visibility', () {
      final c = _ctrl();
      c.toggleColumnHidden('name');
      expect(c.isColumnHidden('name'), true);
      c.toggleColumnHidden('name');
      expect(c.isColumnHidden('name'), false);
    });

    test('setColumnWidth stores width', () {
      final c = _ctrl();
      c.setColumnWidth('name', 250.0);
      expect(c.state.columnWidths['name'], 250.0);
    });

    test('resetColumnWidths clears all widths', () {
      final c = _ctrl();
      c.setColumnWidth('name', 250.0);
      c.setColumnWidth('id', 80.0);
      c.resetColumnWidths();
      expect(c.state.columnWidths, isEmpty);
    });

    test('resetColumnWidths when already empty is a no-op', () {
      int notifications = 0;
      final c = _ctrl()..addListener(() => notifications++);
      notifications = 0;
      c.resetColumnWidths();
      expect(notifications, 0);
    });

    test('setColumnOrder stores order', () {
      final c = _ctrl();
      c.setColumnOrder(['name', 'id']);
      expect(c.state.columnOrder, ['name', 'id']);
    });

    test('resetColumnOrder clears order', () {
      final c = _ctrl();
      c.setColumnOrder(['name', 'id']);
      c.resetColumnOrder();
      expect(c.state.columnOrder, isEmpty);
    });

    test('reorderColumn moves field to new index', () {
      final c = _ctrl();
      c.setColumnOrder(['a', 'b', 'c', 'd']);
      c.reorderColumn('a', 2);
      expect(c.state.columnOrder, ['b', 'c', 'a', 'd']);
    });
  });

  // =========================================================================
  group('inline editing', () {
    test('beginEdit sets editing state', () {
      final c = _ctrl();
      c.beginEdit(2, 'name');
      expect(c.editingRowIndex, 2);
      expect(c.editingField, 'name');
    });

    test('confirmEdit clears editing state', () {
      final c = _ctrl();
      c.beginEdit(2, 'name');
      c.confirmEdit(2, 'name');
      expect(c.editingRowIndex, isNull);
      expect(c.editingField, isNull);
    });

    test('cancelEdit clears editing state', () {
      final c = _ctrl();
      c.beginEdit(0, 'id');
      c.cancelEdit();
      expect(c.editingRowIndex, isNull);
      expect(c.editingField, isNull);
    });
  });

  // =========================================================================
  group('CSV export', () {
    test('produces header row from column titles', () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row);
      final csv = c.exportToCsv(_cols);
      expect(csv.split('\n').first.trim(), 'ID,Name');
    });

    test('produces correct data rows', () {
      final c = _ctrl();
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      final lines = c.exportToCsv(_cols).trim().split('\n');
      expect(lines[1], '1,Alice');
      expect(lines[2], '2,Bob');
    });

    test('sanitises formula-starting characters (= + - @)', () {
      final c = _ctrl();
      c.replaceRows([
        const _Item(1, '=SUM(A1)'),
        const _Item(2, '+evil'),
        const _Item(3, '-1+1'),
        const _Item(4, '@cmd'),
      ], rowBuilder: _row);
      final csv = c.exportToCsv(_cols);
      // Injection-prevention prefix is a tab, wrapped in quotes.
      expect(csv, contains('"\t=SUM(A1)"'));
      expect(csv, contains('"\t+evil"'));
      expect(csv, contains('"\t-1+1"'));
      expect(csv, contains('"\t@cmd"'));
    });

    test('quotes cells containing commas', () {
      final c = _ctrl();
      c.replaceRows([const _Item(1, 'Smith, John')], rowBuilder: _row);
      expect(c.exportToCsv(_cols), contains('"Smith, John"'));
    });

    test('quotes cells containing double quotes and escapes them', () {
      final c = _ctrl();
      c.replaceRows([const _Item(1, 'say "hi"')], rowBuilder: _row);
      expect(c.exportToCsv(_cols), contains('"say ""hi"""'));
    });

    test('excludes hidden columns', () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row);
      c.setColumnHidden('name', true);
      final csv = c.exportToCsv(_cols);
      expect(csv, isNot(contains('Name')));
      expect(csv, isNot(contains('Alice')));
      expect(csv, contains('ID'));
    });
  });

  // =========================================================================
  group('loading and error state', () {
    test('setLoading updates isLoading', () {
      final c = _ctrl();
      expect(c.state.isLoading, false);
      c.setLoading(true);
      expect(c.state.isLoading, true);
      c.setLoading(false);
      expect(c.state.isLoading, false);
    });

    test('setLoading same value is a no-op', () {
      int notifications = 0;
      final c = _ctrl()..addListener(() => notifications++);
      notifications = 0;
      c.setLoading(false); // already false
      expect(notifications, 0);
    });

    test('setError stores error', () {
      final c = _ctrl();
      final err = Exception('oops');
      c.setError(err);
      expect(c.state.error, err);
    });

    test('setError null clears error', () {
      final c = _ctrl();
      c.setError(Exception('oops'));
      c.setError(null);
      expect(c.state.error, isNull);
    });
  });

  // =========================================================================
  group('lifecycle and notifications', () {
    test('dispose prevents further method calls', () {
      final c = _ctrl();
      c.dispose();
      expect(() => c.replaceRows([_alice], rowBuilder: _row),
          throwsStateError);
      expect(() => c.selectRow(_alice), throwsStateError);
      expect(() => c.goToPage(2), throwsStateError);
    });

    test('refresh increments refreshSignal', () {
      final c = _ctrl();
      expect(c.refreshSignal.value, 0);
      c.refresh();
      expect(c.refreshSignal.value, 1);
      c.refresh();
      expect(c.refreshSignal.value, 2);
    });

    test('replaceRows notifies listeners once', () {
      int count = 0;
      final c = _ctrl()..addListener(() => count++);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      expect(count, 1);
    });

    test('operations that change nothing do not notify', () {
      int count = 0;
      final c = _ctrl(mode: TablexSelectionMode.multiple)
        ..addListener(() => count++);
      c.replaceRows([_alice], rowBuilder: _row);
      count = 0;

      c.goToPage(1);         // already page 1
      c.previousPage();      // already at 1, no-op
      c.clearSelection();    // nothing selected, no-op
      c.setLoading(false);   // already false, no-op
      c.resetColumnWidths(); // nothing to reset, no-op
      c.resetColumnOrder();  // nothing to reset, no-op

      expect(count, 0);
    });
  });

  // =========================================================================
  group('sliding-window row mutations', () {
    test('prependRows inserts at the beginning', () {
      final c = _ctrl();
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      c.prependRows([_carol], rowBuilder: _row);
      expect(c.rowCount, 3);
      expect(c.getAllRowData(), [_carol, _alice, _bob]);
    });

    test('prependRows on empty controller starts the list', () {
      final c = _ctrl();
      c.prependRows([_alice], rowBuilder: _row);
      expect(c.rowCount, 1);
      expect(c.getAllRowData(), [_alice]);
    });

    test('prependRows notifies listeners once', () {
      int count = 0;
      final c = _ctrl()..addListener(() => count++);
      c.replaceRows([_alice], rowBuilder: _row);
      count = 0;
      c.prependRows([_bob], rowBuilder: _row);
      expect(count, 1);
    });

    test('removeFirstRows removes N rows from the top', () {
      final c = _ctrl();
      c.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      c.removeFirstRows(2);
      expect(c.rowCount, 1);
      expect(c.getAllRowData(), [_carol]);
    });

    test('removeFirstRows(0) is a no-op and does not notify', () {
      int count = 0;
      final c = _ctrl()..addListener(() => count++);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      count = 0;
      c.removeFirstRows(0);
      expect(c.rowCount, 2);
      expect(count, 0);
    });

    test('removeFirstRows clamps to rowCount when count exceeds length', () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row);
      c.removeFirstRows(99);
      expect(c.rowCount, 0);
    });

    test('removeFirstRows notifies listeners', () {
      int count = 0;
      final c = _ctrl()..addListener(() => count++);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      count = 0;
      c.removeFirstRows(1);
      expect(count, 1);
    });

    test('removeLastRows removes N rows from the bottom', () {
      final c = _ctrl();
      c.replaceRows([_alice, _bob, _carol], rowBuilder: _row);
      c.removeLastRows(2);
      expect(c.rowCount, 1);
      expect(c.getAllRowData(), [_alice]);
    });

    test('removeLastRows(0) is a no-op and does not notify', () {
      int count = 0;
      final c = _ctrl()..addListener(() => count++);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      count = 0;
      c.removeLastRows(0);
      expect(c.rowCount, 2);
      expect(count, 0);
    });

    test('removeLastRows clamps to rowCount when count exceeds length', () {
      final c = _ctrl();
      c.replaceRows([_alice], rowBuilder: _row);
      c.removeLastRows(99);
      expect(c.rowCount, 0);
    });

    test('removeLastRows notifies listeners', () {
      int count = 0;
      final c = _ctrl()..addListener(() => count++);
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      count = 0;
      c.removeLastRows(1);
      expect(count, 1);
    });

    test('prepend + removeLastRows simulates backward-scroll window eviction', () {
      final c = _ctrl();
      c.replaceRows([_bob, _carol], rowBuilder: _row);
      c.prependRows([_alice], rowBuilder: _row);
      c.removeLastRows(1);
      expect(c.rowCount, 2);
      expect(c.getAllRowData(), [_alice, _bob]);
    });

    test('removeFirstRows + appendRows simulates forward-scroll window eviction', () {
      final c = _ctrl();
      c.replaceRows([_alice, _bob], rowBuilder: _row);
      c.removeFirstRows(1);
      c.appendRows([_carol], rowBuilder: _row);
      expect(c.rowCount, 2);
      expect(c.getAllRowData(), [_bob, _carol]);
    });
  });
}
