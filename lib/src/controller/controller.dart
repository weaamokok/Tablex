import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../model/column.dart';
import '../model/enums.dart';
import '../model/query.dart';
import '../model/response.dart';
import '../model/row.dart';
import 'state.dart';

/// Central controller for a Tablex grid.
///
/// `TablexController` is a [ChangeNotifier] — the grid rebuilds whenever any
/// mutating method is called. You can also add your own listeners:
///
/// ```dart
/// controller.addListener(() {
///   print('selection: ${controller.selectedRows}');
/// });
/// ```
///
/// **Lifecycle:** if you create the controller yourself, dispose it when the
/// owning widget is disposed:
///
/// ```dart
/// final _controller = TablexController<Employee>();
///
/// @override
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
/// ```
///
/// When passed to [TablexConsumer] or [Tablex] without creating your own
/// controller, the widget manages the lifecycle automatically.
class TablexController<T> extends ChangeNotifier {
  /// Creates a controller.
  ///
  /// [initialQuery] sets the starting page, page-size, sort, and filters.
  /// [selectionMode] is kept in sync with the widget — pass it here when you
  /// create the controller outside the widget tree and need selection APIs to
  /// respect the mode from the start.
  TablexController({
    TablexQuery initialQuery = const TablexQuery(),
    TablexSelectionMode selectionMode = TablexSelectionMode.none,
  })  : _selectionMode = selectionMode,
        _state = TablexState<T>(query: initialQuery);

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  TablexState<T> _state;

  /// The current immutable state snapshot. Prefer the typed getters for
  /// common operations; read [state] directly only when you need multiple
  /// fields from the same snapshot.
  TablexState<T> get state => _state;

  bool _disposed = false;
  bool _pendingNotify = false;

  final Map<String, TablexRow<T>> _rowMap = {};
  final List<String> _rowOrder = [];

  final ValueNotifier<int> _refreshSignal = ValueNotifier(0);

  /// A listenable that increments every time [refresh] is called.
  /// The grid's pagination / infinite-scroll layer listens to this to
  /// invalidate caches and re-fetch.
  ValueListenable<int> get refreshSignal => _refreshSignal;

  TablexSelectionMode _selectionMode;

  // Package-private setter — called once by the widget layer during init.
  set selectionMode(TablexSelectionMode m) => _selectionMode = m;

  static int _keyCounter = 0;
  String _generateKey() => 'row_${++_keyCounter}';

  // ---------------------------------------------------------------------------
  // Guard helpers
  // ---------------------------------------------------------------------------

  void _checkDisposed() {
    if (_disposed) throw StateError('TablexController has been disposed.');
  }

