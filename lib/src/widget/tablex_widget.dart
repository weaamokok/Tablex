import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controller/controller.dart';
import '../model/column.dart';
import '../model/enums.dart';
import '../model/query.dart';
import '../model/response.dart';
import '../model/row.dart';
import '../theme/grid_theme.dart';
import '../theme/grid_theme_data.dart';
import '../../i18n/strings.g.dart';
import 'core/body.dart';
import 'core/column_group_header.dart';
import 'core/footer_row.dart';
import 'core/header_row.dart';
import 'pagination/pagination_footer.dart';

/// Configuration for the first-load skeleton state on [Tablex.lazyPaged]
/// and [Tablex.infinite].
///
/// [skeletonData] pre-populates the table with placeholder rows so
/// [builder] has real content to shimmer over.
/// [builder] is only called while `!isInitialized`; it never fires on
/// subsequent page fetches.
///
/// ```dart
/// loadingBuilder: TablexLoadingBuilder(
///   skeletonData: List.generate(13, (_) => Employee.placeholder()),
///   builder: (context, table) => Skeletonizer(enabled: true, child: table),
/// ),
/// ```
class TablexLoadingBuilder<T> {
  const TablexLoadingBuilder({
    required this.skeletonData,
    required this.builder,
  });

  final List<T> skeletonData;
  final Widget Function(BuildContext context, Widget table) builder;
}

/// Replaces the table entirely when a fetch error occurs.
typedef TablexErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
);

/// Fully replaces the selection summary header that appears above the grid
/// when one or more rows are selected.
///
/// Receives the current [selectedRows] and a [clearSelection] callback.
/// When this builder is provided, [selectionActions] and
/// [includeClearSelectionAction] are ignored — the widget returned here is
/// used as-is.
///
/// ```dart
/// selectionSummaryBuilder: (context, selected, clear) => ColoredBox(
///   color: Colors.amber.shade100,
///   child: Row(children: [
///     Text('${selected.length} items'),
///     IconButton(icon: const Icon(Icons.close), onPressed: clear),
///   ]),
/// ),
/// ```
typedef TablexSelectionSummaryBuilder<T> = Widget Function(
  BuildContext context,
  List<T> selectedRows,
  VoidCallback clearSelection,
);

/// An action button rendered in the [TablexConsumer] selection summary bar.
///
/// Each action appears as a [TextButton] with an icon next to a label. The
/// button receives the list of currently selected rows when pressed.
///
/// ```dart
/// selectionActions: [
///   TablexSelectionAction(
///     label: 'Delete selected',
///     icon: Icons.delete_outline,
///     onPressed: (selected) => _bulkDelete(selected),
///   ),
/// ]
/// ```
class TablexSelectionAction<T> {
  const TablexSelectionAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;

  /// Called with all currently selected rows when the user taps this action.
  final void Function(List<T> selected) onPressed;
}

// ============================================================================
// Variant enum (package-private)
// ============================================================================

enum _TablexVariant { static_, lazyPaged, infinite, select }

// ============================================================================
// Main Tablex widget
// ============================================================================

/// Low-level data grid widget with four named constructors.
///
/// For most use cases prefer [TablexConsumer], which wraps this widget with
/// a controller lifecycle, themed border, filter bar, and selection summary
/// bar. Use [Tablex] directly when you need a bare grid embedded inside a
/// custom layout.
///
/// ## Constructors
///
/// | Constructor | When to use |
/// |---|---|
/// | [Tablex.static] | In-memory list, client-side sort |
/// | [Tablex.lazyPaged] | Server-side pagination with page cache |
/// | [Tablex.infinite] | Infinite scroll — appends batches as the user scrolls |
/// | [Tablex.select] | Picker / combobox pattern — always single or multi select |
class Tablex<T> extends StatefulWidget {
  // --------------------------------------------------------------------------
  // Static constructor
  // --------------------------------------------------------------------------
  // ignore: prefer_const_constructors_in_immutables

