import 'package:flutter/material.dart';
import '../../controller/controller.dart';
import '../../controller/state.dart';
import '../../model/column.dart';
import '../../model/enums.dart';
import '../../model/row.dart';
import '../../theme/grid_theme_data.dart' show TablexThemeData, TablexCheckboxTheme;
import '../../../i18n/strings.g.dart';
import 'cell_widget.dart';

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
                  onEditConfirm: (field, _) =>
                      controller.confirmEdit(index, field),
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
              final w =
                  widget.columnWidths[col.fieldKey] ?? col.width ?? 150.0;
              final isEditing = widget.state.editingRowIndex == index &&
                  widget.state.editingField == col.fieldKey;
              return TablexCellWidget<TRow>(
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
              );
            }),
          ],
        ),
      ),
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
    );
  }
}
