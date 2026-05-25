import 'package:flutter/material.dart';
import '../model/enums.dart';

/// Runtime metadata passed to every [TablexColumn.cellRenderer] callback.
///
/// Use this to adapt the cell widget to its current state — for example,
/// showing a different icon when the row is hovered, or centering text in
/// RTL layouts.
class TablexCellContext {
  const TablexCellContext({
    required this.rowIndex,
    required this.isHovered,
    required this.isSelected,
    required this.isEditing,
    required this.textDirection,
    required this.density,
    required this.columnField,
    required this.columnTitle,
    required this.columnType,
  });

  /// Zero-based index of this row in the current page / visible set.
  final int rowIndex;

  /// Whether the pointer is currently hovering over this row.
  final bool isHovered;

  /// Whether this row is currently in the selection set.
  final bool isSelected;

  /// Whether this cell is currently in inline-edit mode.
  final bool isEditing;

  /// Resolved text direction from the widget tree (LTR or RTL).
  final TextDirection textDirection;

  /// The active row density — useful for adjusting padding or icon sizes.
  final TablexDensity density;

  /// The [TablexColumnBase.fieldKey] of the owning column.
  final String columnField;

  /// The [TablexColumnBase.title] of the owning column.
  final String columnTitle;

  /// The [TablexColumnBase.type] of the owning column.
  final TablexColumnType columnType;
}

/// Metadata passed to a column's [TablexColumnBase.footerRenderer] callback.
///
/// Use [allRowData] for column-wide aggregations (sum, average) and
/// [visibleRowData] if you only want to aggregate the currently visible rows.
class TablexFooterContext<T> {
  const TablexFooterContext({
    required this.field,
    required this.allRowData,
    required this.visibleRowData,
  });

  /// The [TablexColumnBase.fieldKey] of the owning column.
  final String field;

  /// Every row currently held by the controller (all pages in the cache).
  final List<T> allRowData;

  /// Only the rows currently rendered in the viewport.
  final List<T> visibleRowData;
}