  /// Renders [rows] from an in-memory list.
  ///
  /// Sorting is handled client-side by the widget — no network call required.
  /// Best for small, fully-loaded datasets (< ~500 rows).
  const Tablex.static({
    super.key,
    required List<TablexColumnBase<T>> columns,
    required List<T> rows,
    required TablexRow<T> Function(T) rowBuilder,
    TablexController<T>? controller,
    TablexDensity density = TablexDensity.comfortable,
    TablexSelectionMode selectionMode = TablexSelectionMode.none,
    List<T>? initialSelection,
    void Function(T)? onRowTap,
    void Function(T)? onRowDoubleTap,
    void Function(List<T>)? onSelectionChanged,
    bool enableColumnResize = true,
    bool showHeader = true,
    List<TablexColumnGroup>? columnGroups,
    Widget? noDataWidget,
    TablexThemeData? theme,
    bool showSelectionSummary = false,
    List<TablexSelectionAction<T>>? selectionActions,
    bool includeClearSelectionAction = true,
    TablexSelectionSummaryBuilder<T>? selectionSummaryBuilder,
  })  : _variant = _TablexVariant.static_,
        _columns = columns,
        _staticRows = rows,
        _rowBuilder = rowBuilder,
        _controller = controller,
        _density = density,
        _selectionMode = selectionMode,
        _initialSelection = initialSelection,
        _onRowTap = onRowTap,
        _onRowDoubleTap = onRowDoubleTap,
        _onSelectionChanged = onSelectionChanged,
        _enableColumnResize = enableColumnResize,
        _showHeader = showHeader,
        _columnGroups = columnGroups,
        _noDataWidget = noDataWidget,
        _loadingBuilder = null,
        _errorBuilder = null,
        _themeOverride = theme,
        _fetchTask = null,
        _fetchWithSorting = false,
        _fetchWithFiltering = false,
        _fetchSize = 50,
        _initialPageSize = 25,
        _paginationKey = null,
        _enablePageJump = false,
        _footerBuilder = null,
        _hideEmptyColumns = false,
        _showSelectionSummary = showSelectionSummary,
        _selectionActions = selectionActions,
        _includeClearSelectionAction = includeClearSelectionAction,
        _selectionSummaryBuilder = selectionSummaryBuilder;

  // --------------------------------------------------------------------------
  // Lazy paged constructor
  // --------------------------------------------------------------------------
  // ignore: prefer_const_constructors_in_immutables

  /// Server-side paginated grid with an in-memory page cache.
  ///
  /// [fetchTask] is called whenever the page, page size, sort, or filters
  /// change. Previously fetched pages are cached (up to 10) and reused on
  /// back-navigation without a network call.
  ///
  /// Set [fetchWithSorting] / [fetchWithFiltering] to `false` to opt out of
  /// automatic query propagation for those axes. [hideEmptyColumns] collapses
  /// columns whose values are all empty for the current page.
  const Tablex.lazyPaged({
    super.key,
    required List<TablexColumnBase<T>> columns,
    required TablexFetchTask<T> fetchTask,
    required TablexRow<T> Function(T) rowBuilder,
    TablexController<T>? controller,
    TablexDensity density = TablexDensity.comfortable,
    TablexSelectionMode selectionMode = TablexSelectionMode.none,
    void Function(T)? onRowTap,
    void Function(T)? onRowDoubleTap,
    void Function(List<T>)? onSelectionChanged,
    bool enableColumnResize = true,
    bool showHeader = true,
    bool fetchWithSorting = true,
    bool fetchWithFiltering = true,
    bool hideEmptyColumns = false,
    int initialPageSize = 25,
    List<TablexColumnGroup>? columnGroups,
    Widget? noDataWidget,
    TablexLoadingBuilder<T>? loadingBuilder,
    TablexErrorBuilder? errorBuilder,
    Key? paginationKey,
    bool enablePageJump = false,
    TablexFooterBuilder? footerBuilder,
    TablexThemeData? theme,
    bool showSelectionSummary = false,
    List<TablexSelectionAction<T>>? selectionActions,
    bool includeClearSelectionAction = true,
    TablexSelectionSummaryBuilder<T>? selectionSummaryBuilder,
  })  : _variant = _TablexVariant.lazyPaged,
        _columns = columns,
        _fetchTask = fetchTask,
        _rowBuilder = rowBuilder,
        _controller = controller,
        _density = density,
        _selectionMode = selectionMode,
        _onRowTap = onRowTap,
        _onRowDoubleTap = onRowDoubleTap,
        _onSelectionChanged = onSelectionChanged,
        _enableColumnResize = enableColumnResize,
        _showHeader = showHeader,
        _columnGroups = columnGroups,
        _noDataWidget = noDataWidget,
        _loadingBuilder = loadingBuilder,
        _errorBuilder = errorBuilder,
        _themeOverride = theme,
        _staticRows = null,
        _initialSelection = null,
        _fetchWithSorting = fetchWithSorting,
        _fetchWithFiltering = fetchWithFiltering,
        _hideEmptyColumns = hideEmptyColumns,
        _initialPageSize = initialPageSize,
        _paginationKey = paginationKey,
        _enablePageJump = enablePageJump,
        _footerBuilder = footerBuilder,
        _fetchSize = 50,
        _showSelectionSummary = showSelectionSummary,
        _selectionActions = selectionActions,
        _includeClearSelectionAction = includeClearSelectionAction,
        _selectionSummaryBuilder = selectionSummaryBuilder;

