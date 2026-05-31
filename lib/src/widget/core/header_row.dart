import 'package:flutter/material.dart';
import '../../model/column.dart';
import '../../model/enums.dart';
import '../../model/query.dart';
import '../../theme/grid_theme_data.dart'
    show TablexThemeData, TablexCheckboxTheme;

const double _kCheckboxWidth = 48.0;

class TablexHeaderRow<TRow> extends StatelessWidget {
  const TablexHeaderRow({
    super.key,
    required this.columns,
    required this.columnWidths,
    required this.hiddenFields,
    required this.sort,
    required this.density,
    required this.theme,
    required this.onSort,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    this.onReorder,
    this.selectionMode = TablexSelectionMode.none,
    this.selectedCount = 0,
    this.totalCount = 0,
    this.onSelectAll,
    this.onDeselectAll,
  });

  final List<TablexColumnBase<TRow>> columns;
  final Map<String, double> columnWidths;
  final Set<String> hiddenFields;
  final TablexColumnSort? sort;
  final TablexDensity density;
  final TablexThemeData theme;
  final void Function(String field, TablexColumnSort? sort) onSort;
  final void Function(String field, double width)? onResizeUpdate;
  final void Function(String field, double width)? onResizeEnd;
  // fromField dragged onto toField's position
  final void Function(String fromField, String toField)? onReorder;
  final TablexSelectionMode selectionMode;
  final int selectedCount;
  final int totalCount;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;

