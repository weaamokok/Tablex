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
import 'core/frozen_panel.dart';
import 'core/header_row.dart';
import 'pagination/pagination_footer.dart';
import 'tablex_types.dart';

export 'tablex_types.dart';

part '_tablex_state_mixin.dart';

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
        _windowPages = 1,
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
        _windowPages = 1,
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
    int windowPages = 5,
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
        _windowPages = windowPages,
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
        _windowPages = 1,
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
  final int _windowPages;
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

class _TablexState<T> extends State<Tablex<T>> with _TablexStateMixin<T> {
  @override
  void initState() {
    super.initState();
    _ownsController = widget._controller == null;
    _controller = widget._controller ?? TablexController<T>();
    _controller.selectionMode = widget._selectionMode;
    _controller.addListener(_onControllerChanged);
    _horizontalScroll.addListener(_syncHeaderScroll);
    _verticalScroll.addListener(_syncFrozenScrolls);

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
        WidgetsBinding.instance.addPostFrameCallback((_) => _fetchForward());
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
    _disposeScrollControllers();
    super.dispose();
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
            .where((col) => _controller.rows.every(
                (r) => (r.cells[col.fieldKey]?.toString() ?? '').isEmpty))
            .map((col) => col.fieldKey),
    };

    // Error replaces the table entirely.
    if (state.error != null && widget._errorBuilder != null) {
      return widget._errorBuilder!(context, state.error!);
    }

    // ── Column partitioning ──────────────────────────────────────────────────
    // Split the ordered column list into three groups. Frozen panels get their
    // own fixed-width areas; the scrollable group goes into TablexBody as usual.
    // The controller's runtime frozen overrides take precedence over the static
    // column definition so users can freeze/unfreeze via the column manager.
    final frozenStartCols = ordered
        .where((c) =>
            _controller.getColumnFrozen(c.fieldKey, c.frozen) ==
            TablexColumnFrozen.start)
        .toList();
    final frozenEndCols = ordered
        .where((c) =>
            _controller.getColumnFrozen(c.fieldKey, c.frozen) ==
            TablexColumnFrozen.end)
        .toList();
    final scrollableCols = ordered
        .where((c) =>
            _controller.getColumnFrozen(c.fieldKey, c.frozen) ==
            TablexColumnFrozen.none)
        .toList();
    final hasFrozenStart = frozenStartCols
        .any((c) => !c.hide && !hiddenFields.contains(c.fieldKey));
    final hasFrozenEnd =
        frozenEndCols.any((c) => !c.hide && !hiddenFields.contains(c.fieldKey));
    final hasFrozen = hasFrozenStart || hasFrozenEnd;

    // Columns handed to the scrollable body/header (excludes frozen cols).
    final bodyCols = hasFrozen ? scrollableCols : ordered;

    // ── Body ─────────────────────────────────────────────────────────────────
    // Built separately so loadingBuilder only wraps the scrollable rows, never
    // the header or footer (which don't need to be skeletonized).
    final tableBody = TablexBody<T>(
      controller: _controller,
      columns: bodyCols,
      density: widget._density,
      theme: resolvedTheme,
      selectionMode: widget._selectionMode,
      verticalScrollController: _verticalScroll,
      horizontalScrollController: _horizontalScroll,
      onRowTap: widget._onRowTap,
      onRowDoubleTap: widget._onRowDoubleTap,
      onSelectionChanged: widget._onSelectionChanged,
      // Suppress noDataWidget while the first fetch is in flight so the
      // user never sees "No data" before any rows have arrived.
      noDataWidget: (!state.isInitialized && state.isLoading)
          ? const SizedBox.shrink()
          : widget._noDataWidget,
    );

    Widget resolvedBody;
    final lb = widget._loadingBuilder;
    if (!state.isInitialized && state.isLoading) {
      if (lb != null) {
        // Skeleton rows already loaded in initState — let the builder shimmer
        // only over the row area, not the header or footer.
        resolvedBody = lb.builder(context, tableBody);
      } else {
        // No loadingBuilder — centred spinner over the empty body area.
        resolvedBody = Stack(
          children: [
            tableBody,
            const Center(child: CircularProgressIndicator())
          ],
        );
      }
    } else {
      resolvedBody = tableBody;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    final showSelectionBar =
        _controller.selectedRows.isNotEmpty && widget._showSelectionSummary;

    Widget buildSelectionSummary() => widget._selectionSummaryBuilder != null
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
          );

