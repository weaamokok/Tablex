import 'dart:async';
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

Widget _harness(Widget widget) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 800, height: 600, child: widget)),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  group('TablexQuery.copyWith', () {
    test('replaces page, leaves other fields untouched', () {
      const q = TablexQuery(page: 1, pageSize: 25);
      final q2 = q.copyWith(page: 5);
      expect(q2.page, 5);
      expect(q2.pageSize, 25);
      expect(q2.sort, isNull);
    });

    test('replaces sort without touching page', () {
      const q = TablexQuery(page: 3);
      const sort = TablexColumnSort(
          field: 'name', direction: TablexSortDirection.ascending);
      final q2 = q.copyWith(sort: sort);
      expect(q2.sort, sort);
      expect(q2.page, 3);
    });

    test('clearSort: true nullifies sort regardless of sort argument', () {
      const sort = TablexColumnSort(
          field: 'name', direction: TablexSortDirection.descending);
      const q = TablexQuery(sort: sort);
      final q2 = q.copyWith(clearSort: true);
      expect(q2.sort, isNull);
    });

    test(
        'clearSort: false (default) preserves existing sort when no new sort given',
        () {
      const sort = TablexColumnSort(
          field: 'id', direction: TablexSortDirection.ascending);
      const q = TablexQuery(sort: sort);
      final q2 = q.copyWith(page: 2);
      expect(q2.sort, sort);
    });

    test('equality holds for structurally identical instances', () {
      const a = TablexQuery(page: 2, pageSize: 10);
      const b = TablexQuery(page: 2, pageSize: 10);
      expect(a, b);
    });

    test('inequality when pages differ', () {
      const a = TablexQuery(page: 1);
      const b = TablexQuery(page: 2);
      expect(a, isNot(b));
    });

    test('inequality when sort differs', () {
      const sort = TablexColumnSort(
          field: 'name', direction: TablexSortDirection.ascending);
      const a = TablexQuery(sort: sort);
      const b = TablexQuery();
      expect(a, isNot(b));
    });
  });

  // =========================================================================
  group('static sort', () {
    testWidgets('first tap sorts column ascending', (tester) async {
      final ctrl = TablexController<_Item>();
      await tester.pumpWidget(_harness(Tablex.static(
        columns: _cols,
        rows: const [_carol, _alice, _bob], // deliberately unsorted
        rowBuilder: _row,
        controller: ctrl,
      )));
      await tester.pump();

      await tester.tap(find.text('Name'));
      await tester.pump();

      expect(ctrl.getAllRowData().map((i) => i.name).toList(),
          ['Alice', 'Bob', 'Carol']);
    });

    testWidgets('second tap on same column sorts descending', (tester) async {
      final ctrl = TablexController<_Item>();
      await tester.pumpWidget(_harness(Tablex.static(
        columns: _cols,
        rows: const [_carol, _alice, _bob],
        rowBuilder: _row,
        controller: ctrl,
      )));
      await tester.pump();

      await tester.tap(find.text('Name'));
      await tester.pump();
      await tester.tap(find.text('Name'));
      await tester.pump();

      expect(ctrl.getAllRowData().map((i) => i.name).toList(),
          ['Carol', 'Bob', 'Alice']);
    });

    testWidgets('third tap clears sort and restores original row order',
        (tester) async {
      final ctrl = TablexController<_Item>();
      await tester.pumpWidget(_harness(Tablex.static(
        columns: _cols,
        rows: const [_carol, _alice, _bob],
        rowBuilder: _row,
        controller: ctrl,
      )));
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Name'));
        await tester.pump();
      }

      // After sort cleared the widget re-applies _staticRows in original order
      expect(ctrl.getAllRowData().map((i) => i.name).toList(),
          ['Carol', 'Alice', 'Bob']);
    });

    testWidgets('ascending sort icon appears on sorted column', (tester) async {
      await tester.pumpWidget(_harness(Tablex.static(
        columns: _cols,
        rows: const [_alice, _bob],
        rowBuilder: _row,
      )));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_upward), findsNothing);

      await tester.tap(find.text('Name'));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('descending sort icon appears on second tap', (tester) async {
      await tester.pumpWidget(_harness(Tablex.static(
        columns: _cols,
        rows: const [_alice, _bob],
        rowBuilder: _row,
      )));
      await tester.pump();

      await tester.tap(find.text('Name'));
      await tester.pump();
      await tester.tap(find.text('Name'));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('sort icon disappears after third tap (sort cleared)',
        (tester) async {
      await tester.pumpWidget(_harness(Tablex.static(
        columns: _cols,
        rows: const [_alice, _bob],
        rowBuilder: _row,
      )));
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Name'));
        await tester.pump();
      }

      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });

    testWidgets('sort by numeric ID column orders by integer value',
        (tester) async {
      final ctrl = TablexController<_Item>();
      // Insert in non-numeric order
      const d = _Item(10, 'Dave');
      const e = _Item(2, 'Eve');
      await tester.pumpWidget(_harness(Tablex.static(
        columns: _cols,
        rows: const [d, e],
        rowBuilder: _row,
        controller: ctrl,
      )));
      await tester.pump();

      await tester.tap(find.text('ID'));
      await tester.pump();

      expect(ctrl.getAllRowData().map((i) => i.id).toList(), [2, 10]);
    });
  });

  // =========================================================================
  group('lazy paged — fetch', () {
    testWidgets('initial fetch is called with page 1 and initialPageSize',
        (tester) async {
      TablexQuery? captured;
      final completer = Completer<TablexFetchResult<_Item>>();

      await tester.pumpWidget(_harness(Tablex.lazyPaged(
        columns: _cols,
        rowBuilder: _row,
        initialPageSize: 10,
        fetchTask: (q) {
          captured = q;
          return completer.future;
        },
      )));
      await tester.pump(); // frame 2: postFrameCallback fires → _fetchPage(1)

      expect(captured, isNotNull);
      expect(captured!.page, 1);
      expect(captured!.pageSize, 10);

      completer.complete(TablexFetchResult(rows: [_alice], totalRows: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('rows returned from fetch are rendered in the table',
        (tester) async {
      final completer = Completer<TablexFetchResult<_Item>>();

      await tester.pumpWidget(_harness(Tablex.lazyPaged(
        columns: _cols,
        rowBuilder: _row,
        fetchTask: (_) => completer.future,
      )));
      await tester.pump();

      completer.complete(TablexFetchResult(
        rows: [_alice, _bob],
        totalRows: 2,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('tapping column header triggers re-fetch with sort and page 1',
        (tester) async {
      final queries = <TablexQuery>[];
      final calls = <Completer<TablexFetchResult<_Item>>>[];

      await tester.pumpWidget(_harness(Tablex.lazyPaged(
        columns: _cols,
        rowBuilder: _row,
        fetchTask: (q) {
          queries.add(q);
          final c = Completer<TablexFetchResult<_Item>>();
          calls.add(c);
          return c.future;
        },
      )));
      await tester.pump(); // postFrameCallback → _fetchPage(1) called

      expect(calls.length, 1,
          reason: 'Initial fetch should have been triggered');

      // Complete initial fetch
      calls[0].complete(TablexFetchResult(rows: [_alice], totalRows: 1));
      await tester.pumpAndSettle();

      final countBeforeSort = queries.length;

      // Tap Name header → ascending sort → re-fetch
      await tester.tap(find.text('Name'));
      await tester.pump();
      await tester.pump();

      expect(queries.length, greaterThan(countBeforeSort));
      expect(queries.last.page, 1);
      expect(queries.last.sort?.field, 'name');
      expect(queries.last.sort?.direction, TablexSortDirection.ascending);

      calls.last.complete(TablexFetchResult(rows: [_alice], totalRows: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('fetch error is stored in controller error state',
        (tester) async {
      final ctrl = TablexController<_Item>();
      final completer = Completer<TablexFetchResult<_Item>>();

      await tester.pumpWidget(_harness(Tablex.lazyPaged(
        columns: _cols,
        rowBuilder: _row,
        controller: ctrl,
        fetchTask: (_) => completer.future,
      )));
      await tester.pump();

      completer.completeError(Exception('network error'));
      await tester.pumpAndSettle();

      expect(ctrl.state.error, isA<Exception>());
    });

    testWidgets('custom error widget is shown when errorBuilder is provided',
        (tester) async {
      final completer = Completer<TablexFetchResult<_Item>>();

      await tester.pumpWidget(_harness(Tablex.lazyPaged(
        columns: _cols,
        rowBuilder: _row,
        fetchTask: (_) => completer.future,
        errorBuilder: (ctx, err) => const Text('FETCH_FAILED'),
      )));
      await tester.pump();

      completer.completeError(Exception('boom'));
      await tester.pumpAndSettle();

      expect(find.text('FETCH_FAILED'), findsOneWidget);
    });
  });

  // =========================================================================
  group('infinite scroll — initial load', () {
    testWidgets('first fetch is called with page 1 and fetchSize',
        (tester) async {
      TablexQuery? captured;
      final completer = Completer<TablexFetchResult<_Item>>();

      await tester.pumpWidget(_harness(Tablex.infinite(
        columns: _cols,
        rowBuilder: _row,
        fetchSize: 20,
        windowPages: 5,
        fetchTask: (q) {
          captured ??= q;
          return completer.future;
        },
      )));
      await tester.pump(); // postFrameCallback fires _fetchForward

      expect(captured, isNotNull);
      expect(captured!.page, 1);
      expect(captured!.pageSize, 20);

      completer.complete(TablexFetchResult(rows: [], totalRows: 0));
      await tester.pumpAndSettle();
    });

    testWidgets('rows from first fetch are rendered', (tester) async {
      final completer = Completer<TablexFetchResult<_Item>>();

      await tester.pumpWidget(_harness(Tablex.infinite(
        columns: _cols,
        rowBuilder: _row,
        fetchSize: 10,
        windowPages: 5,
        fetchTask: (_) => completer.future,
      )));
      await tester.pump();

      completer.complete(TablexFetchResult(
        rows: [_alice, _bob, _carol],
        totalRows: 3,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
    });

    testWidgets(
        'first page uses replaceRows so skeleton rows are replaced, not appended',
        (tester) async {
      final ctrl = TablexController<_Item>();
      final completer = Completer<TablexFetchResult<_Item>>();
      final skeletons = List.generate(5, (i) => _Item(-i - 1, 'placeholder'));

      await tester.pumpWidget(_harness(Tablex.infinite(
        columns: _cols,
        controller: ctrl,
        rowBuilder: _row,
        fetchSize: 3,
        windowPages: 5,
        fetchTask: (_) => completer.future,
        loadingBuilder: TablexLoadingBuilder(
          skeletonData: skeletons,
          builder: (ctx, table) => table,
        ),
      )));

      // After initState: skeleton rows pre-loaded, real fetch not yet resolved
      await tester.pump();
      expect(ctrl.rowCount, 5,
          reason: 'Skeleton rows should be present before fetch completes');

      // Trigger the postFrameCallback → _fetchForward starts
      await tester.pump();

      // Resolve with 3 real items
      completer.complete(
          TablexFetchResult(rows: [_alice, _bob, _carol], totalRows: 3));
      await tester.pumpAndSettle();

      // replaceRows should have been used: exactly 3 real rows, not 5+3
      expect(ctrl.rowCount, 3,
          reason:
              'Real rows must replace skeleton rows, not append after them');
      expect(ctrl.getAllRowData(), [_alice, _bob, _carol]);
    });

    testWidgets('fetch error is stored in controller error state',
        (tester) async {
      final ctrl = TablexController<_Item>();
      final completer = Completer<TablexFetchResult<_Item>>();

      await tester.pumpWidget(_harness(Tablex.infinite(
        columns: _cols,
        controller: ctrl,
        rowBuilder: _row,
        fetchSize: 10,
        windowPages: 5,
        fetchTask: (_) => completer.future,
      )));
      await tester.pump();

      completer.completeError(Exception('load error'));
      await tester.pumpAndSettle();

      expect(ctrl.state.error, isA<Exception>());
    });
  });

  // =========================================================================
  group('infinite scroll — sort', () {
    testWidgets('tapping column header triggers re-fetch with page 1 and sort',
        (tester) async {
      final ctrl = TablexController<_Item>();
      final queries = <TablexQuery>[];
      final calls = <Completer<TablexFetchResult<_Item>>>[];

      await tester.pumpWidget(_harness(Tablex.infinite(
        columns: _cols,
        controller: ctrl,
        rowBuilder: _row,
        fetchSize: 3,
        windowPages: 5,
        fetchWithSorting: true,
        fetchTask: (q) {
          queries.add(q);
          final c = Completer<TablexFetchResult<_Item>>();
          calls.add(c);
          return c.future;
        },
      )));
      await tester.pump(); // postFrameCallback → _fetchForward

      expect(calls.length, 1, reason: 'Initial fetch should be triggered');

      // Complete first fetch
      calls[0].complete(
          TablexFetchResult(rows: [_alice, _bob, _carol], totalRows: 3));
      await tester.pumpAndSettle();

      final countAfterInit = queries.length;

      // Tap 'Name' to sort ascending
      await tester.tap(find.text('Name'));
      await tester.pump();
      await tester.pump();

      expect(queries.length, greaterThan(countAfterInit),
          reason: 'Sort should trigger a new fetch');
      expect(queries.last.page, 1,
          reason: 'Sort re-fetch must start from page 1');
      expect(queries.last.sort?.field, 'name');
      expect(queries.last.sort?.direction, TablexSortDirection.ascending);

      calls.last.complete(
          TablexFetchResult(rows: [_alice, _bob, _carol], totalRows: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('sort clears previous rows and installs result rows',
        (tester) async {
      final ctrl = TablexController<_Item>();
      final calls = <Completer<TablexFetchResult<_Item>>>[];

      await tester.pumpWidget(_harness(Tablex.infinite(
        columns: _cols,
        controller: ctrl,
        rowBuilder: _row,
        fetchSize: 2,
        windowPages: 5,
        fetchWithSorting: true,
        fetchTask: (_) {
          final c = Completer<TablexFetchResult<_Item>>();
          calls.add(c);
          return c.future;
        },
      )));
      await tester.pump();

      // Complete first fetch: alice + bob
      calls[0].complete(TablexFetchResult(rows: [_alice, _bob], totalRows: 2));
      await tester.pumpAndSettle();
      expect(ctrl.getAllRowData(), [_alice, _bob]);

      // Tap 'Name' → sort → clearRows → re-fetch
      await tester.tap(find.text('Name'));
      await tester.pump();
      await tester.pump();

      // Before sort fetch completes, old rows must be gone
      expect(ctrl.getAllRowData().contains(_alice), isFalse,
          reason: 'Rows must be cleared on sort reset');
      expect(ctrl.getAllRowData().contains(_bob), isFalse,
          reason: 'Rows must be cleared on sort reset');

      // Complete sort fetch with only carol
      calls.last.complete(TablexFetchResult(rows: [_carol], totalRows: 1));
      await tester.pumpAndSettle();

      expect(ctrl.getAllRowData(), [_carol],
          reason: 'After sort, rows come from the fresh fetch');
    });

    testWidgets(
        'stale in-flight fetch result is discarded when sort fires mid-fetch',
        (tester) async {
      final ctrl = TablexController<_Item>();
      final calls = <Completer<TablexFetchResult<_Item>>>[];

      await tester.pumpWidget(_harness(Tablex.infinite(
        columns: _cols,
        controller: ctrl,
        rowBuilder: _row,
        fetchSize: 2,
        windowPages: 5,
        fetchWithSorting: true,
        fetchTask: (_) {
          final c = Completer<TablexFetchResult<_Item>>();
          calls.add(c);
          return c.future;
        },
      )));
      await tester.pump(); // first _fetchForward starts

      // Tap sort BEFORE the first fetch resolves → invalidates generation
      await tester.tap(find.text('Name'));
      await tester.pump();
      await tester.pump();

      // Now complete the stale first fetch (generation already incremented)
      calls[0].complete(TablexFetchResult(rows: [_alice, _bob], totalRows: 2));
      await tester.pump();

      // Complete the valid sort fetch
      calls.last.complete(TablexFetchResult(rows: [_carol], totalRows: 1));
      await tester.pumpAndSettle();

      // Only carol should be in the table; alice+bob were from the stale fetch
      expect(ctrl.getAllRowData(), [_carol],
          reason: 'Stale fetch result must be discarded by generation guard');
    });
  });
}