  @override
  Widget build(BuildContext context) {
    final visible = columns
        .where((c) => !c.hide && !hiddenFields.contains(c.fieldKey))
        .toList();

    final showCheckbox = selectionMode == TablexSelectionMode.multiple;

    return Container(
      height: density.headerHeight,
      color: theme.headerBackgroundColor,
      child: Row(
        children: [
          if (showCheckbox)
            _CheckboxHeaderCell(
              selectedCount: selectedCount,
              totalCount: totalCount,
              density: density,
              theme: theme,
              onSelectAll: onSelectAll,
              onDeselectAll: onDeselectAll,
            ),
          ...visible.map((col) {
            final w = columnWidths[col.fieldKey] ?? col.width ?? 150.0;
            return _HeaderCell<TRow>(
              key: ValueKey(col.fieldKey),
              column: col,
              width: w,
              sort: sort,
              theme: theme,
              density: density,
              onSort: onSort,
              onResizeUpdate: onResizeUpdate,
              onResizeEnd: onResizeEnd,
              onReorder: onReorder,
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tri-state select-all checkbox in the header
// ---------------------------------------------------------------------------

class _CheckboxHeaderCell extends StatelessWidget {
  const _CheckboxHeaderCell({
    required this.selectedCount,
    required this.totalCount,
    required this.density,
    required this.theme,
    this.onSelectAll,
    this.onDeselectAll,
  });

  final int selectedCount;
  final int totalCount;
  final TablexDensity density;
  final TablexThemeData theme;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;

  @override
  Widget build(BuildContext context) {
    final bool? checkboxValue = selectedCount == 0
        ? false
        : selectedCount == totalCount
            ? true
            : null; // null → indeterminate

    final cb = theme.checkboxTheme ?? const TablexCheckboxTheme();
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (selectedCount == totalCount) {
          onDeselectAll?.call();
        } else {
          onSelectAll?.call();
        }
      },
      child: Container(
        width: _kCheckboxWidth,
        height: density.headerHeight,
        color: theme.headerBackgroundColor,
        child: Center(
          child: IgnorePointer(
            child: SizedBox(
              width: cb.size,
              height: cb.size,
              child: Checkbox(
                value: checkboxValue,
                tristate: true,
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

// ---------------------------------------------------------------------------
// Single header cell — supports sort, resize, and drag-to-reorder
// ---------------------------------------------------------------------------

class _HeaderCell<TRow> extends StatefulWidget {
  const _HeaderCell({
    super.key,
    required this.column,
    required this.width,
    required this.sort,
    required this.theme,
    required this.density,
    required this.onSort,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    this.onReorder,
  });

  final TablexColumnBase<TRow> column;
  final double width;
  final TablexColumnSort? sort;
  final TablexThemeData theme;
  final TablexDensity density;
  final void Function(String field, TablexColumnSort? sort) onSort;
  final void Function(String field, double width)? onResizeUpdate;
  final void Function(String field, double width)? onResizeEnd;
  final void Function(String fromField, String toField)? onReorder;

  @override
  State<_HeaderCell<TRow>> createState() => _HeaderCellState<TRow>();
}

class _HeaderCellState<TRow> extends State<_HeaderCell<TRow>> {
  double _resizeDragStartX = 0;
  double _resizeStartWidth = 0;

  @override
  Widget build(BuildContext context) {
    final col = widget.column;
    final direction = Directionality.of(context);
    final isSorted = widget.sort?.field == col.fieldKey;
    final isAsc = widget.sort?.direction == TablexSortDirection.ascending;
    final canReorder = widget.onReorder != null;

    // The visual content of the header cell (shared between normal and dragging states)
    Widget headerContent = _buildContent(col, isSorted, isAsc);

    // Wrap in Draggable when reorder is enabled
    Widget draggableContent = canReorder
        ? Draggable<String>(
            data: col.fieldKey,
            feedback: _ReorderFeedback(
              title: col.title,
              width: widget.width,
              height: widget.density.headerHeight,
              theme: widget.theme,
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: headerContent,
            ),
            child: headerContent,
          )
        : headerContent;

    // Wrap in DragTarget to receive drops from other columns
    Widget cell = canReorder
        ? DragTarget<String>(
            onWillAcceptWithDetails: (d) => d.data != col.fieldKey,
            onAcceptWithDetails: (d) =>
                widget.onReorder?.call(d.data, col.fieldKey),
            builder: (ctx, candidateData, _) {
              final isOver = candidateData.isNotEmpty;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  draggableContent,
                  // Drop indicator: accent line on leading edge
                  if (isOver)
                    Positioned(
                      left: direction == TextDirection.ltr ? 0 : null,
                      right: direction == TextDirection.rtl ? 0 : null,
                      top: 4,
                      bottom: 4,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        : draggableContent;

    return SizedBox(
      width: widget.width,
      height: widget.density.headerHeight,
      child: Stack(
        children: [
          cell,
          // Resize handle — only rendered when resize is enabled
          if (widget.onResizeUpdate != null)
            Positioned(
              right: direction == TextDirection.ltr ? 0 : null,
              left: direction == TextDirection.rtl ? 0 : null,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (d) {
                  _resizeDragStartX = d.globalPosition.dx;
                  _resizeStartWidth = widget.width;
                },
                onHorizontalDragUpdate: (d) {
                  final delta = d.globalPosition.dx - _resizeDragStartX;
                  final sign = direction == TextDirection.rtl ? -1.0 : 1.0;
                  final newWidth = (_resizeStartWidth + delta * sign)
                      .clamp(col.minWidth, double.infinity);
                  widget.onResizeUpdate!(col.fieldKey, newWidth);
                },
                onHorizontalDragEnd: (_) =>
                    widget.onResizeEnd?.call(col.fieldKey, widget.width),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child:
                      SizedBox(width: 6, height: widget.density.headerHeight),
                ),
              ),
            ),
          // Bottom border
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Divider(
              height: 1,
              thickness: 1,
              color: widget.theme.borderColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    TablexColumnBase<TRow> col,
    bool isSorted,
    bool isAsc,
  ) {
    return GestureDetector(
      onTap: col.enableSorting
          ? () {
              TablexColumnSort? next;
              if (!isSorted) {
                next = TablexColumnSort(
                  field: col.fieldKey,
                  direction: TablexSortDirection.ascending,
                );
              } else if (isAsc) {
                next = TablexColumnSort(
                  field: col.fieldKey,
                  direction: TablexSortDirection.descending,
                );
              }
              // third click clears sort
              widget.onSort(col.fieldKey, next);
            }
          : null,
      child: MouseRegion(
        cursor: widget.onReorder != null
            ? SystemMouseCursors.grab
            : SystemMouseCursors.basic,
        child: Container(
          width: widget.width,
          height: widget.density.headerHeight,
          padding: widget.theme.headerPadding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  col.title,
                  style: widget.theme.headerTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSorted && col.enableSorting)
                Icon(
                  isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: widget.theme.iconSize,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating drag feedback widget
// ---------------------------------------------------------------------------

class _ReorderFeedback extends StatelessWidget {
  const _ReorderFeedback({
    required this.title,
    required this.width,
    required this.height,
    required this.theme,
  });

  final String title;
  final double width;
  final double height;
  final TablexThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(6),
      color: cs.primaryContainer,
      child: Container(
        width: width,
        height: height,
        padding: theme.headerPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.primary.withAlpha(100)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style:
                theme.headerTextStyle?.copyWith(color: cs.onPrimaryContainer),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
