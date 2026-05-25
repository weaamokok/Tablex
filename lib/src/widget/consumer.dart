import 'package:flutter/material.dart';
import '../controller/controller.dart';
import '../model/column.dart';
import '../model/enums.dart';
import '../model/response.dart';
import '../model/row.dart';
import '../theme/grid_theme.dart';
import '../theme/grid_theme_data.dart';
import 'core/filter_bar.dart';
import 'pagination/pagination_footer.dart' show TablexFooterBuilder;
import 'selection/selection_summary_bar.dart';
import 'tablex_widget.dart';

/// The recommended top-level widget for server-paginated data grids.
///
/// `TablexConsumer` wraps [Tablex.lazyPaged] and adds:
/// - A rounded, bordered container.
/// - An optional [tableHeader] and [tableFilter] slot above the grid.
/// - An automatic [TablexFilterBar] that renders filter chips when the last
///   fetch returned server-side filter metadata.
/// - An optional selection summary bar at the bottom with bulk-action buttons.
///
/// A [TablexController] is created and disposed automatically. Pass your own
/// via [controller] if you need to drive the grid from outside — for example
/// to call [TablexController.refresh] after a save operation.
///
/// ## Minimal usage
///
/// ```dart
/// TablexConsumer<Employee>(
///   columns: [
///     TablexColumn(
///       fieldKey: 'name', title: 'Name',
///       valueGetter: (e) => e.name,
///     ),
///     TablexColumn(
///       fieldKey: 'salary', title: 'Salary',
///       valueGetter: (e) => e.salary,
///       cellRenderer: TablexRenderers.currency(),
///     ),
///   ],
///   fetchTask: (query) async {
///     final resp = await api.getEmployees(page: query.page);
///     return TablexFetchResult(rows: resp.items, totalRows: resp.total);
///   },
/// )
/// ```
class TablexConsumer<T> extends StatefulWidget {
  const TablexConsumer({
    super.key,
    required this.columns,
    required this.fetchTask,
    this.controller,
    this.rowBuilder,
    this.tableHeader,
    this.tableFilter,
    this.initialPageSize = 13,
    this.paginationKey,
    this.selectionMode = TablexSelectionMode.none,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onSelectionChanged,
    this.showHeader = true,
    this.enableColumnResize = true,
    this.enableColumnReorder = false,
    this.fetchWithSorting = true,
    this.fetchWithFiltering = true,
    this.tableHeight,
    this.noDataWidget,
    this.loadingBuilder,
    this.errorBuilder,
    this.hideEmptyColumns = false,
    this.showSelectionSummary = false,
    this.selectionSummaryBuilder,
    this.selectionActions,
    this.includeClearSelectionAction = true,
    this.margin = const EdgeInsets.all(0),
    this.columnGroups,
    this.enablePageJump = false,
    this.footerBuilder,
    this.theme,
  });

  /// Column definitions. See [TablexColumn] and [TablexRenderers].
  final List<TablexColumnBase<T>> columns;

  /// Async callback that fetches a page of data. Called whenever the query
  /// changes (page, sort, filters, params). See [TablexFetchTask].
  final TablexFetchTask<T> fetchTask;

  /// Optional external controller. When `null` the widget creates and disposes
  /// its own controller automatically.
  final TablexController<T>? controller;

  /// Converts a domain object into a [TablexRow]. When `null` the widget
  /// auto-builds rows by calling [TablexColumnBase.extractValue] for each
  /// column — sufficient for most cases.
  final TablexRow<T> Function(T)? rowBuilder;

  /// Optional widget rendered above the filter bar (e.g. a title bar with
  /// export / refresh buttons).
  final Widget? tableHeader;

  /// Optional widget rendered between [tableHeader] and the filter bar (e.g.
  /// a search field or custom filter controls).
  final Widget? tableFilter;

  /// Rows per page on the initial fetch. Defaults to 13.
  final int initialPageSize;

  /// Optional [Key] for the pagination footer widget. Useful when you embed
  /// multiple consumers and need stable widget identities.
  final Key? paginationKey;

  /// Row-selection mode. Defaults to [TablexSelectionMode.none].
  final TablexSelectionMode selectionMode;

  /// Called when the user taps a row (after toggling selection if applicable).
  final void Function(T)? onRowTap;

  /// Called when the user double-taps a row.
  final void Function(T)? onRowDoubleTap;

  /// Called whenever the selection set changes.
  final void Function(List<T>)? onSelectionChanged;

  /// Whether the column header row is visible. Defaults to `true`.
  final bool showHeader;

  /// Whether columns can be resized by dragging the header edge. Defaults to `true`.
  final bool enableColumnResize;

  /// Whether columns can be reordered by dragging the header. Defaults to `false`.
  final bool enableColumnReorder;

  /// Whether sort changes are forwarded to [fetchTask] via [TablexQuery.sort].
  /// Defaults to `true`.
  final bool fetchWithSorting;

  /// Whether column filter changes are forwarded to [fetchTask] via
  /// [TablexQuery.filters]. Defaults to `true`.
  final bool fetchWithFiltering;

  /// Fixed pixel height of the grid. When `null` the grid expands to fill its
  /// parent's height (typical for full-screen tables).
  final double? tableHeight;

  /// Widget shown when [fetchTask] returns zero rows. Defaults to a centred
  /// "No data" text.
  final Widget? noDataWidget;