  // --------------------------------------------------------------------------
  // Infinite scroll constructor
  // --------------------------------------------------------------------------
  // ignore: prefer_const_constructors_in_immutables

  /// Appends batches of rows as the user scrolls toward the bottom.
  ///
  /// [fetchTask] is called with an incrementing page number each time the
  /// scroll position nears the end. [fetchSize] controls how many rows are
  /// requested per batch. When the sort changes, all rows are cleared and
  /// fetching restarts from page 1.
  const Tablex.infinite({
    super.key,
    required List<TablexColumnBase<T>> columns,
    required TablexFetchTask<T> fetchTask,
    required TablexRow<T> Function(T) rowBuilder,
    TablexController<T>? controller,
    TablexDensity density = TablexDensity.comfortable,
    TablexSelectionMode selectionMode = TablexSelectionMode.none,
    void Function(T)? onRowTap,
    void Function(T)? onRowDoubleTap,
    void Function(List<T>)? onSelectionChanged,
    bool enableColumnResize = true,
    bool fetchWithSorting = true,
    bool fetchWithFiltering = true,
    int fetchSize = 50,
    List<TablexColumnGroup>? columnGroups,
    Widget? noDataWidget,
    TablexLoadingBuilder<T>? loadingBuilder,
    TablexErrorBuilder? errorBuilder,
    TablexThemeData? theme,
    bool showSelectionSummary = false,
    List<TablexSelectionAction<T>>? selectionActions,
    bool includeClearSelectionAction = true,
    TablexSelectionSummaryBuilder<T>? selectionSummaryBuilder,
  })  : _variant = _TablexVariant.infinite,
        _columns = columns,
        _fetchTask = fetchTask,
        _rowBuilder = rowBuilder,
        _controller = controller,
        _density = density,
        _selectionMode = selectionMode,
        _onRowTap = onRowTap,
        _onRowDoubleTap = onRowDoubleTap,
        _onSelectionChanged = onSelectionChanged,
        _enableColumnResize = enableColumnResize,
        _showHeader = true,
        _columnGroups = columnGroups,
        _noDataWidget = noDataWidget,
        _loadingBuilder = loadingBuilder,
        _errorBuilder = errorBuilder,
        _themeOverride = theme,
        _staticRows = null,
        _initialSelection = null,
        _fetchWithSorting = fetchWithSorting,
        _fetchWithFiltering = fetchWithFiltering,
        _fetchSize = fetchSize,
        _initialPageSize = 25,
        _paginationKey = null,
        _enablePageJump = false,
        _footerBuilder = null,
        _hideEmptyColumns = false,
        _showSelectionSummary = showSelectionSummary,
        _selectionActions = selectionActions,
        _includeClearSelectionAction = includeClearSelectionAction,
        _selectionSummaryBuilder = selectionSummaryBuilder;

