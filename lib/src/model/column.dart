import 'package:flutter/material.dart';
import 'enums.dart';
import '../renderer/cell_context.dart';

/// Base class for all Tablex column descriptors.
///
/// Use the concrete subclass [TablexColumn] for the vast majority of cases.
/// Extend this class only when you need a column whose value type can't be
/// captured statically (e.g. a fully dynamic schema).
abstract class TablexColumnBase<TRow> {
  const TablexColumnBase({
    required this.fieldKey,
    required this.title,
    this.width,
    this.minWidth = 100,
    this.frozen = TablexColumnFrozen.none,
    this.hide = false,
    this.hideIfEmpty = false,
    this.enableSorting = true,
    this.enableFiltering = true,
    this.enableEditing = false,
    this.enableContextMenu = true,
    this.textAlign = TextAlign.start,
    this.backgroundColor,
    this.emptyCellPlaceholder,
    this.showEmptyAsDash = true,
    this.type = TablexColumnType.text,
    this.footerRenderer,
    this.exportFormatter,
  });

  /// Unique key that identifies this column and maps to a key in
  /// [TablexRow.cells]. Must match the key you write in `rowBuilder`.
  final String fieldKey;

  /// Header label shown in the column header cell.
  final String title;

  /// Fixed column width in logical pixels. When `null` the column defaults
  /// to 150 px but can be resized by the user.
  final double? width;

  /// Minimum width the column can be resized to. Defaults to 100 px.
  final double minWidth;

  /// Whether and where this column is frozen (pinned) during horizontal scroll.
  final TablexColumnFrozen frozen;

  /// Set to `true` to hide the column from the grid by default. Users can
  /// still reveal it via [TablexColumnManagerButton].
  final bool hide;

  /// Set to `true` to automatically hide this column when every loaded row has
  /// a null or empty value for it. The column reappears as soon as any row
  /// provides a non-empty value and stays visible for the rest of the session —
  /// preventing the flickering that occurs when hiding is re-evaluated on every
  /// page load.
  ///
  /// The grid-level [Tablex.hideEmptyColumns] flag applies the same behaviour
  /// to all columns at once; [hideIfEmpty] lets you opt individual columns in.
  final bool hideIfEmpty;

  /// Whether the user can sort by this column. Defaults to `true`.
  final bool enableSorting;

  /// Whether this column participates in column-level filtering.
  final bool enableFiltering;

  /// Whether this column can enter inline-edit mode on tap.
  final bool enableEditing;

  /// Whether a right-click / long-press context menu is available on cells
  /// in this column.
  final bool enableContextMenu;

  /// Horizontal text alignment inside the cell. Defaults to [TextAlign.start].
  final TextAlign textAlign;

  /// Optional background colour applied to every cell in this column.
  final Color? backgroundColor;

  /// Custom placeholder shown for null/empty values. Falls back to `'—'`
  /// when `null` and [showEmptyAsDash] is `true`.
  final String? emptyCellPlaceholder;

  /// Whether null or empty values are shown as a dash (`'—'`). Defaults to `true`.
  final bool showEmptyAsDash;

  /// Semantic column type used by built-in renderers and the cell context.
  final TablexColumnType type;

  /// Optional footer cell renderer. Receives aggregated row data so you can
  /// render sums, averages, or other column-level stats.
  final Widget Function(TablexFooterContext<dynamic> context)? footerRenderer;

  /// Optional formatter used when exporting this column to CSV, Excel, or PDF.
  ///
  /// Receives the full typed row object, giving access to all fields — not just
  /// this column's raw cell value. Use this when the default resolution chain
  /// does not produce the desired string (e.g. a nested model, a computed label,
  /// or a value derived from multiple fields).
  ///
  /// ```dart
  /// exportFormatter: (employee) => '${employee.firstName} ${employee.lastName}',
  /// ```
  ///
  /// Resolution order:
  /// 1. [exportFormatter] — if provided, its result is always used.
  /// 2. [TablexColumn.formatter] — used when no [exportFormatter] is set.
  /// 3. Enum `.name` — for [Enum] values, the short name is used automatically
  ///    (e.g. `EmployeeStatus.active` → `'active'`).
  /// 4. [Object.toString] — final fallback.
  final String Function(TRow row)? exportFormatter;

  /// The dash (or custom placeholder) rendered for empty cells.
  String get effectivePlaceholder => emptyCellPlaceholder ?? '—';

  /// Returns the widget to render for [row], or `null` to fall back to the
  /// default text renderer.
  Widget? buildCell(TRow row, dynamic rawValue, TablexCellContext context);

  /// Extracts the typed cell value from [row].
  dynamic extractValue(TRow row);

  /// Formats [rawValue] to a display string, or returns `null` to use the
  /// default `toString()`.
  String? formatValueRaw(dynamic rawValue);

  /// Called by the grid after the user commits an inline edit.
  ///
  /// Override in concrete column classes to fire a typed [onEdit] callback.
  /// The default implementation is a no-op.
  void handleEdit(TRow row, dynamic newValue) {}

  /// Returns a custom edit widget for this cell, or `null` to fall back to
  /// the type-appropriate default editor (TextField, numeric keyboard, etc.).
  ///
  /// [onSubmit] must be called with the new value to commit the edit.
  /// [onCancel] must be called to discard it.
  Widget? buildEditCell(
    BuildContext context,
    TRow row,
    dynamic currentValue,
    void Function(dynamic) onSubmit,
    VoidCallback onCancel,
  ) =>
      null;
}