  /// First-load skeleton configuration. When provided, the grid pre-populates
  /// with [TablexLoadingBuilder.skeletonData] and wraps the table with
  /// [TablexLoadingBuilder.builder] until the first real fetch completes.
  final TablexLoadingBuilder<T>? loadingBuilder;

  /// Widget builder called when [fetchTask] throws. Replaces the grid entirely
  /// so you can show a retry button or an error illustration.
  final TablexErrorBuilder? errorBuilder;

  /// Whether to collapse columns whose values are all empty for the current
  /// page. Defaults to `false`.
  final bool hideEmptyColumns;

  /// Whether to show the selection count summary bar at the bottom when rows
  /// are selected. Defaults to `false`.
  final bool showSelectionSummary;

  /// Custom builder for the selection summary bar. When `null` the default
  /// [TablexSelectionSummaryBar] is used.
  ///
  /// Receives the currently selected items and a `clearSelection` callback —
  /// the same signature as [TablexSelectionSummaryBuilder] on [Tablex].
  final TablexSelectionSummaryBuilder<T>? selectionSummaryBuilder;

  /// Action buttons rendered inside the default selection summary bar.
  final List<TablexSelectionAction<T>>? selectionActions;

  /// Whether the built-in "Clear" button is shown in the default summary bar.
  /// Defaults to `true`.
  final bool includeClearSelectionAction;

  /// Outer margin around the entire widget. Defaults to zero.
  final EdgeInsetsGeometry margin;

  /// Optional column group headers spanning multiple columns.
  final List<TablexColumnGroup>? columnGroups;

  /// Per-widget theme override. Takes precedence over [TablexTheme] and the
  /// Material 3 defaults.
  final TablexThemeData? theme;

  /// Whether the current-page indicator in the pagination footer is editable,
  /// allowing the user to type a page number and jump directly to it.
  final bool enablePageJump;

  /// Fully replaces the pagination footer with a custom widget.
  ///
  /// Receives a [TablexPaginationInfo] snapshot with the current page state
  /// and navigation callbacks. Return `null` to fall back to the default footer.
  ///
  /// ```dart
  /// footerBuilder: (info) => MyCustomFooter(info: info),
  /// ```
  final TablexFooterBuilder? footerBuilder;

  @override
  State<TablexConsumer<T>> createState() => _TablexConsumerState<T>();
}

class _TablexConsumerState<T> extends State<TablexConsumer<T>> {
  late TablexController<T> _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TablexController<T>();
    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(TablexConsumer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_rebuild);
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TablexController<T>();
      _controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  TablexRow<T> _defaultRowBuilder(T item) {
    final cells = <String, dynamic>{};
    for (final col in widget.columns) {
      cells[col.fieldKey] = col.extractValue(item);
    }
    return TablexRow<T>(data: item, cells: cells);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = (widget.theme ??
            TablexTheme.maybeOf(context) ??
            const TablexThemeData())
        .resolve(context);
    final rowBuilder = widget.rowBuilder ?? _defaultRowBuilder;
    final meta = _controller.state.meta;
    final selectedCount = _controller.selectedRows.length;

    Widget grid = Tablex<T>.lazyPaged(
      columns: widget.columns,
      fetchTask: widget.fetchTask,
      rowBuilder: rowBuilder,
      controller: _controller,
      selectionMode: widget.selectionMode,
      onRowTap: widget.onRowTap,
      onRowDoubleTap: widget.onRowDoubleTap,
      onSelectionChanged: widget.onSelectionChanged,
      showHeader: widget.showHeader,
      enableColumnResize: widget.enableColumnResize,
      fetchWithSorting: widget.fetchWithSorting,
      fetchWithFiltering: widget.fetchWithFiltering,
      hideEmptyColumns: widget.hideEmptyColumns,
      initialPageSize: widget.initialPageSize,
      columnGroups: widget.columnGroups,
      noDataWidget: widget.noDataWidget,
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: widget.errorBuilder,
      paginationKey: widget.paginationKey,
      enablePageJump: widget.enablePageJump,
      footerBuilder: widget.footerBuilder,
      theme: resolvedTheme,
    );

    if (widget.tableHeight != null) {
      grid = SizedBox(height: widget.tableHeight, child: grid);
    }

    return Padding(
      padding: widget.margin,
      child: ClipRRect(
        borderRadius: resolvedTheme.borderRadius,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: resolvedTheme.borderColor ?? Colors.grey.shade300,
            ),
            borderRadius: resolvedTheme.borderRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Table header slot
              if (widget.tableHeader != null) widget.tableHeader!,
              // Table filter slot
              if (widget.tableFilter != null) widget.tableFilter!,
              // Active server-side filter bar
              if (meta != null && meta.filters.isNotEmpty)
                TablexFilterBar<T>(
                  controller: _controller,
                  filters: meta.filters,
                ),
              // Grid itself
              grid,
              // Selection summary
              if (widget.showSelectionSummary && selectedCount > 0)
                widget.selectionSummaryBuilder != null
                    ? widget.selectionSummaryBuilder!(
                        context,
                        _controller.selectedRows,
                        _controller.clearSelection,
                      )
                    : TablexSelectionSummaryBar(
                        count: selectedCount,
                        onClear: _controller.clearSelection,
                        actions: widget.selectionActions
                            ?.map(
                              (a) => TextButton.icon(
                                icon: Icon(a.icon, size: 16),
                                label: Text(a.label),
                                onPressed: () =>
                                    a.onPressed(_controller.selectedRows),
                              ),
                            )
                            .toList(),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
