part of 'controller.dart';

extension TablexControllerColumns<T> on TablexController<T> {
  // ── Visibility ────────────────────────────────────────────────────────────

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

  // ── Width ─────────────────────────────────────────────────────────────────

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

  // ── Order ─────────────────────────────────────────────────────────────────

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

  // ── Frozen ────────────────────────────────────────────────────────────────

  /// Sets the frozen (pinned) side of [field] at runtime, overriding the
  /// static [TablexColumnBase.frozen] definition.
  ///
  /// Pass [TablexColumnFrozen.none] to explicitly unfreeze a column (even if
  /// it has a non-none static frozen value).
  void setColumnFrozen(String field, TablexColumnFrozen frozen) {
    _checkDisposed();
    final current =
        Map<String, TablexColumnFrozen>.from(_state.frozenColumnFields)
          ..[field] = frozen;
    _state = _state.copyWith(frozenColumnFields: current);
    _notify();
  }

  /// Returns the effective frozen side for [field].
  ///
  /// A runtime override set via [setColumnFrozen] takes precedence; otherwise
  /// [staticFrozen] (from the column definition) is returned.
  TablexColumnFrozen getColumnFrozen(
          String field, TablexColumnFrozen staticFrozen) =>
      _state.frozenColumnFields[field] ?? staticFrozen;

  // ── Inline editing ────────────────────────────────────────────────────────

  /// The zero-based index of the row in inline-edit mode, or `null`.
  int? get editingRowIndex => _state.editingRowIndex;

  /// The field key of the cell in inline-edit mode, or `null`.
  String? get editingField => _state.editingField;

  /// Updates a single cell value in place without requiring a full row rebuild.
  ///
  /// Called automatically by the grid when the user commits an inline edit.
  /// You can also call it programmatically for optimistic UI updates — e.g.
  /// immediately reflect a change while an async save is in flight.
  void updateCell(int rowIndex, String field, dynamic newValue) {
    _checkDisposed();
    if (rowIndex < 0 || rowIndex >= _rowOrder.length) return;
    final key = _rowOrder[rowIndex];
    final row = _rowMap[key]!;
    final updatedCells = Map<String, dynamic>.from(row.cells)
      ..[field] = newValue;
    _rowMap[key] = TablexRow<T>(
      data: row.data,
      cells: updatedCells,
      key: key,
      checked: row.checked,
    );
    _notify();
  }

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
}
