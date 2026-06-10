part of 'tablex_widget.dart';

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
    // Uses the accumulated _seenNonEmptyFields set (never shrinks) so columns
    // do not flicker in/out as the user pages through data.
    final Set<String> hiddenFields = {
      ...state.hiddenColumnFields,
      ...ordered
          .where((col) =>
              (widget._hideEmptyColumns || col.hideIfEmpty) &&
              !_seenNonEmptyFields.contains(col.fieldKey))
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
      hiddenFields: hiddenFields,
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
            const Center(child: CircularProgressIndicator()),
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
            columns: widget._columns,
            controller: _controller,
            selectionMode: widget._selectionMode,
            onExportSelectedCsv: widget._onExportSelectedCsv,
            onExportSelectedExcel: widget._onExportSelectedExcel,
            onExportSelectedPdf: widget._onExportSelectedPdf,
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
