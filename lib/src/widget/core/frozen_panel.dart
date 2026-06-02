import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../controller/controller.dart';
import '../../model/column.dart';
import '../../model/enums.dart';
import '../../model/query.dart';
import '../../model/row.dart';
import '../../theme/grid_theme_data.dart' show TablexThemeData;
import 'cell_widget.dart';

/// A horizontally-fixed panel of frozen (pinned) columns.
///
/// Renders the header row and data rows for columns whose
/// [TablexColumnBase.frozen] is [TablexColumnFrozen.start] or
/// [TablexColumnFrozen.end].
///
/// The panel's vertical scroll position is kept in sync with the main body by
/// the parent widget: [verticalController] is jumped to match the main scroll.
/// Pointer scroll and touch drag events on the panel are forwarded to
/// [mainVerticalController] so the user can scroll by interacting with the
/// frozen area.
///
/// [shadowOnTrailingEdge] controls the shadow direction for RTL-aware
/// visual separation:
/// * `true` — shadow on the trailing edge — use for frozen-start panels.
/// * `false` — shadow on the leading edge — use for frozen-end panels.
class TablexFrozenPanel<TRow> extends StatelessWidget {
  const TablexFrozenPanel({
    super.key,
    required this.columns,
    required this.controller,
    required this.columnWidths,
    required this.hiddenFields,
    required this.sort,
    required this.density,
    required this.theme,
    required this.verticalController,
    required this.mainVerticalController,
    required this.shadowOnTrailingEdge,
    required this.showHeader,
    required this.onSort,
    this.onResizeUpdate,
    this.selectionMode = TablexSelectionMode.none,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onSelectionChanged,
  });

  final List<TablexColumnBase<TRow>> columns;
  final TablexController<TRow> controller;
  final Map<String, double> columnWidths;
  final Set<String> hiddenFields;
  final TablexColumnSort? sort;
  final TablexDensity density;
  final TablexThemeData theme;
  final ScrollController verticalController;
  final ScrollController mainVerticalController;
  final bool shadowOnTrailingEdge;
  final bool showHeader;
  final void Function(String field, TablexColumnSort? sort) onSort;
  final void Function(String field, double width)? onResizeUpdate;
  final TablexSelectionMode selectionMode;
  final void Function(TRow)? onRowTap;
  final void Function(TRow)? onRowDoubleTap;
  final void Function(List<TRow>)? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final visible = columns
        .where((c) => !c.hide && !hiddenFields.contains(c.fieldKey))
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final totalWidth = visible.fold<double>(
      0.0,
      (sum, col) => sum + (columnWidths[col.fieldKey] ?? col.width ?? 150.0),
    );