  void _notify() {
    if (_disposed) return;
    // Defer if we're in the middle of a build phase to avoid "setState called
    // during build" when replaceRows is called from a widget's initState while
    // sibling widgets have already subscribed to this controller.
    // Deduplicate: multiple mutations in the same build frame share one callback.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_pendingNotify) return;
      _pendingNotify = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _pendingNotify = false;
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Row management
  // ---------------------------------------------------------------------------

  /// All rows currently held by the controller, in display order.
  List<TablexRow<T>> get rows =>
      _rowOrder.map((k) => _rowMap[k]!).toList(growable: false);

  /// Number of rows currently held by the controller.
  int get rowCount => _rowOrder.length;

  /// Replaces all rows with [items], converting each via [rowBuilder].
  ///
  /// Set [clearSelection] to `false` to preserve the current selection across
  /// the replacement (useful for in-place refreshes). Set [markInitialized]
  /// to `false` to pre-populate skeleton rows without marking the grid as
  /// having real data — used internally by the loading-skeleton flow.
  void replaceRows(
    List<T> items, {
    required TablexRow<T> Function(T item) rowBuilder,
    bool clearSelection = true,
    bool markInitialized = true,
  }) {
    _checkDisposed();
    _rowMap.clear();
    _rowOrder.clear();
    for (final item in items) {
      final row = rowBuilder(item);
      final key = row.key ?? _generateKey();
      _rowMap[key] = TablexRow<T>(
          data: row.data, cells: row.cells, key: key, checked: row.checked);
      _rowOrder.add(key);
    }
    _state = _state.copyWith(
      isInitialized: markInitialized || _state.isInitialized,
      selectedRows: clearSelection ? [] : _state.selectedRows,
    );
    _notify();
  }

  /// Appends [items] to the current row set without clearing existing rows.
  ///
  /// Used by the infinite-scroll layer to accumulate pages.
  void appendRows(
    List<T> items, {
    required TablexRow<T> Function(T item) rowBuilder,
  }) {
    _checkDisposed();
    for (final item in items) {
      final row = rowBuilder(item);
      final key = row.key ?? _generateKey();
      _rowMap[key] = TablexRow<T>(
          data: row.data, cells: row.cells, key: key, checked: row.checked);
      _rowOrder.add(key);
    }
    _state = _state.copyWith(isInitialized: true);
    _notify();
  }

  /// Replaces the row at [index] with a new version of [item].
  ///
  /// The row keeps its existing key so any widgets keyed on it are updated
  /// in place rather than recreated.
  void updateRow(
    int index,
    T item, {
    required TablexRow<T> Function(T item) rowBuilder,
  }) {
    _checkDisposed();
    if (index < 0 || index >= _rowOrder.length) {
      throw RangeError.index(index, _rowOrder, 'index', null, _rowOrder.length);
    }
    final existingKey = _rowOrder[index];
    final row = rowBuilder(item);
    _rowMap[existingKey] = TablexRow<T>(
        data: row.data,
        cells: row.cells,
        key: existingKey,
        checked: row.checked);
    _notify();
  }

  /// Removes the row at [index].
  void removeRow(int index) {
    _checkDisposed();
    if (index < 0 || index >= _rowOrder.length) {
      throw RangeError.index(index, _rowOrder, 'index', null, _rowOrder.length);
    }
    final key = _rowOrder.removeAt(index);
    _rowMap.remove(key);
    _notify();
  }

  /// Removes all rows whose keys are in [keys].
  ///
  /// Row keys are set in [TablexRow.key] via your `rowBuilder`.
  void removeRowsByKey(List<String> keys) {
    _checkDisposed();
    for (final key in keys) {
      _rowMap.remove(key);
      _rowOrder.remove(key);
    }
    _notify();
  }

  /// Removes all rows and marks the grid as uninitialized (back to first-load
  /// state). The [TablexLoadingBuilder], if set, will re-appear on the next
  /// fetch.
  void clearRows() {
    _checkDisposed();
    _rowMap.clear();
    _rowOrder.clear();
    _state = _state.copyWith(isInitialized: false);
    _notify();
  }

  /// Returns the data object for the row with [rowKey], or `null` if not found.
  T? getRowData(String rowKey) => _rowMap[rowKey]?.data;

  /// Returns every row's data object in display order.
  List<T> getAllRowData() =>
      _rowOrder.map((k) => _rowMap[k]!.data).toList(growable: false);

  /// Returns the row at [index], or `null` if [index] is out of range.
  TablexRow<T>? getRowAt(int index) {
    if (index < 0 || index >= _rowOrder.length) return null;
    return _rowMap[_rowOrder[index]];
  }

  // ---------------------------------------------------------------------------
  // Query management
  // ---------------------------------------------------------------------------

  /// Replaces the entire query at once. Use the individual setters below for
  /// targeted updates — they guard against unnecessary rebuilds.
  void updateQuery(TablexQuery query) {
    _checkDisposed();
    if (_state.query == query) return;
    _state = _state.copyWith(query: query);
    _notify();
  }

  /// Sets an arbitrary extra parameter under [key] in [TablexQuery.params].
  ///
  /// If [resetPage] is `true` (the default), the page is reset to 1 so the
  /// user sees results from the beginning after the parameter changes.
  void setParam(String key, dynamic value, {bool resetPage = true}) {
    _checkDisposed();
    final newParams = Map<String, dynamic>.from(_state.query.params)
      ..[key] = value;
    final newQuery = _state.query.copyWith(
      params: newParams,
      page: resetPage ? 1 : null,
    );
    if (_state.query == newQuery) return;
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  /// Removes an extra parameter by [key] from [TablexQuery.params].
  void removeParam(String key, {bool resetPage = true}) {
    _checkDisposed();
    if (!_state.query.params.containsKey(key)) return;
    final newParams = Map<String, dynamic>.from(_state.query.params)
      ..remove(key);
    final newQuery = _state.query.copyWith(
      params: newParams,
      page: resetPage ? 1 : null,
    );
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  /// Clears all extra parameters from [TablexQuery.params].
  void clearParams({bool resetPage = true}) {
    _checkDisposed();
    if (_state.query.params.isEmpty) return;
    final newQuery = _state.query.copyWith(
      params: const {},
      page: resetPage ? 1 : null,
    );
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  /// Navigates to a specific [page] number (1-based).
  void goToPage(int page) {
    _checkDisposed();
    if (_state.query.page == page) return;
    _state = _state.copyWith(query: _state.query.copyWith(page: page));
    _notify();
  }

  /// Advances to the next page.
  void nextPage() => goToPage(_state.query.page + 1);

  /// Goes back to the previous page. No-op if already on page 1.
  void previousPage() {
    if (_state.query.page > 1) goToPage(_state.query.page - 1);
  }

  /// Changes the page size and resets to page 1.
  void setPageSize(int size) {
    _checkDisposed();
    final newQuery = _state.query.copyWith(pageSize: size, page: 1);
    if (_state.query == newQuery) return;
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  /// Sets the active sort. Pass `null` to clear sorting and return to the
  /// default server ordering.
  void setSort(TablexColumnSort? sort) {
    _checkDisposed();
    final newQuery = sort == null
        ? _state.query.copyWith(clearSort: true, page: 1)
        : _state.query.copyWith(sort: sort, page: 1);
    if (_state.query == newQuery) return;
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  /// Replaces the active column filters. Pass an empty list to clear all.
  void setFilters(List<TablexColumnFilter> filters) {
    _checkDisposed();
    final newQuery = _state.query.copyWith(filters: filters, page: 1);
    if (_state.query == newQuery) return;
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  /// Forces the grid to re-fetch the current page, invalidating the page cache.
  ///
  /// Use this after an out-of-band data mutation (e.g. after the user saves
  /// an edit) to sync the grid with the server.
  void refresh() {
    _checkDisposed();
    _refreshSignal.value++;
    _notify();
  }

  /// Updates the loading flag. Normally managed by the widget layer — you only
  /// need this when driving data manually via [replaceRows] / [appendRows].
  void setLoading(bool loading) {
    _checkDisposed();
    if (_state.isLoading == loading) return;
    _state = _state.copyWith(isLoading: loading);
    _notify();
  }

  /// Stores the [TablexResponseMeta] returned by the last fetch. Pass `null`
  /// to clear it.
  void setMeta(TablexResponseMeta? meta) {
    _checkDisposed();
    if (meta == null) {
      _state = _state.copyWith(clearMeta: true);
    } else {
      _state = _state.copyWith(meta: meta);
    }
    _notify();
  }

  /// Stores a fetch error so the [TablexErrorBuilder] can display it. Pass
  /// `null` to clear any previous error.
  void setError(Object? error) {
    _checkDisposed();
    if (error == null) {
      _state = _state.copyWith(clearError: true);
    } else {
      _state = _state.copyWith(error: error);
    }
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  /// Currently selected row data objects.
  List<T> get selectedRows => _state.selectedRows;

  /// Returns `true` if [item] is in the current selection.
  bool isSelected(T item) => _state.selectedRows.contains(item);

  /// Adds [item] to the selection, respecting [TablexSelectionMode].
  ///
  /// In [TablexSelectionMode.single] this replaces any existing selection.
  void selectRow(T item) {
    _checkDisposed();
    if (_selectionMode == TablexSelectionMode.none) return;
    if (_selectionMode == TablexSelectionMode.single) {
      _state = _state.copyWith(selectedRows: [item]);
    } else {
      if (isSelected(item)) return;
      _state = _state.copyWith(
        selectedRows: List<T>.from(_state.selectedRows)..add(item),
      );
    }
    _notify();
  }

  /// Removes [item] from the selection. No-op if not currently selected.
  void deselectRow(T item) {
    _checkDisposed();
    if (!isSelected(item)) return;
    _state = _state.copyWith(
      selectedRows: _state.selectedRows.where((r) => r != item).toList(),
    );
    _notify();
  }

  /// Selects [item] if not selected, deselects it if already selected.
  void toggleRowSelection(T item) {
    _checkDisposed();
    if (isSelected(item)) {
      deselectRow(item);
    } else {
      selectRow(item);
    }
  }

  /// Replaces the entire selection with [items].
  void setSelection(List<T> items) {
    _checkDisposed();
    _state = _state.copyWith(selectedRows: List<T>.from(items));
    _notify();
  }

  /// Clears all selected rows. No-op if the selection is already empty.
  void clearSelection() {
    _checkDisposed();
    if (_state.selectedRows.isEmpty) return;
    _state = _state.copyWith(selectedRows: []);
    _notify();
  }

  /// Selects every item in [allItems]. Only works in
  /// [TablexSelectionMode.multiple].
  void selectAll(List<T> allItems) {
    _checkDisposed();
    if (_selectionMode != TablexSelectionMode.multiple) return;
    _state = _state.copyWith(selectedRows: List<T>.from(allItems));
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Column visibility / resize / order
  // ---------------------------------------------------------------------------

  /// Hides or reveals the column identified by [field].
  void setColumnHidden(String field, bool hidden) {
    _checkDisposed();
    final current = Set<String>.from(_state.hiddenColumnFields);
    if (hidden) {
      if (current.contains(field)) return;
      current.add(field);
    } else {
      if (!current.contains(field)) return;
      current.remove(field);
    }
    _state = _state.copyWith(hiddenColumnFields: current);
    _notify();
  }

  /// Toggles visibility of the column identified by [field].
  void toggleColumnHidden(String field) {
    _checkDisposed();
    setColumnHidden(field, !isColumnHidden(field));
  }

  /// Returns `true` if the column with [field] is currently hidden.
  bool isColumnHidden(String field) =>
      _state.hiddenColumnFields.contains(field);

  /// The field keys of all currently hidden columns.
  List<String> get hiddenColumnFields =>
      _state.hiddenColumnFields.toList(growable: false);

  /// Sets the pixel width of the column identified by [field].
  ///
  /// Called automatically by the column-resize drag handle; you can also call
  /// it programmatically to enforce initial widths.
  void setColumnWidth(String field, double width) {
    _checkDisposed();
    final newWidths = Map<String, double>.from(_state.columnWidths)
      ..[field] = width;
    _state = _state.copyWith(columnWidths: newWidths);
    _notify();
  }

  /// Resets all column widths to their definition defaults.
  void resetColumnWidths() {
    _checkDisposed();
    if (_state.columnWidths.isEmpty) return;
    _state = _state.copyWith(columnWidths: const {});
    _notify();
  }

  /// Moves the column identified by [field] to [newIndex] in the display order.
  void reorderColumn(String field, int newIndex) {
    _checkDisposed();
    final order = List<String>.from(_state.columnOrder);
    final current = order.indexOf(field);
    if (current == -1 || current == newIndex) return;
    order.removeAt(current);
    final clampedIndex = newIndex.clamp(0, order.length);
    order.insert(clampedIndex, field);
    _state = _state.copyWith(columnOrder: order);
    _notify();
  }

  /// Replaces the entire column order in one call.
  ///
  /// Called by the header drag-to-reorder handle; you can also call it
  /// programmatically to restore a saved layout.
  void setColumnOrder(List<String> fields) {
    _checkDisposed();
    _state = _state.copyWith(columnOrder: List<String>.from(fields));
    _notify();
  }

  /// Resets the column order to the order in which columns were defined.
  void resetColumnOrder() {
    _checkDisposed();
    if (_state.columnOrder.isEmpty) return;
    _state = _state.copyWith(columnOrder: const []);
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Inline editing
  // ---------------------------------------------------------------------------

  /// The zero-based index of the row in inline-edit mode, or `null`.
  int? get editingRowIndex => _state.editingRowIndex;

  /// The field key of the cell in inline-edit mode, or `null`.
  String? get editingField => _state.editingField;

  /// Enters inline-edit mode for the cell at ([rowIndex], [field]).
  void beginEdit(int rowIndex, String field) {
    _checkDisposed();
    _state = _state.copyWith(editingRowIndex: rowIndex, editingField: field);
    _notify();
  }

  /// Exits inline-edit mode after the user confirms a value.
  ///
  /// Call [updateRow] first to persist the new value, then call this to clear
  /// the editing state and trigger a rebuild.
  void confirmEdit(int rowIndex, String field) {
    _checkDisposed();
    _state = _state.copyWith(clearEditingRow: true, clearEditingField: true);
    _notify();
  }

  /// Exits inline-edit mode, discarding any pending changes.
  void cancelEdit() {
    _checkDisposed();
    _state = _state.copyWith(clearEditingRow: true, clearEditingField: true);
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Serialises all currently loaded rows to a CSV string.
  ///
  /// Only visible (non-hidden) columns are included. Values are sanitised to
  /// prevent CSV injection. Wrap the result in a `Blob` / write it to a file
  /// using your preferred platform API.
  ///
  /// ```dart
  /// final csv = controller.exportToCsv(columns);
  /// await FileSaver.instance.saveFile('export.csv', csv.codeUnits);
  /// ```
  String exportToCsv(List<TablexColumnBase<T>> columns) {
    _checkDisposed();
    final visibleColumns = columns
        .where((c) => !c.hide && !isColumnHidden(c.fieldKey))
        .toList(growable: false);

    final buffer = StringBuffer();

    // Header row
    buffer.writeln(
      visibleColumns.map((c) => _csvCell(c.title)).join(','),
    );

    // Data rows
    for (final key in _rowOrder) {
      final row = _rowMap[key]!;
      final values = visibleColumns.map((col) {
        final raw = row.cells[col.fieldKey];
        String text;
        if (raw == null) {
          text = '';
        } else {
          text = col.formatValueRaw(raw) ?? raw.toString();
        }
        return _csvCell(text);
      });
      buffer.writeln(values.join(','));
    }

    return buffer.toString();
  }

  /// Imports rows from a CSV string.
  ///
  /// [rowFactory] receives a `Map<String, String>` keyed by header name (or
  /// by [fieldKeys] when [hasHeader] is `false`) and must return a [TablexRow].
  ///
  /// Set [append] to `true` to add the imported rows after existing ones
  /// instead of replacing them.
  ///
  /// ```dart
  /// controller.importFromCsv(
  ///   csvString,
  ///   (map) => TablexRow(
  ///     data: Employee(name: map['Name']!, salary: double.parse(map['Salary']!)),
  ///     key: map['Id'],
  ///     cells: {'name': map['Name']!, 'salary': double.parse(map['Salary']!)},
  ///   ),
  /// );
  /// ```
  void importFromCsv(
    String csvText,
    TablexRow<T> Function(Map<String, String> row) rowFactory, {
    bool hasHeader = true,
    List<String>? fieldKeys,
    bool append = false,
  }) {
    _checkDisposed();
    final rawRows = _parseCsvRows(csvText);
    if (rawRows.isEmpty) return;

    final List<String> keys;
    final int dataStart;

    if (hasHeader) {
      keys = rawRows.first;
      dataStart = 1;
    } else {
      keys = fieldKeys ?? List.generate(rawRows.first.length, (i) => 'col$i');
      dataStart = 0;
    }

    if (!append) {
      _rowMap.clear();
      _rowOrder.clear();
    }

    for (int i = dataStart; i < rawRows.length; i++) {
      final cells = rawRows[i];
      final map = {
        for (int j = 0; j < keys.length && j < cells.length; j++)
          keys[j]: cells[j],
      };
      final row = rowFactory(map);
      final key = row.key ?? _generateKey();
      _rowMap[key] = TablexRow<T>(
          data: row.data, cells: row.cells, key: key, checked: row.checked);
      _rowOrder.add(key);
    }

    _state = _state.copyWith(
      isInitialized: true,
      selectedRows: append ? null : <T>[],
    );
    _notify();
  }

  /// Serialises all currently loaded rows to an Excel (.xlsx) byte array.
  ///
  /// Only visible (non-hidden) columns are included. Numeric and boolean
  /// values are written as typed Excel cells; everything else uses the
  /// column's [TablexColumn.formatter] or `toString()`.
  ///
  /// ```dart
  /// final bytes = controller.exportToExcel(columns);
  /// await FileSaver.instance.saveFile('export.xlsx', bytes);
  /// ```
  Uint8List exportToExcel(
    List<TablexColumnBase<T>> columns, {
    String sheetName = 'Sheet1',
  }) {
    _checkDisposed();
    final visibleColumns = columns
        .where((c) => !c.hide && !isColumnHidden(c.fieldKey))
        .toList(growable: false);

    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet();
    final sheet = workbook[sheetName];
    if (defaultSheet != null && defaultSheet != sheetName) {
      workbook.delete(defaultSheet);
    }

    // Header row
    sheet.appendRow(
      visibleColumns
          .map<CellValue>((c) => TextCellValue(c.title))
          .toList(growable: false),
    );

    // Data rows
    for (final key in _rowOrder) {
      final row = _rowMap[key]!;
      sheet.appendRow(
        visibleColumns.map<CellValue>((col) {
          final raw = row.cells[col.fieldKey];
          if (raw == null) return TextCellValue('');
          return _toCellValue(raw, col.formatValueRaw(raw));
        }).toList(growable: false),
      );
    }

    final encoded = workbook.encode();
    if (encoded == null) throw StateError('Excel encoding produced no output.');
    return Uint8List.fromList(encoded);
  }

  /// Imports rows from an Excel (.xlsx) byte array.
  ///
  /// [rowFactory] receives a `Map<String, String>` keyed by header name (or
  /// by [fieldKeys] when [hasHeader] is `false`) and must return a [TablexRow].
  /// All cell values are converted to strings before being passed to the factory.
  ///
  /// Set [append] to `true` to add rows after the existing ones.
  ///
  /// ```dart
  /// controller.importFromExcel(
  ///   excelBytes,
  ///   (map) => TablexRow(
  ///     data: Employee(name: map['Name']!, salary: double.parse(map['Salary']!)),
  ///     key: map['Id'],
  ///     cells: {'name': map['Name']!, 'salary': double.parse(map['Salary']!)},
  ///   ),
  /// );
  /// ```
  void importFromExcel(
    Uint8List bytes,
    TablexRow<T> Function(Map<String, String> row) rowFactory, {
    int sheetIndex = 0,
    bool hasHeader = true,
    List<String>? fieldKeys,
    bool append = false,
  }) {
    _checkDisposed();
    final workbook = Excel.decodeBytes(bytes);
    final sheetName = workbook.sheets.keys.elementAt(sheetIndex);
    final sheet = workbook.sheets[sheetName]!;
    final dataRows = sheet.rows;
    if (dataRows.isEmpty) return;

    final List<String> keys;
    final int dataStart;

    if (hasHeader) {
      keys = dataRows.first
          .map((c) => _cellValueToString(c?.value))
          .toList(growable: false);
      dataStart = 1;
    } else {
      keys = fieldKeys ??
          List.generate(dataRows.first.length, (i) => 'col$i');
      dataStart = 0;
    }

    if (!append) {
      _rowMap.clear();
      _rowOrder.clear();
    }

    for (int i = dataStart; i < dataRows.length; i++) {
      final excelRow = dataRows[i];
      final map = {
        for (int j = 0; j < keys.length && j < excelRow.length; j++)
          keys[j]: _cellValueToString(excelRow[j]?.value),
      };
      final row = rowFactory(map);
      final key = row.key ?? _generateKey();
      _rowMap[key] = TablexRow<T>(
          data: row.data, cells: row.cells, key: key, checked: row.checked);
      _rowOrder.add(key);
    }

    _state = _state.copyWith(
      isInitialized: true,
      selectedRows: append ? null : <T>[],
    );
    _notify();
  }

  /// Sanitises a single value for CSV output (injection prevention + quoting).
  String _csvCell(String value) {
    // Prevent CSV injection: values starting with formula chars get a tab
    // prefix. A tab is invisible in spreadsheet cells, survives round-trips
    // through this library without ambiguity, and cannot appear at the start
    // of legitimate data in typical use.
    if (value.isNotEmpty &&
        (value.startsWith('=') ||
            value.startsWith('+') ||
            value.startsWith('-') ||
            value.startsWith('@'))) {
      value = '\t$value';
    }
    // Wrap in double quotes if the value contains a comma, newline, double
    // quote, or the tab we may have just prepended.
    if (value.contains(',') ||
        value.contains('\n') ||
        value.contains('"') ||
        value.contains('\t')) {
      value = '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// RFC 4180 CSV parser. Returns rows as lists of field strings.
  static List<List<String>> _parseCsvRows(String csv) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    int i = 0;

    while (i < csv.length) {
      final ch = csv[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < csv.length && csv[i + 1] == '"') {
            buf.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
        } else {
          buf.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          currentRow.add(_unescapeCsvCell(buf.toString()));
          buf.clear();
        } else if (ch == '\n') {
          currentRow.add(_unescapeCsvCell(buf.toString()));
          buf.clear();
          rows.add(List.of(currentRow));
          currentRow.clear();
        } else if (ch != '\r') {
          buf.write(ch);
        }
      }
      i++;
    }

    // Flush final field and row.
    currentRow.add(_unescapeCsvCell(buf.toString()));
    if (currentRow.any((f) => f.isNotEmpty)) {
      rows.add(List.of(currentRow));
    }

    return rows;
  }

  /// Strips the injection-prevention tab prefix added by [_csvCell] so that
  /// a CSV round-trip preserves the original value.
  static String _unescapeCsvCell(String value) {
    if (value.startsWith('\t') && value.length > 1) {
      final rest = value.substring(1);
      if (rest.startsWith('=') ||
          rest.startsWith('+') ||
          rest.startsWith('-') ||
          rest.startsWith('@')) {
        return rest;
      }
    }
    return value;
  }

  /// Maps a raw cell value to a typed [CellValue] for Excel export.
  static CellValue _toCellValue(dynamic raw, String? formatted) {
    if (raw is int) return IntCellValue(raw);
    if (raw is double) return DoubleCellValue(raw);
    if (raw is bool) return BoolCellValue(raw);
    return TextCellValue(formatted ?? raw.toString());
  }

  /// Converts an Excel [CellValue] to a plain string for import.
  static String _cellValueToString(CellValue? value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.value.text ?? '';
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value.toString();
    if (value is DateCellValue) {
      return value.asDateTimeLocal().toIso8601String().split('T').first;
    }
    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }
    if (value is TimeCellValue) {
      final h = value.hour.toString().padLeft(2, '0');
      final m = value.minute.toString().padLeft(2, '0');
      final s = value.second.toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return value.toString();
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _disposed = true;
    _rowMap.clear();
    _rowOrder.clear();
    _refreshSignal.dispose();
    super.dispose();
  }
}
