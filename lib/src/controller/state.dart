import '../model/query.dart';
import '../model/response.dart';

/// Immutable snapshot of all runtime state managed by [TablexController].
///
/// You rarely need to access this directly; prefer the typed getters on
/// [TablexController] (`selectedRows`, `hoveredRowIdx`, `editingRowIndex`, …).
/// Read the state for advanced cases such as deriving UI from multiple fields
/// at once — e.g. `controller.state.isLoading && !controller.state.isInitialized`.
class TablexState<T> {
  const TablexState({
    this.isLoading = false,
    this.isInitialized = false,
    this.query = const TablexQuery(),
    this.selectedRows = const [],
    this.hiddenColumnFields = const {},
    this.columnWidths = const {},
    this.columnOrder = const [],
    this.meta,
    this.error,
    this.editingRowIndex,
    this.editingField,
  });

  /// Whether an async fetch is currently in progress.
  final bool isLoading;

  /// `true` after the first successful data load. Used to distinguish
  /// "first load" (skeleton state) from subsequent page-change loads.
  final bool isInitialized;

  /// Current pagination / sort / filter query.
  final TablexQuery query;

  /// Currently selected row data objects.
  final List<T> selectedRows;

  /// Field keys of columns explicitly hidden by [TablexController.setColumnHidden].
  final Set<String> hiddenColumnFields;

  /// Per-column widths set by the user via column resizing.
  /// Keyed by [TablexColumnBase.fieldKey].
  final Map<String, double> columnWidths;

  /// Explicit column order after drag-to-reorder.
  /// Empty when columns are in their definition order.
  final List<String> columnOrder;

  /// Optional metadata returned by the last fetch (filter chips, extras).
  final TablexResponseMeta? meta;

  /// The last fetch error, or `null` when the grid is healthy.
  final Object? error;

  /// Zero-based row index currently in inline-edit mode, or `null`.
  final int? editingRowIndex;

  /// Field key of the cell currently in inline-edit mode, or `null`.
  final String? editingField;

  TablexState<T> copyWith({
    bool? isLoading,
    bool? isInitialized,
    TablexQuery? query,
    List<T>? selectedRows,
    Set<String>? hiddenColumnFields,
    Map<String, double>? columnWidths,
    List<String>? columnOrder,
    TablexResponseMeta? meta,
    bool clearMeta = false,
    Object? error,
    bool clearError = false,
    int? editingRowIndex,
    bool clearEditingRow = false,
    String? editingField,
    bool clearEditingField = false,
  }) {
    return TablexState<T>(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      query: query ?? this.query,
      selectedRows: selectedRows ?? this.selectedRows,
      hiddenColumnFields: hiddenColumnFields ?? this.hiddenColumnFields,
      columnWidths: columnWidths ?? this.columnWidths,
      columnOrder: columnOrder ?? this.columnOrder,
      meta: clearMeta ? null : (meta ?? this.meta),
      error: clearError ? null : (error ?? this.error),
      editingRowIndex:
          clearEditingRow ? null : (editingRowIndex ?? this.editingRowIndex),
      editingField:
          clearEditingField ? null : (editingField ?? this.editingField),
    );
  }
}
