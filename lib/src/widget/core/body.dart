import 'package:flutter/material.dart';
import '../../controller/controller.dart';
import '../../controller/state.dart';
import '../../model/column.dart';
import '../../model/enums.dart';
import '../../model/row.dart';
import '../../theme/grid_theme_data.dart'
    show TablexThemeData, TablexCheckboxTheme;
import '../../../i18n/strings.g.dart';
import 'cell_widget.dart';

typedef _RowNavigateCallback = void Function(
    String field, dynamic value, TablexEditDirection direction);

const double _kCheckboxWidth = 48.0;

class TablexBody<TRow> extends StatelessWidget {
  const TablexBody({
    super.key,
    required this.controller,
    required this.columns,
    required this.density,
    required this.theme,
    required this.selectionMode,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onSelectionChanged,
    this.noDataWidget,
  });

  final TablexController<TRow> controller;
  final List<TablexColumnBase<TRow>> columns;
  final TablexDensity density;
  final TablexThemeData theme;
  final TablexSelectionMode selectionMode;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final void Function(TRow)? onRowTap;
  final void Function(TRow)? onRowDoubleTap;
  final void Function(List<TRow>)? onSelectionChanged;
  final Widget? noDataWidget;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final rows = controller.rows;
        if (rows.isEmpty) {
          return Center(
            child: noDataWidget ??
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    tablexStrings(context).noData,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
          );
        }

        final state = controller.state;
        final hiddenFields = state.hiddenColumnFields;
        final columnWidths = state.columnWidths;
        final visible = columns
            .where((c) => !c.hide && !hiddenFields.contains(c.fieldKey))
            .toList();

        final showCheckboxes = selectionMode == TablexSelectionMode.multiple;

        final totalWidth = visible.fold<double>(
          showCheckboxes ? _kCheckboxWidth : 0.0,
          (sum, col) =>
              sum + (columnWidths[col.fieldKey] ?? col.width ?? 150.0),
        );

