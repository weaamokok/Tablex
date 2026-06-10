part of 'controller.dart';

extension TablexControllerRows<T> on TablexController<T> {
  // ── Read ──────────────────────────────────────────────────────────────────

  /// All rows currently held by the controller, in display order.
  List<TablexRow<T>> get rows => _rowOrder.map((k) {
        assert(_rowMap.containsKey(k),
            'Row key "$k" is in _rowOrder but missing from _rowMap — this is a controller bug');
        return _rowMap[k]!;
      }).toList(growable: false);

  /// Number of rows currently held by the controller.
  int get rowCount => _rowOrder.length;

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

  // ── Write ─────────────────────────────────────────────────────────────────

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

  /// Inserts [items] at the beginning of the row set without clearing existing rows.
  ///
  /// Used by the infinite-scroll sliding window when re-fetching evicted pages
  /// above the viewport.
  void prependRows(
    List<T> items, {
    required TablexRow<T> Function(T item) rowBuilder,
  }) {
    _checkDisposed();
    final newKeys = <String>[];
    for (final item in items) {
      final row = rowBuilder(item);
      final key = row.key ?? _generateKey();
      _rowMap[key] = TablexRow<T>(
          data: row.data, cells: row.cells, key: key, checked: row.checked);
      newKeys.add(key);
    }
    _rowOrder.insertAll(0, newKeys);
    _state = _state.copyWith(isInitialized: true);
    _notify();
  }

  /// Removes the first [count] rows from the controller.
  ///
  /// Used by the infinite-scroll sliding window to evict pages that have
  /// scrolled above the viewport.
  void removeFirstRows(int count) {
    _checkDisposed();
    final n = count.clamp(0, _rowOrder.length);
    if (n == 0) return;
    final evicted = _rowOrder.sublist(0, n);
    _rowOrder.removeRange(0, n);
    for (final key in evicted) {
      assert(_rowMap.containsKey(key),
          'Row key "$key" missing from _rowMap during removeFirstRows — controller bug');
      _rowMap.remove(key);
    }
    _notify();
  }

  /// Removes the last [count] rows from the controller.
  ///
  /// Used by the infinite-scroll sliding window to evict pages below the
  /// viewport when the user scrolls back up.
  void removeLastRows(int count) {
    _checkDisposed();
    final n = count.clamp(0, _rowOrder.length);
    if (n == 0) return;
    final start = _rowOrder.length - n;
    final evicted = _rowOrder.sublist(start);
    _rowOrder.removeRange(start, _rowOrder.length);
    for (final key in evicted) {
      assert(_rowMap.containsKey(key),
          'Row key "$key" missing from _rowMap during removeLastRows — controller bug');
      _rowMap.remove(key);
    }
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
}