/// A strongly-typed column descriptor.
///
/// `TRow` is your domain model type; `TValue` is the type of the value
/// extracted from each row for this column.
///
/// ```dart
/// TablexColumn<Employee, String>(
///   fieldKey: 'name',
///   title: 'Name',
///   valueGetter: (e) => e.name,
///   cellRenderer: TablexRenderers.avatarTwoLine(
///     secondLine: (e) => e.department,
///     avatar: (e) => NetworkImage(e.avatarUrl),
///   ),
/// )
/// ```
///
/// The [cellRenderer] callback is optional. When omitted the grid uses a
/// plain text renderer that calls [formatter] (or `value.toString()`).
class TablexColumn<TRow, TValue> extends TablexColumnBase<TRow> {
  const TablexColumn({
    required super.fieldKey,
    required super.title,
    required this.valueGetter,
    this.cellRenderer,
    this.formatter,
    this.onEdit,
    this.editRenderer,
    super.width,
    super.minWidth = 100,
    super.frozen = TablexColumnFrozen.none,
    super.hide = false,
    super.hideIfEmpty = false,
    super.enableSorting = true,
    super.enableFiltering = true,
    super.enableEditing = false,
    super.enableContextMenu = true,
    super.textAlign = TextAlign.start,
    super.backgroundColor,
    super.emptyCellPlaceholder,
    super.showEmptyAsDash = true,
    super.type = TablexColumnType.text,
    super.footerRenderer,
    super.exportFormatter,
  });

  /// Extracts the typed value from a row object.
  final TValue Function(TRow row) valueGetter;

  /// Optional custom cell widget. Receives the full row, the typed value (which
  /// may be `null` when the backend omits the field), and a [TablexCellContext]
  /// with layout/state metadata. Return `null` to fall back to the default text
  /// renderer.
  ///
  /// Use [TablexRenderers] for ready-made renderers (currency, status chip,
  /// identifier, actions, …).
  final Widget Function(TRow row, TValue? value, TablexCellContext context)?
      cellRenderer;

  /// Optional value-to-string formatter used when no [cellRenderer] is set.
  /// Falls back to `value.toString()` when both are `null`.
  final String Function(TValue value)? formatter;

  /// Called after the user commits an inline edit. The grid has already
  /// updated the cell display; use this to persist the change to your backend
  /// or local state. Requires [enableEditing] to be `true`.
  final void Function(TRow row, TValue newValue)? onEdit;

  /// Custom edit-mode widget. Supply this to replace the default type-based
  /// editor (TextField, numeric keyboard, etc.) for this column.
  ///
  /// Call [onSubmit] with the accepted value, or [onCancel] to discard.
  /// Requires [enableEditing] to be `true`.
  final Widget Function(
    BuildContext context,
    TRow row,
    TValue currentValue,
    void Function(TValue) onSubmit,
    VoidCallback onCancel,
  )? editRenderer;

  @override
  TValue extractValue(TRow row) => valueGetter(row);

  @override
  Widget? buildCell(TRow row, dynamic rawValue, TablexCellContext context) {
    if (cellRenderer == null) return null;
    return cellRenderer!(row, extractValue(row), context);
  }

  @override
  String? formatValueRaw(dynamic rawValue) {
    if (formatter == null) return null;
    return formatter!(rawValue as TValue);
  }

  @override
  void handleEdit(TRow row, dynamic newValue) {
    if (onEdit != null && newValue is TValue) {
      onEdit!(row, newValue);
    }
  }

  @override
  Widget? buildEditCell(
    BuildContext context,
    TRow row,
    dynamic currentValue,
    void Function(dynamic) onSubmit,
    VoidCallback onCancel,
  ) {
    if (editRenderer == null) return null;
    return editRenderer!(
      context,
      row,
      currentValue is TValue ? currentValue : extractValue(row),
      (v) => onSubmit(v),
      onCancel,
    );
  }
}

/// Groups one or more columns under a shared spanning header label.
///
/// Exactly one of [fields] or [children] must be provided:
/// - [fields] — a flat list of [TablexColumnBase.fieldKey] values to group.
/// - [children] — nested [TablexColumnGroup]s for multi-level headers.
///
/// ```dart
/// columnGroups: [
///   TablexColumnGroup(title: 'Personal', fields: ['name', 'dob']),
///   TablexColumnGroup(title: 'Employment', fields: ['role', 'salary']),
/// ]
/// ```
class TablexColumnGroup {
  const TablexColumnGroup({
    required this.title,
    this.fields,
    this.children,
    this.backgroundColor,
    this.titleTextAlign = TextAlign.center,
  }) : assert(
          (fields == null) != (children == null),
          'Exactly one of fields or children must be set',
        );

  /// Spanning header label.
  final String title;

  /// Field keys of the columns that fall under this group.
  /// Mutually exclusive with [children].
  final List<String>? fields;

  /// Nested sub-groups for multi-level column headers.
  /// Mutually exclusive with [fields].
  final List<TablexColumnGroup>? children;

  /// Background colour for the group header cell.
  final Color? backgroundColor;

  /// Text alignment of [title] inside the group header cell.
  final TextAlign titleTextAlign;
}
