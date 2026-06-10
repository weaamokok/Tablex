part of 'controller.dart';

extension TablexControllerSelection<T> on TablexController<T> {
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
}