        final verticalList = Scrollbar(
          controller: verticalScrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: verticalScrollController,
            itemCount: rows.length,
            itemExtent: density.rowHeight,
            itemBuilder: (context, index) {
              final row = rows[index];
              final isSelected = controller.isSelected(row.data);
              return RepaintBoundary(
                child: _TablexBodyRow<TRow>(
                  key: ValueKey(row.key),
                  row: row,
                  rowIndex: index,
                  visible: visible,
                  columnWidths: columnWidths,
                  state: state,
                  showCheckboxes: showCheckboxes,
                  isSelected: isSelected,
                  density: density,
                  theme: theme,
                  selectionMode: selectionMode,
                  onRowTap: onRowTap,
                  onRowDoubleTap: onRowDoubleTap,
                  onToggleSelection: () {
                    controller.toggleRowSelection(row.data);
                    onSelectionChanged?.call(controller.selectedRows);
                  },
                  onBeginEdit: (field) => controller.beginEdit(index, field),
                  onCancelEdit: controller.cancelEdit,
                  onEditConfirm: (field, newValue) {
                    _commitEdit(
                      controller: controller,
                      visible: visible,
                      rows: rows,
                      rowIndex: index,
                      field: field,
                      newValue: newValue,
                    );
                  },
                  onNavigate: (field, newValue, direction) {
                    _commitEdit(
                      controller: controller,
                      visible: visible,
                      rows: rows,
                      rowIndex: index,
                      field: field,
                      newValue: newValue,
                    );
                    final newRow = _resolveNavTarget(
                      controller: controller,
                      visible: visible,
                      rowIndex: index,
                      field: field,
                      direction: direction,
                    );
                    if (newRow != null) {
                      controller.beginEdit(newRow.$1, newRow.$2);
                      _scrollToRow(
                        rowIndex: newRow.$1,
                        density: density,
                        scrollController: verticalScrollController,
                      );
                    }
                  },
                ),
              );
            },
          ),
        );

        return Scrollbar(
          controller: horizontalScrollController,
          thumbVisibility: true,
          notificationPredicate: (n) => n.depth == 1,
          child: SingleChildScrollView(
            controller: horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: totalWidth, child: verticalList),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Per-row widget — owns its own hover state so hover never touches the
// controller and never triggers a global list rebuild.
// ============================================================================

class _TablexBodyRow<TRow> extends StatefulWidget {
  const _TablexBodyRow({
    super.key,
    required this.row,
    required this.rowIndex,
    required this.visible,
    required this.columnWidths,
    required this.state,
    required this.showCheckboxes,
    required this.isSelected,
    required this.density,
    required this.theme,
    required this.selectionMode,
    required this.onToggleSelection,
    required this.onEditConfirm,
    required this.onBeginEdit,
    required this.onCancelEdit,
    required this.onNavigate,
    this.onRowTap,
    this.onRowDoubleTap,
  });

  final TablexRow<TRow> row;
  final int rowIndex;
  final List<TablexColumnBase<TRow>> visible;
  final Map<String, double> columnWidths;
  final TablexState<TRow> state;
  final bool showCheckboxes;
  final bool isSelected;
  final TablexDensity density;
  final TablexThemeData theme;
  final TablexSelectionMode selectionMode;
  final VoidCallback onToggleSelection;
  final void Function(String field, dynamic value) onEditConfirm;
  final void Function(String field) onBeginEdit;
  final VoidCallback onCancelEdit;
  final _RowNavigateCallback onNavigate;
  final void Function(TRow)? onRowTap;
  final void Function(TRow)? onRowDoubleTap;

  @override
  State<_TablexBodyRow<TRow>> createState() => _TablexBodyRowState<TRow>();
}

class _TablexBodyRowState<TRow> extends State<_TablexBodyRow<TRow>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final index = widget.rowIndex;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // In multiple mode selection is handled exclusively by the checkbox.
        onTap: () {
          if (widget.selectionMode == TablexSelectionMode.single) {
            widget.onToggleSelection();
          }
          widget.onRowTap?.call(row.data);
        },
        onDoubleTap: widget.onRowDoubleTap != null
            ? () => widget.onRowDoubleTap!.call(row.data)
            : null,
        child: Row(
          children: [
            if (widget.showCheckboxes)
              _RowCheckbox(
                isSelected: widget.isSelected,
                isHovered: _isHovered,
                rowIndex: index,
                density: widget.density,
                theme: widget.theme,
                onTap: widget.onToggleSelection,
              ),
            ...widget.visible.map((col) {
              final w = widget.columnWidths[col.fieldKey] ?? col.width ?? 150.0;
              final isEditing = widget.state.editingRowIndex == index &&
                  widget.state.editingField == col.fieldKey;

              Widget cell = TablexCellWidget<TRow>(
                key: ValueKey('${row.key}_${col.fieldKey}'),
                column: col,
                row: row,
                rowIndex: index,
                isHovered: _isHovered,
                isSelected: widget.isSelected,
                isEditing: isEditing,
                density: widget.density,
                theme: widget.theme,
                width: w,
                onEditConfirm: isEditing
                    ? (v) => widget.onEditConfirm(col.fieldKey, v)
                    : null,
                onEditCancel: isEditing ? widget.onCancelEdit : null,
                onNavigate: isEditing
                    ? (v, dir) => widget.onNavigate(col.fieldKey, v, dir)
                    : null,
              );

              if (col.enableEditing && !isEditing) {
                if (col.type == TablexColumnType.boolean) {
                  // Boolean: single tap toggles immediately.
                  final current = row.cells[col.fieldKey];
                  cell = GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onEditConfirm(
                        col.fieldKey, !(current as bool? ?? false)),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: cell,
                    ),
                  );
                } else {
                  // All other types: double-tap to enter edit mode.
                  cell = GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () => widget.onBeginEdit(col.fieldKey),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.text,
                      child: cell,
                    ),
                  );
                }
              }

              return cell;
            }),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Edit-navigation helpers
// ============================================================================

/// Commits an in-progress edit: updates the cell, fires the column callback,
/// and clears edit mode.
void _commitEdit<TRow>({
  required TablexController<TRow> controller,
  required List<TablexColumnBase<TRow>> visible,
  required List<TablexRow<TRow>> rows,
  required int rowIndex,
  required String field,
  required dynamic newValue,
}) {
  controller.updateCell(rowIndex, field, newValue);
  final col = visible.firstWhere((c) => c.fieldKey == field,
      orElse: () => visible.first);
  col.handleEdit(rows[rowIndex].data, newValue);
  controller.confirmEdit(rowIndex, field);
}