  // --------------------------------------------------------------------------
  // Select constructor
  // --------------------------------------------------------------------------
  // ignore: prefer_const_constructors_in_immutables

  /// A compact, always-selectable table intended for picker / combobox use.
  ///
  /// Column resize is disabled. Density defaults to [TablexDensity.compact].
  /// Set [multiSelect] to `true` for checkbox-style multi-selection.
  const Tablex.select({
    super.key,
    required List<TablexColumnBase<T>> columns,
    required List<T> rows,
    required TablexRow<T> Function(T) rowBuilder,
    TablexController<T>? controller,
    TablexDensity density = TablexDensity.compact,
    bool multiSelect = false,
    List<T>? initialSelection,
    void Function(List<T>)? onSelectionChanged,
    bool showHeader = true,
    List<TablexColumnGroup>? columnGroups,
    Widget? noDataWidget,
    TablexThemeData? theme,
  })  : _variant = _TablexVariant.select,
        _columns = columns,
        _staticRows = rows,
        _rowBuilder = rowBuilder,
        _controller = controller,
        _density = density,
        _selectionMode = multiSelect
            ? TablexSelectionMode.multiple
            : TablexSelectionMode.single,
        _initialSelection = initialSelection,
        _onSelectionChanged = onSelectionChanged,
        _showHeader = showHeader,
        _columnGroups = columnGroups,
        _noDataWidget = noDataWidget,
        _themeOverride = theme,
        _enableColumnResize = false,
        _onRowTap = null,
        _onRowDoubleTap = null,
        _fetchTask = null,
        _loadingBuilder = null,
        _errorBuilder = null,
        _fetchWithSorting = false,
        _fetchWithFiltering = false,
        _fetchSize = 50,
        _initialPageSize = 25,
        _paginationKey = null,
        _enablePageJump = false,
        _footerBuilder = null,
        _hideEmptyColumns = false,
        _showSelectionSummary = false,
        _selectionActions = null,
        _includeClearSelectionAction = true,
        _selectionSummaryBuilder = null;

  // --------------------------------------------------------------------------
  // Shared fields
  // --------------------------------------------------------------------------

  final _TablexVariant _variant;
  final List<TablexColumnBase<T>> _columns;
  final List<T>? _staticRows;
  final TablexFetchTask<T>? _fetchTask;
  final TablexRow<T> Function(T) _rowBuilder;
  final TablexController<T>? _controller;
  final TablexDensity _density;
  final TablexSelectionMode _selectionMode;
  final List<T>? _initialSelection;
  final void Function(T)? _onRowTap;
  final void Function(T)? _onRowDoubleTap;
  final void Function(List<T>)? _onSelectionChanged;
  final bool _enableColumnResize;
  final bool _showHeader;
  final List<TablexColumnGroup>? _columnGroups;
  final Widget? _noDataWidget;
  final TablexLoadingBuilder<T>? _loadingBuilder;
  final TablexErrorBuilder? _errorBuilder;
  final TablexThemeData? _themeOverride;
  final bool _fetchWithSorting;
  final bool _fetchWithFiltering;
  final bool _hideEmptyColumns;
  final int _initialPageSize;
  final int _fetchSize;
  final Key? _paginationKey;
  final bool _enablePageJump;
  final TablexFooterBuilder? _footerBuilder;
  final bool _showSelectionSummary;
  final List<TablexSelectionAction<T>>? _selectionActions;
  final bool _includeClearSelectionAction;
  final TablexSelectionSummaryBuilder<T>? _selectionSummaryBuilder;

  @override
  State<Tablex<T>> createState() => _TablexState<T>();
}

// ============================================================================
// State
// ============================================================================

class _TablexState<T> extends State<Tablex<T>> {
  late TablexController<T> _controller;
  bool _ownsController = false;

  final ScrollController _verticalScroll = ScrollController();
  // Primary horizontal scroll — owned by the body.
  final ScrollController _horizontalScroll = ScrollController();
  // Mirrors body scroll so the header stays in sync without sharing a controller.
  final ScrollController _headerHorizontalScroll = ScrollController();