    Widget buildScrollableHeader() => SingleChildScrollView(
          controller: _headerHorizontalScroll,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: TablexHeaderRow<T>(
            columns: bodyCols,
            columnWidths: columnWidths,
            hiddenFields: hiddenFields,
            sort: state.query.sort,
            density: widget._density,
            theme: resolvedTheme,
            onSort: _onSort,
            onResizeUpdate:
                widget._enableColumnResize ? _controller.setColumnWidth : null,
            onResizeEnd: widget._enableColumnResize ? (_, __) {} : null,
            onReorder: _onReorder,
            selectionMode: widget._selectionMode,
            selectedCount: _controller.selectedRows.length,
            totalCount: _controller.rowCount,
            onSelectAll: () =>
                _controller.selectAll(_controller.getAllRowData()),
            onDeselectAll: _controller.clearSelection,
          ),
        );

    TablexFrozenPanel<T> buildFrozenPanel(
      List<TablexColumnBase<T>> cols,
      ScrollController scroll, {
      required bool shadowOnTrailingEdge,
    }) =>
        TablexFrozenPanel<T>(
          columns: cols,
          controller: _controller,
          columnWidths: columnWidths,
          hiddenFields: hiddenFields,
          sort: state.query.sort,
          density: widget._density,
          theme: resolvedTheme,
          verticalController: scroll,
          mainVerticalController: _verticalScroll,
          shadowOnTrailingEdge: shadowOnTrailingEdge,
          showHeader: widget._showHeader && !showSelectionBar,
          onSort: _onSort,
          onResizeUpdate:
              widget._enableColumnResize ? _controller.setColumnWidth : null,
          selectionMode: widget._selectionMode,
          onRowTap: widget._onRowTap,
          onRowDoubleTap: widget._onRowDoubleTap,
          onSelectionChanged: widget._onSelectionChanged,
        );

    // ── Full table layout ────────────────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column group header — shown for the scrollable columns only when
        // frozen columns are present (spanning all three panels is not
        // supported and would misalign with the frozen panel widths).
        if (widget._columnGroups != null)
          TablexColumnGroupHeader<T>(
            groups: widget._columnGroups!,
            columns: bodyCols,
            columnWidths: columnWidths,
            hiddenFields: hiddenFields,
            density: widget._density,
            theme: resolvedTheme,
          ),
        // Selection summary bar always spans the full width.
        if (widget._showHeader && showSelectionBar) buildSelectionSummary(),
        // Header + body area — three-panel when frozen columns are active.
        if (hasFrozen)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasFrozenStart)
                  buildFrozenPanel(
                    frozenStartCols,
                    _frozenStartScroll,
                    shadowOnTrailingEdge: true,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget._showHeader && !showSelectionBar)
                        buildScrollableHeader(),
                      Expanded(child: resolvedBody),
                    ],
                  ),
                ),
                if (hasFrozenEnd)
                  buildFrozenPanel(
                    frozenEndCols,
                    _frozenEndScroll,
                    shadowOnTrailingEdge: false,
                  ),
              ],
            ),
          )
        else ...[
          // Original flat layout (no frozen columns).
          if (widget._showHeader && !showSelectionBar) buildScrollableHeader(),
          Expanded(child: resolvedBody),
        ],
        // Bottom loading indicator for ongoing infinite-scroll fetches.
        if (widget._variant == _TablexVariant.infinite &&
            state.isInitialized &&
            state.isLoading)
          const _InfiniteLoadingBar(),
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
  }
}

// ============================================================================
// Infinite scroll bottom loading bar
// ============================================================================

class _InfiniteLoadingBar extends StatelessWidget {
  const _InfiniteLoadingBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
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
          Text(
            strings.selected(selectedCount),
            style: theme.headerTextStyle?.copyWith(
              color: cs.onPrimaryContainer,
            ),
          ),
          const Spacer(),
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