    // Shadow toward the scrollable area: trailing edge in LTR = positive X,
    // leading edge in LTR = negative X. RTL inverts.
    final shadowOffsetX = shadowOnTrailingEdge
        ? (direction == TextDirection.ltr ? 4.0 : -4.0)
        : (direction == TextDirection.ltr ? -4.0 : 4.0);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final rows = controller.rows;

        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                offset: Offset(shadowOffsetX, 0),
                blurRadius: 6,
              ),
            ],
          ),
          child: SizedBox(
            width: totalWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader)
                  _FrozenPanelHeader<TRow>(
                    visible: visible,
                    columnWidths: columnWidths,
                    sort: sort,
                    density: density,
                    theme: theme,
                    onSort: onSort,
                    onResizeUpdate: onResizeUpdate,
                  ),
                Expanded(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent &&
                          mainVerticalController.hasClients) {
                        mainVerticalController.jumpTo(
                          (mainVerticalController.offset + event.scrollDelta.dy)
                              .clamp(
                            0.0,
                            mainVerticalController.position.maxScrollExtent,
                          ),
                        );
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: (details) {
                        if (!mainVerticalController.hasClients) return;
                        mainVerticalController.jumpTo(
                          (mainVerticalController.offset - details.delta.dy)
                              .clamp(
                            0.0,
                            mainVerticalController.position.maxScrollExtent,
                          ),
                        );
                      },
                      child: ListView.builder(
                        controller: verticalController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rows.length,
                        itemExtent: density.rowHeight,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          final isSelected = controller.isSelected(row.data);
                          return RepaintBoundary(
                            child: _FrozenBodyRow<TRow>(
                              key: ValueKey('fp_${row.key}'),
                              row: row,
                              rowIndex: index,
                              visible: visible,
                              columnWidths: columnWidths,
                              isSelected: isSelected,
                              density: density,
                              theme: theme,
                              selectionMode: selectionMode,
                              onToggleSelection: () {
                                controller.toggleRowSelection(row.data);
                                onSelectionChanged
                                    ?.call(controller.selectedRows);
                              },
                              onRowTap: onRowTap,
                              onRowDoubleTap: onRowDoubleTap,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Frozen panel header row
// ---------------------------------------------------------------------------

class _FrozenPanelHeader<TRow> extends StatelessWidget {
  const _FrozenPanelHeader({
    required this.visible,
    required this.columnWidths,
    required this.sort,
    required this.density,
    required this.theme,
    required this.onSort,
    this.onResizeUpdate,
  });

  final List<TablexColumnBase<TRow>> visible;
  final Map<String, double> columnWidths;
  final TablexColumnSort? sort;
  final TablexDensity density;
  final TablexThemeData theme;
  final void Function(String field, TablexColumnSort? sort) onSort;
  final void Function(String field, double width)? onResizeUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: density.headerHeight,
      color: theme.headerBackgroundColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: visible.map((col) {
          final w = columnWidths[col.fieldKey] ?? col.width ?? 150.0;
          return _FrozenHeaderCell<TRow>(
            key: ValueKey('fph_${col.fieldKey}'),
            column: col,
            width: w,
            sort: sort,
            theme: theme,
            density: density,
            onSort: onSort,
            onResizeUpdate: onResizeUpdate,
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single frozen header cell — sort + resize, no drag-to-reorder
// ---------------------------------------------------------------------------

class _FrozenHeaderCell<TRow> extends StatefulWidget {
  const _FrozenHeaderCell({
    super.key,
    required this.column,
    required this.width,
    required this.sort,
    required this.theme,
    required this.density,
    required this.onSort,
    this.onResizeUpdate,
  });

  final TablexColumnBase<TRow> column;
  final double width;
  final TablexColumnSort? sort;
  final TablexThemeData theme;
  final TablexDensity density;
  final void Function(String field, TablexColumnSort? sort) onSort;
  final void Function(String field, double width)? onResizeUpdate;

  @override
  State<_FrozenHeaderCell<TRow>> createState() =>
      _FrozenHeaderCellState<TRow>();
}

class _FrozenHeaderCellState<TRow> extends State<_FrozenHeaderCell<TRow>> {
  double _resizeDragStartX = 0;
  double _resizeStartWidth = 0;

  @override
  Widget build(BuildContext context) {
    final col = widget.column;
    final direction = Directionality.of(context);
    final isSorted = widget.sort?.field == col.fieldKey;
    final isAsc = widget.sort?.direction == TablexSortDirection.ascending;

    return SizedBox(
      width: widget.width,
      height: widget.density.headerHeight,
      child: Stack(
        children: [
          GestureDetector(
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
                    widget.onSort(col.fieldKey, next);
                  }
                : null,
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
                  final newWidth = (_resizeStartWidth + delta * sign).clamp(
                    col.minWidth,
                    double.infinity,
                  );
                  widget.onResizeUpdate!(col.fieldKey, newWidth);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child:
                      SizedBox(width: 6, height: widget.density.headerHeight),
                ),
              ),
            ),
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
}

// ---------------------------------------------------------------------------
// Frozen body row — hover state, selection, row tap
// ---------------------------------------------------------------------------

class _FrozenBodyRow<TRow> extends StatefulWidget {
  const _FrozenBodyRow({
    super.key,
    required this.row,
    required this.rowIndex,
    required this.visible,
    required this.columnWidths,
    required this.isSelected,
    required this.density,
    required this.theme,
    required this.selectionMode,
    required this.onToggleSelection,
    this.onRowTap,
    this.onRowDoubleTap,
  });

  final TablexRow<TRow> row;
  final int rowIndex;
  final List<TablexColumnBase<TRow>> visible;
  final Map<String, double> columnWidths;
  final bool isSelected;
  final TablexDensity density;
  final TablexThemeData theme;
  final TablexSelectionMode selectionMode;
  final VoidCallback onToggleSelection;
  final void Function(TRow)? onRowTap;
  final void Function(TRow)? onRowDoubleTap;

  @override
  State<_FrozenBodyRow<TRow>> createState() => _FrozenBodyRowState<TRow>();
}

class _FrozenBodyRowState<TRow> extends State<_FrozenBodyRow<TRow>> {
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
          mainAxisSize: MainAxisSize.min,
          children: widget.visible.map((col) {
            final w = widget.columnWidths[col.fieldKey] ?? col.width ?? 150.0;
            return TablexCellWidget<TRow>(
              key: ValueKey('fp_${row.key}_${col.fieldKey}'),
              column: col,
              row: row,
              rowIndex: index,
              isHovered: _isHovered,
              isSelected: widget.isSelected,
              isEditing: false,
              density: widget.density,
              theme: widget.theme,
              width: w,
            );
          }).toList(),
        ),
      ),
    );
  }
}