  // For infinite scroll
  bool _isFetching = false;
  int _lastFetchedPage = 0;
  int _totalRows = 0;

  @override
  void initState() {
    super.initState();
    _ownsController = widget._controller == null;
    _controller = widget._controller ?? TablexController<T>();
    _controller.selectionMode = widget._selectionMode;
    _controller.addListener(_onControllerChanged);
    _horizontalScroll.addListener(_syncHeaderScroll);

    if (widget._initialSelection != null) {
      _controller.setSelection(widget._initialSelection!);
    }

    if (widget._variant == _TablexVariant.static_ ||
        widget._variant == _TablexVariant.select) {
      _loadStaticRows();
    } else {
      _preloadSkeletonIfNeeded();
      if (widget._variant == _TablexVariant.infinite) {
        _verticalScroll.addListener(_onInfiniteScroll);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _fetchInfinitePage());
      }
    }

    if (widget._initialPageSize != 25) {
      _controller.setPageSize(widget._initialPageSize);
    }
  }

  @override
  void didUpdateWidget(Tablex<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._controller != widget._controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) _controller.dispose();
      _ownsController = widget._controller == null;
      _controller = widget._controller ?? TablexController<T>();
      _controller.selectionMode = widget._selectionMode;
      _controller.addListener(_onControllerChanged);
    }
    // Only re-sync rows from the prop when we own the controller.
    // When the caller provides an external controller they own the data —
    // rows written by importFromCsv / replaceRows must not be overwritten.
    if (_ownsController &&
        (widget._variant == _TablexVariant.static_ ||
            widget._variant == _TablexVariant.select) &&
        !listEquals(widget._staticRows, oldWidget._staticRows)) {
      _loadStaticRows();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    _horizontalScroll.removeListener(_syncHeaderScroll);
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    _headerHorizontalScroll.dispose();
    super.dispose();
  }

  void _syncHeaderScroll() {
    if (!_headerHorizontalScroll.hasClients) return;
    if (!_horizontalScroll.hasClients) return;
    final offset = _horizontalScroll.position.pixels;
    if (_headerHorizontalScroll.position.pixels != offset) {
      _headerHorizontalScroll.jumpTo(offset);
    }
  }

  void _loadStaticRows() {
    _controller.replaceRows(
      widget._staticRows ?? [],
      rowBuilder: widget._rowBuilder,
    );
  }

  void _preloadSkeletonIfNeeded() {
    final lb = widget._loadingBuilder;
    if (lb == null || lb.skeletonData.isEmpty) return;
    if (_controller.state.isInitialized) return;
    _controller.replaceRows(
      lb.skeletonData,
      rowBuilder: widget._rowBuilder,
      markInitialized: false,
    );
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // Returns columns in the current display order (respects controller.columnOrder).
  List<TablexColumnBase<T>> get _orderedColumns {
    final order = _controller.state.columnOrder;
    if (order.isEmpty) return widget._columns;
    final byField = {for (final c in widget._columns) c.fieldKey: c};
    final ordered =
        order.map((f) => byField[f]).whereType<TablexColumnBase<T>>().toList();
    // Append any columns added after the last reorder
    for (final col in widget._columns) {
      if (!order.contains(col.fieldKey)) ordered.add(col);
    }
    return ordered;
  }

  void _onReorder(String fromField, String toField) {
    final currentOrder = _orderedColumns.map((c) => c.fieldKey).toList();
    final fromIdx = currentOrder.indexOf(fromField);
    final toIdx = currentOrder.indexOf(toField);
    if (fromIdx == -1 || toIdx == -1 || fromIdx == toIdx) return;
    currentOrder.removeAt(fromIdx);
    currentOrder.insert(toIdx, fromField);
    _controller.setColumnOrder(currentOrder);
  }

  void _onSort(String field, TablexColumnSort? sort) {
    _controller.setSort(sort);
    switch (widget._variant) {
      case _TablexVariant.static_:
      case _TablexVariant.select:
        _applyStaticSort(sort?.field, sort?.direction);
      case _TablexVariant.infinite:
        if (!widget._fetchWithSorting) break;
        _isFetching = false;
        _controller.clearRows();
        _lastFetchedPage = 0;
        _totalRows = 0;
        _preloadSkeletonIfNeeded();
        _fetchInfinitePage();
      case _TablexVariant.lazyPaged:
        break; // pagination footer reacts via _onControllerChanged
    }
  }

  void _applyStaticSort(String? field, TablexSortDirection? direction) {
    final rows = List<T>.from(widget._staticRows ?? []);
    if (field != null && direction != null) {
      final candidates = widget._columns.where((c) => c.fieldKey == field);
      if (candidates.isNotEmpty) {
        final col = candidates.first;
        rows.sort((a, b) {
          final va = col.extractValue(a);
          final vb = col.extractValue(b);
          final cmp = va is Comparable && vb is Comparable
              ? va.compareTo(vb)
              : va.toString().compareTo(vb.toString());
          return direction == TablexSortDirection.ascending ? cmp : -cmp;
        });
      }
    }
    _controller.replaceRows(
      rows,
      rowBuilder: widget._rowBuilder,
      clearSelection: false,
    );
  }

  Future<void> _fetchInfinitePage() async {
    if (_isFetching) return;
    final nextPage = _lastFetchedPage + 1;

    _isFetching = true;
    _controller.setLoading(true);
    try {
      final query = _controller.state.query.copyWith(
        page: nextPage,
        pageSize: widget._fetchSize,
      );
      final result = await widget._fetchTask!(query);
      if (!mounted) return;
      _totalRows = result.totalRows;
      _lastFetchedPage = nextPage;
      _controller.appendRows(result.rows, rowBuilder: widget._rowBuilder);
    } catch (e) {
      if (mounted) _controller.setError(e);
    } finally {
      _isFetching = false;
      if (mounted) _controller.setLoading(false);
    }
  }

  void _onInfiniteScroll() {
    if (!_verticalScroll.hasClients) return;
    final position = _verticalScroll.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      if (_controller.rowCount < _totalRows) {
        _fetchInfinitePage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = (widget._themeOverride ??
            TablexTheme.maybeOf(context) ??
            const TablexThemeData())
        .resolve(context);

    final state = _controller.state;
    final columnWidths = state.columnWidths;
    final ordered = _orderedColumns;

    // Merge controller-hidden fields with auto-hidden empty columns.
    final Set<String> hiddenFields = {
      ...state.hiddenColumnFields,
      if (widget._hideEmptyColumns)
        ...ordered
            .where((col) => _controller.rows
                .every((r) => (r.cells[col.fieldKey]?.toString() ?? '').isEmpty))
            .map((col) => col.fieldKey),
    };
    if (_isFetching || state.isLoading) {}
    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column group header
        if (widget._columnGroups != null)
          TablexColumnGroupHeader<T>(
            groups: widget._columnGroups!,
            columns: ordered,
            columnWidths: columnWidths,
            hiddenFields: hiddenFields,
            density: widget._density,
            theme: resolvedTheme,
          ),
        // Header row or selection summary bar
        if (widget._showHeader)
          _controller.selectedRows.isNotEmpty && widget._showSelectionSummary
              ? widget._selectionSummaryBuilder != null
                  ? widget._selectionSummaryBuilder!(
                      context,
                      _controller.selectedRows,
                      _controller.clearSelection,
                    )
                  : _SelectionSummaryHeader<T>(
                      selectedCount: _controller.selectedRows.length,
                      selectedItems: _controller.selectedRows,
                      density: widget._density,
                      theme: resolvedTheme,
                      onClear: _controller.clearSelection,
                      actions: widget._selectionActions,
                      includeClearAction: widget._includeClearSelectionAction,
                    )
              : SingleChildScrollView(
                  controller: _headerHorizontalScroll,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: TablexHeaderRow<T>(
                    columns: ordered,
                    columnWidths: columnWidths,
                    hiddenFields: hiddenFields,
                    sort: state.query.sort,
                    density: widget._density,
                    theme: resolvedTheme,
                    onSort: _onSort,
                    onResizeUpdate: widget._enableColumnResize
                        ? _controller.setColumnWidth
                        : null,
                    onResizeEnd: widget._enableColumnResize
                        ? (_, __) {}
                        : null,
                    onReorder: _onReorder,
                    selectionMode: widget._selectionMode,
                    selectedCount: _controller.selectedRows.length,
                    totalCount: _controller.rowCount,
                    onSelectAll: () =>
                        _controller.selectAll(_controller.getAllRowData()),
                    onDeselectAll: _controller.clearSelection,
                  ),
                ),
        Expanded(
          child: TablexBody<T>(
            controller: _controller,
            columns: ordered,
            density: widget._density,
            theme: resolvedTheme,
            selectionMode: widget._selectionMode,
            verticalScrollController: _verticalScroll,
            horizontalScrollController: _horizontalScroll,
            onRowTap: widget._onRowTap,
            onRowDoubleTap: widget._onRowDoubleTap,
            onSelectionChanged: widget._onSelectionChanged,
            // Suppress noDataWidget while in skeleton-loading state
            noDataWidget:
                (!state.isInitialized && widget._loadingBuilder != null)
                    ? const SizedBox.shrink()
                    : widget._noDataWidget,
          ),
        ),
        // Footer row (aggregate cells)
        if (ordered.any((c) => c.footerRenderer != null))
          TablexFooterRow<T>(
            columns: ordered,
            columnWidths: columnWidths,
            hiddenFields: hiddenFields,
            allRowData: _controller.getAllRowData(),
            visibleRowData: _controller.getAllRowData(),
            density: widget._density,
            theme: resolvedTheme,
          ),
        // Pagination footer (lazyPaged only)
        if (widget._variant == _TablexVariant.lazyPaged)
          TablexPaginationFooter<T>(
            key: widget._paginationKey,
            controller: _controller,
            fetchTask: widget._fetchTask!,
            rowBuilder: widget._rowBuilder,
            theme: resolvedTheme,
            fetchWithSorting: widget._fetchWithSorting,
            fetchWithFiltering: widget._fetchWithFiltering,
            enablePageJump: widget._enablePageJump,
            footerBuilder: widget._footerBuilder,
          ),
      ],
    );

    // Error replaces the table entirely
    if (state.error != null && widget._errorBuilder != null) {
      return widget._errorBuilder!(context, state.error!);
    }

    // Loading builder wraps the table — only on the very first fetch.
    // Skeleton rows are already in the controller (loaded in initState),
    // so the builder immediately has content to shimmer over.
    final lb = widget._loadingBuilder;
    if (!state.isInitialized && state.isLoading && lb != null) {
      return lb.builder(context, table);
    }

    return table;
  }
}