/// Computes the next (rowIndex, fieldKey) to enter edit mode after a
/// navigation key, or returns null if navigation goes out of bounds.
(int, String)? _resolveNavTarget<TRow>({
  required TablexController<TRow> controller,
  required List<TablexColumnBase<TRow>> visible,
  required int rowIndex,
  required String field,
  required TablexEditDirection direction,
}) {
  // Boolean columns toggle on tap and never enter text-edit mode.
  final editable = visible
      .where((c) => c.enableEditing && c.type != TablexColumnType.boolean)
      .toList();
  if (editable.isEmpty) return null;

  final colIdx = editable.indexWhere((c) => c.fieldKey == field);
  final lastCol = editable.length - 1;
  final lastRow = controller.rowCount - 1;

  return switch (direction) {
    TablexEditDirection.tabForward => colIdx < lastCol
        ? (rowIndex, editable[colIdx + 1].fieldKey)
        : rowIndex < lastRow
            ? (rowIndex + 1, editable.first.fieldKey)
            : null,
    TablexEditDirection.tabBackward => colIdx > 0
        ? (rowIndex, editable[colIdx - 1].fieldKey)
        : rowIndex > 0
            ? (rowIndex - 1, editable.last.fieldKey)
            : null,
    TablexEditDirection.arrowDown =>
      rowIndex < lastRow ? (rowIndex + 1, field) : null,
    TablexEditDirection.arrowUp => rowIndex > 0 ? (rowIndex - 1, field) : null,
  };
}

/// Scrolls the vertical list so the row at [rowIndex] is fully visible.
void _scrollToRow({
  required int rowIndex,
  required TablexDensity density,
  required ScrollController scrollController,
}) {
  if (!scrollController.hasClients) return;
  final position = scrollController.position;
  final rowTop = rowIndex * density.rowHeight;
  final rowBottom = rowTop + density.rowHeight;
  final viewTop = position.pixels;
  final viewBottom = viewTop + position.viewportDimension;

  if (rowTop < viewTop) {
    scrollController.animateTo(
      rowTop.clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  } else if (rowBottom > viewBottom) {
    scrollController.animateTo(
      (rowBottom - position.viewportDimension)
          .clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }
}

// ============================================================================
// Per-row checkbox cell
// ============================================================================

class _RowCheckbox extends StatelessWidget {
  const _RowCheckbox({
    required this.isSelected,
    required this.isHovered,
    required this.rowIndex,
    required this.density,
    required this.theme,
    required this.onTap,
  });

  final bool isSelected;
  final bool isHovered;
  final int rowIndex;
  final TablexDensity density;
  final TablexThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? theme.rowSelectedColor
        : isHovered
            ? theme.rowHoverColor
            : (rowIndex.isEven ? theme.rowEvenColor : theme.rowOddColor);

    final cb = theme.checkboxTheme ?? const TablexCheckboxTheme();
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      // opaque so this gesture wins over the outer row GestureDetector —
      // clicking the checkbox does not trigger onRowTap.
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: _kCheckboxWidth,
        height: density.rowHeight,
        color: bgColor,
        child: Center(
          child: IgnorePointer(
            child: Container(
              decoration: isSelected && cb.doubleBorder
                  ? BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(cb.borderRadius ?? 3),
                      border: Border.all(
                        width: 1,
                        color: cb.activeColor ?? cs.primary,
                      ),
                      shape: BoxShape.rectangle,
                    )
                  : null,
              width: cb.size + 5,
              height: cb.size + 5,
              child: SizedBox(
                width: cb.size,
                height: cb.size,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) {},
                  activeColor: cb.activeColor ?? cs.primary,
                  checkColor: cb.checkColor ?? cs.onPrimary,
                  side: BorderSide(
                    color: cb.borderColor ?? cs.outlineVariant,
                    width: cb.borderWidth,
                  ),
                  shape: cb.shape,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
