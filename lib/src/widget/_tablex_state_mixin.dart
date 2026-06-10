part of 'tablex_widget.dart';

// Sliding-window infinite scroll, scroll-sync helpers, sort, and column-order
// logic, extracted from _TablexState to keep the widget file focused on
// constructors and build. Uses `part of` so all `_private` names remain
// accessible without exposing them as a public API.
mixin _TablexStateMixin<T> on State<Tablex<T>> {
  late TablexController<T> _controller;
  bool _ownsController = false;

  // Primary horizontal scroll — owned by the body.
  final ScrollController _horizontalScroll = ScrollController();
  // Mirrors body scroll so the header stays in sync without sharing a controller.
  final ScrollController _headerHorizontalScroll = ScrollController();
  // Main vertical scroll shared by the body and the frozen-panel sync logic.
  final ScrollController _verticalScroll = ScrollController();
  // Independent vertical controllers for frozen panels, kept in sync with
  // _verticalScroll via _syncFrozenScrolls.
  final ScrollController _frozenStartScroll = ScrollController();
  final ScrollController _frozenEndScroll = ScrollController();

  // Sliding-window infinite scroll state.
  // _loadedPages holds page numbers currently in memory, oldest-first.
  // _pageRowCounts tracks actual row count per page (last page may be partial).
  final List<int> _loadedPages = [];
  final Map<int, int> _pageRowCounts = {};
  bool _isFetchingForward = false;
  bool _isFetchingBackward = false;
  int _totalRows = 0;
  // Incremented on every sort/reset so in-flight futures from the previous
  // generation abort when they resolve instead of mutating stale state.
  int _fetchGeneration = 0;

  // Accumulates fieldKeys that have had at least one non-null/non-empty value
  // across any loaded page. Used by hideEmptyColumns / hideIfEmpty to avoid
  // flickering as pages turn — a column stays visible once it has been seen
  // with data, instead of being re-evaluated against the current page only.
  final Set<String> _seenNonEmptyFields = {};

  // ---------------------------------------------------------------------------
  // Scroll sync
  // ---------------------------------------------------------------------------

  void _syncFrozenScrolls() {
    if (!_verticalScroll.hasClients) return;
    final offset = _verticalScroll.position.pixels;
    if (_frozenStartScroll.hasClients &&
        _frozenStartScroll.position.pixels != offset) {
      _frozenStartScroll.jumpTo(offset);
    }
    if (_frozenEndScroll.hasClients &&
        _frozenEndScroll.position.pixels != offset) {
      _frozenEndScroll.jumpTo(offset);
    }
  }

  void _syncHeaderScroll() {
    if (!_headerHorizontalScroll.hasClients) return;
    if (!_horizontalScroll.hasClients) return;
    final offset = _horizontalScroll.position.pixels;
    if (_headerHorizontalScroll.position.pixels != offset) {
      _headerHorizontalScroll.jumpTo(offset);
    }
  }

  void _disposeScrollControllers() {
    _horizontalScroll.removeListener(_syncHeaderScroll);
    _verticalScroll.removeListener(_syncFrozenScrolls);
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    _headerHorizontalScroll.dispose();
    _frozenStartScroll.dispose();
    _frozenEndScroll.dispose();
  }

  // ---------------------------------------------------------------------------
  // Static rows & skeleton
  // ---------------------------------------------------------------------------

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
    _updateSeenNonEmptyFields();
    if (mounted) setState(() {});
  }

  void _updateSeenNonEmptyFields() {
    final needsTracking = widget._hideEmptyColumns ||
        widget._columns.any((c) => c.hideIfEmpty);
    if (!needsTracking) return;
    for (final row in _controller.rows) {
      for (final col in widget._columns) {
        if (_seenNonEmptyFields.contains(col.fieldKey)) continue;
        if (!widget._hideEmptyColumns && !col.hideIfEmpty) continue;
        final v = row.cells[col.fieldKey];
        if (v != null && v.toString().isNotEmpty) {
          _seenNonEmptyFields.add(col.fieldKey);
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Column order & reorder
  // ---------------------------------------------------------------------------

  List<TablexColumnBase<T>> get _orderedColumns {
    final order = _controller.state.columnOrder;
    if (order.isEmpty) return widget._columns;
    final byField = {for (final c in widget._columns) c.fieldKey: c};
    final ordered =
        order.map((f) => byField[f]).whereType<TablexColumnBase<T>>().toList();
    // Append any columns added after the last reorder.
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

  // ---------------------------------------------------------------------------
  // Sort
  // ---------------------------------------------------------------------------

  void _onSort(String field, TablexColumnSort? sort) {
    _controller.setSort(sort);
    switch (widget._variant) {
      case _TablexVariant.static_:
      case _TablexVariant.select:
        _applyStaticSort(sort?.field, sort?.direction);
      case _TablexVariant.infinite:
        if (!widget._fetchWithSorting) break;
        _fetchGeneration++;
        _isFetchingForward = false;
        _isFetchingBackward = false;
        _loadedPages.clear();
        _pageRowCounts.clear();
        _totalRows = 0;
        _controller.clearRows();
        _preloadSkeletonIfNeeded();
        _fetchForward();
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

  // ---------------------------------------------------------------------------
  // Sliding-window infinite scroll
  //
  // Memory model: only [windowPages] pages live in the controller at once.
  // When a new page arrives at the bottom, the oldest top page is evicted and
  // the scroll offset is compensated so the viewport does not jump.
  // When the user scrolls back above the window, the previous page is fetched
  // and the bottom page is evicted instead.
  // ---------------------------------------------------------------------------

  /// Fetches the next page and appends it. Evicts the top page if the window
  /// is full, compensating the scroll offset so the viewport stays stable.
  Future<void> _fetchForward() async {
    if (_isFetchingForward) return;
    if (_loadedPages.isNotEmpty && _controller.rowCount >= _totalRows) return;

    final nextPage = _loadedPages.isEmpty ? 1 : _loadedPages.last + 1;
    final gen = _fetchGeneration;
    _isFetchingForward = true;
    _controller.setLoading(true);
    try {
      var q = _controller.state.query.copyWith(
        page: nextPage,
        pageSize: widget._fetchSize,
      );
      if (!widget._fetchWithSorting) q = q.copyWith(clearSort: true);
      if (!widget._fetchWithFiltering) q = q.copyWith(params: const {});
      final result = await widget._fetchTask!(q);
      if (!mounted || _fetchGeneration != gen) return;

      _totalRows = result.totalRows;
      _pageRowCounts[nextPage] = result.rows.length;

      // Evict the oldest (top) page if the window is full.
      if (_loadedPages.length >= widget._windowPages) {
        final evictedPage = _loadedPages.removeAt(0);
        final evictedCount = _pageRowCounts.remove(evictedPage) ?? 0;
        final compensation = evictedCount * widget._density.rowHeight;
        _controller.removeFirstRows(evictedCount);
        // After the ListView rebuilds with fewer items, shift the scroll up
        // by exactly the height of the removed rows so the viewport is stable.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_verticalScroll.hasClients) return;
          final target = _verticalScroll.offset - compensation;
          _verticalScroll.jumpTo(
              target.clamp(0.0, _verticalScroll.position.maxScrollExtent));
        });
      }

      _loadedPages.add(nextPage);
      // First page: replace any skeleton rows. Subsequent pages: append.
      if (_loadedPages.length == 1) {
        _controller.replaceRows(result.rows, rowBuilder: widget._rowBuilder);
      } else {
        _controller.appendRows(result.rows, rowBuilder: widget._rowBuilder);
      }
    } catch (e) {
      if (mounted) _controller.setError(e);
    } finally {
      _isFetchingForward = false;
      if (mounted) _controller.setLoading(false);
    }

    // Proactive prefetch: fill the window without waiting for a scroll event.
    // Runs after the finally block so _isFetchingForward is already false.
    // Stops once the window is full — from that point the scroll trigger takes over.
    if (mounted &&
        _controller.rowCount < _totalRows &&
        _loadedPages.length < widget._windowPages) {
      _fetchForward();
    }
  }

  /// Fetches the previous page and prepends it. Evicts the bottom page if the
  /// window is full, then compensates the scroll offset downward so the
  /// viewport stays stable.
  Future<void> _fetchBackward() async {
    if (_isFetchingBackward) return;
    if (_loadedPages.isEmpty || _loadedPages.first <= 1) return;

    final prevPage = _loadedPages.first - 1;
    final gen = _fetchGeneration;
    _isFetchingBackward = true;
    try {
      var q = _controller.state.query.copyWith(
        page: prevPage,
        pageSize: widget._fetchSize,
      );
      if (!widget._fetchWithSorting) q = q.copyWith(clearSort: true);
      if (!widget._fetchWithFiltering) q = q.copyWith(params: const {});
      final result = await widget._fetchTask!(q);
      if (!mounted || _fetchGeneration != gen) return;

      _pageRowCounts[prevPage] = result.rows.length;

      // Evict the newest (bottom) page if the window is full.
      if (_loadedPages.length >= widget._windowPages) {
        final evictedPage = _loadedPages.removeLast();
        final evictedCount = _pageRowCounts.remove(evictedPage) ?? 0;
        _controller.removeLastRows(evictedCount);
        // Removing from the bottom does not shift visible content — no scroll
        // compensation needed.
      }

      _loadedPages.insert(0, prevPage);
      _controller.prependRows(result.rows, rowBuilder: widget._rowBuilder);

      // After prepending, the ListView inserts rows above the current offset.
      // Shift the scroll down by the added height to keep the viewport stable.
      final addedHeight = result.rows.length * widget._density.rowHeight;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_verticalScroll.hasClients) return;
        _verticalScroll.jumpTo(_verticalScroll.offset + addedHeight);
      });
    } catch (e) {
      if (mounted) _controller.setError(e);
    } finally {
      _isFetchingBackward = false;
    }
  }

  void _onInfiniteScroll() {
    if (!_verticalScroll.hasClients) return;
    final pos = _verticalScroll.position;
    // Lookahead = one full page worth of row height so fetches start early
    // enough to hide network latency before the user reaches the bottom.
    final lookahead = widget._fetchSize * widget._density.rowHeight;

    if (pos.pixels >= pos.maxScrollExtent - lookahead) {
      _fetchForward();
    }

    if (pos.pixels <= lookahead &&
        _loadedPages.isNotEmpty &&
        _loadedPages.first > 1) {
      _fetchBackward();
    }
  }
}