// ============================================================================
// Selection summary header
// ============================================================================

class _SelectionSummaryHeader<T> extends StatelessWidget {
  const _SelectionSummaryHeader({
    required this.selectedCount,
    required this.selectedItems,
    required this.density,
    required this.theme,
    required this.onClear,
    this.actions,
    this.includeClearAction = true,
  });

  final int selectedCount;
  final List<T> selectedItems;
  final TablexDensity density;
  final TablexThemeData theme;
  final VoidCallback onClear;
  final List<TablexSelectionAction<T>>? actions;
  final bool includeClearAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = tablexStrings(context);

    return Container(
      height: density.headerHeight,
      color: cs.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Count label
          Text(
            strings.selected(selectedCount),
            style: theme.headerTextStyle?.copyWith(
              color: cs.onPrimaryContainer,
            ),
          ),
          const Spacer(),
          // Action buttons
          if (actions != null)
            ...actions!.map(
              (action) => TextButton.icon(
                icon: Icon(action.icon, size: 16),
                label: Text(action.label),
                style: TextButton.styleFrom(
                  foregroundColor: cs.onPrimaryContainer,
                ),
                onPressed: () => action.onPressed(selectedItems),
              ),
            ),
          // Clear button
          if (includeClearAction)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: strings.clear,
              color: cs.onPrimaryContainer,
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}
