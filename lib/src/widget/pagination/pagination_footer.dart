import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/controller.dart';
import '../../model/query.dart';
import '../../model/response.dart';
import '../../model/row.dart';
import '../../theme/grid_theme_data.dart';
import '../../../i18n/strings.g.dart';
import 'page_size_selector.dart';

// ============================================================================
// Public pagination state — passed to footerBuilder
// ============================================================================

/// Snapshot of pagination state passed to [TablexFooterBuilder].
///
/// Use the provided callbacks to drive navigation; do not call
/// [TablexController] methods directly as the footer owns the page cache.
///
/// In cursor mode [isCursorMode] is `true`, [totalRows] / [totalPages] may
/// be `0` (unknown), and [goToPage] is a no-op for unvisited pages.
/// Use [hasNextPage] instead of `page < totalPages` to gate the next button.
class TablexPaginationInfo {
  const TablexPaginationInfo({
    required this.page,
    required this.totalPages,
    required this.totalRows,
    required this.pageSize,
    required this.goToPage,
    required this.previousPage,
    required this.nextPage,
    required this.setPageSize,
    this.isCursorMode = false,
    this.hasNextPage,
  });

  /// Current 1-based page number.
  final int page;

  /// Total number of pages given the current [pageSize] and [totalRows].
  /// May be `0` in cursor mode when the server does not return a total count.
  final int totalPages;

  /// Total number of rows across all pages.
  /// May be `0` in cursor mode when the server does not return a total count.
  final int totalRows;

  /// Current rows-per-page setting.
  final int pageSize;

  /// Navigate to an arbitrary page. Clamped to [1..totalPages].
  /// No-op for unvisited pages in cursor mode.
  final void Function(int page) goToPage;

  /// Navigate to the previous page. No-op on page 1.
  final VoidCallback previousPage;

  /// Navigate to the next page. No-op on the last page.
  final VoidCallback nextPage;

  /// Change the page size. Resets to page 1.
  final void Function(int size) setPageSize;

  /// `true` when the grid is using cursor-based (opaque-token) pagination.
  final bool isCursorMode;

  /// Whether a next page is available.
  /// When `null`, inferred as [page] < [totalPages] (offset mode).
  /// Always set explicitly in cursor mode.
  final bool? hasNextPage;
}

/// Builder that fully replaces the default pagination footer.
///
/// ```dart
/// footerBuilder: (context, info) => Row(
///   children: [
///     Text('Page ${info.page} of ${info.totalPages}'),
///     IconButton(icon: const Icon(Icons.chevron_right), onPressed: info.nextPage),
///   ],
/// ),
/// ```
typedef TablexFooterBuilder = Widget Function(
  BuildContext context,
  TablexPaginationInfo info,
);

// ============================================================================
// Widget
// ============================================================================

class TablexPaginationFooter<T> extends StatefulWidget {
  const TablexPaginationFooter({
    super.key,
    required this.controller,
    required this.fetchTask,
    required this.rowBuilder,
    required this.theme,
    this.pageSizeOptions = const [10, 13, 25, 50, 100],
    this.onFetchComplete,
    this.fetchWithSorting = true,
    this.fetchWithFiltering = true,
    this.enablePageJump = false,
    this.footerBuilder,
  });

  final TablexController<T> controller;
  final TablexFetchTask<T> fetchTask;
  final TablexRow<T> Function(T) rowBuilder;
  final TablexThemeData theme;
  final List<int> pageSizeOptions;
  final void Function(TablexFetchResult<T> result)? onFetchComplete;

  /// When `false`, sort changes do not trigger a re-fetch.
  final bool fetchWithSorting;

  /// When `false`, filter-param changes do not trigger a re-fetch.
  final bool fetchWithFiltering;

  /// When `true`, the current page indicator becomes an editable text field
  /// so users can jump directly to any page number.
  /// Ignored in cursor mode — arbitrary jumps are not supported.
  final bool enablePageJump;

  /// Fully replaces the built-in footer UI. Receives a [TablexPaginationInfo]
  /// with the current state and navigation callbacks.
  final TablexFooterBuilder? footerBuilder;

  @override
  State<TablexPaginationFooter<T>> createState() =>
      _TablexPaginationFooterState<T>();
}

// ============================================================================
// State
// ============================================================================

class _TablexPaginationFooterState<T> extends State<TablexPaginationFooter<T>> {
  // ---------------------------------------------------------------------------
  // Offset-mode state
  // ---------------------------------------------------------------------------
  int _totalRows = 0;
  int _totalPages = 1;

  final Map<int, Future<TablexFetchResult<T>>> _inFlight = {};

  static const int _maxCachedPages = 10;
  final Map<int, _CachedPage<T>> _cache = {};
  final List<int> _evictionQueue = [];

  TablexQuery? _lastQuery;

  // ---------------------------------------------------------------------------
  // Cursor-mode state
  // ---------------------------------------------------------------------------

  /// Set to `true` on the first result that has a non-null [nextCursor].
  /// Never reset to false — once cursor mode is detected it stays for the
  /// session (sort/filter resets restart from page 1 with a null cursor).
  bool _cursorMode = false;

  /// Cursor history. Index 0 is always `null` (first page, no cursor needed).
  /// Index N holds the cursor that fetches page N+1.
  ///
  /// ```
  /// index: 0     1       2       3
  ///        null  'c_1'   'c_2'   'c_3'   ...
  ///        ↑ page 1  ↑ page 2  ↑ page 3  ↑ page 4
  /// ```
  final List<String?> _cursorHistory = [null];

  /// 1-based current page position within [_cursorHistory].
  int _cursorPage = 1;

  /// `false` after a fetch returns `nextCursor == null` (reached the end).
  bool _cursorHasMore = true;

  /// Cache keyed by cursor string (empty string = first page / null cursor).
  final Map<String, _CachedPage<T>> _cursorCache = {};

  /// In-flight cursor fetches — prevents duplicate concurrent requests.
  final Map<String, Future<void>> _cursorInFlight = {};

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    widget.controller.refreshSignal.addListener(_onRefreshSignal);
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPage(1));
  }

  @override
  void dispose() {
    widget.controller.refreshSignal.removeListener(_onRefreshSignal);
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Controller listeners
  // ---------------------------------------------------------------------------

  void _onRefreshSignal() {
    _invalidateCache();
    _fetchPage(1);
  }

  void _onControllerChanged() {
    final q = widget.controller.state.query;
    if (_lastQuery == null || _lastQuery != q) {
      final prev = _lastQuery;
      _lastQuery = q;
      if (prev == null) return;

      final sortChanged = prev.sort != q.sort;
      final paramsChanged = !_mapsEqual(prev.params, q.params);

      if (sortChanged && !widget.fetchWithSorting) return;
      if (paramsChanged && !widget.fetchWithFiltering) return;

      final cacheInvalid = (sortChanged && widget.fetchWithSorting) ||
          prev.pageSize != q.pageSize ||
          (paramsChanged && widget.fetchWithFiltering);

      if (cacheInvalid) _invalidateCache();
      _fetchPage(_cursorMode ? _cursorPage : q.page);
    }
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  void _invalidateCache() {
    _cache.clear();
    _evictionQueue.clear();
    _cursorCache.clear();
    _cursorInFlight.clear();
    _cursorHistory
      ..clear()
      ..add(null);
    _cursorPage = 1;
    _cursorHasMore = true;
    widget.controller.clearRows();
    widget.controller.clearSelection();
  }

  // ---------------------------------------------------------------------------
  // Fetch routing
  // ---------------------------------------------------------------------------

  Future<void> _fetchPage(int page) async {
    if (_cursorMode) {
      // In cursor mode, `page` is a 1-based index into _cursorHistory.
      final idx = (page - 1).clamp(0, _cursorHistory.length - 1);
      await _fetchByCursor(_cursorHistory[idx], targetPage: page);
    } else {
      await _fetchByOffset(page);
    }
  }

  // ---------------------------------------------------------------------------
  // Offset-based fetch
  // ---------------------------------------------------------------------------

  Future<void> _fetchByOffset(int page) async {
    if (!mounted) return;

    if (_cache.containsKey(page)) {
      final cached = _cache[page]!;
      _totalRows = cached.totalRows;
      _totalPages = cached.totalPages;
      widget.controller.replaceRows(
        cached.items,
        rowBuilder: widget.rowBuilder,
        clearSelection: false,
      );
      if (mounted) setState(() {});
      return;
    }

    if (_inFlight.containsKey(page)) {
      await _inFlight[page];
      return;
    }

    widget.controller.setLoading(true);
    var q = widget.controller.state.query.copyWith(page: page);
    if (!widget.fetchWithSorting) q = q.copyWith(clearSort: true);
    if (!widget.fetchWithFiltering) q = q.copyWith(params: const {});
    final future = widget.fetchTask(q);
    _inFlight[page] = future;

    try {
      final result = await future;
      if (!mounted) return;

      // Auto-detect cursor mode from the first result.
      if (!_cursorMode && result.nextCursor != null) {
        _cursorMode = true;
        _cache.clear();
        _evictionQueue.clear();
        // Hand off to cursor-based fetch using the result we already have.
        _applyFetchResult(result, cursorKey: '', targetPage: 1);
        return;
      }

      _totalRows = result.totalRows;
      _totalPages = result.effectiveTotalPages(
        widget.controller.state.query.pageSize,
      );

      _cache[page] = _CachedPage<T>(
        items: result.rows,
        totalRows: result.totalRows,
        totalPages: _totalPages,
      );
      _evictionQueue.add(page);
      while (_evictionQueue.length > _maxCachedPages) {
        _cache.remove(_evictionQueue.removeAt(0));
      }

      widget.controller.replaceRows(result.rows, rowBuilder: widget.rowBuilder);
      if (result.meta != null) widget.controller.setMeta(result.meta);
      widget.controller.setError(null);
      widget.onFetchComplete?.call(result);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) widget.controller.setError(e);
    } finally {
      _inFlight.remove(page);
      if (mounted) widget.controller.setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Cursor-based fetch
  // ---------------------------------------------------------------------------

  Future<void> _fetchByCursor(String? cursor, {required int targetPage}) async {
    if (!mounted) return;

    final cacheKey = cursor ?? '';

    if (_cursorCache.containsKey(cacheKey)) {
      final cached = _cursorCache[cacheKey]!;
      _totalRows = cached.totalRows;
      _totalPages = cached.totalPages;
      _cursorPage = targetPage;
      widget.controller
          .replaceRows(cached.items, rowBuilder: widget.rowBuilder);
      if (mounted) setState(() {});
      return;
    }

    if (_cursorInFlight.containsKey(cacheKey)) {
      await _cursorInFlight[cacheKey];
      return;
    }

    widget.controller.setLoading(true);
    var q = widget.controller.state.query.copyWith(
      page: targetPage,
      cursor: cursor,
      clearCursor: cursor == null,
    );
    if (!widget.fetchWithSorting) q = q.copyWith(clearSort: true);
    if (!widget.fetchWithFiltering) q = q.copyWith(params: const {});

    final completer = Future<void>(() async {
      try {
        final result = await widget.fetchTask(q);
        if (!mounted) return;
        _applyFetchResult(result, cursorKey: cacheKey, targetPage: targetPage);
      } catch (e) {
        if (mounted) widget.controller.setError(e);
      } finally {
        _cursorInFlight.remove(cacheKey);
        if (mounted) widget.controller.setLoading(false);
      }
    });
    _cursorInFlight[cacheKey] = completer;
    await completer;
  }

  void _applyFetchResult(
    TablexFetchResult<T> result, {
    required String cursorKey,
    required int targetPage,
  }) {
    _cursorMode = true;
    _cursorPage = targetPage;

    if (result.totalRows > 0) {
      _totalRows = result.totalRows;
      _totalPages = result.effectiveTotalPages(
        widget.controller.state.query.pageSize,
      );
    }

    // Advance cursor history only when moving forward past known history.
    final nextCursor = result.nextCursor;
    _cursorHasMore = nextCursor != null;
    if (nextCursor != null && _cursorPage >= _cursorHistory.length) {
      _cursorHistory.add(nextCursor);
    }
    // If the API provided a prevCursor and we're missing history entries,
    // we can trust it for back-navigation.
    if (result.prevCursor != null && targetPage > 1) {
      final prevIdx = targetPage - 2;
      if (prevIdx < _cursorHistory.length) {
        _cursorHistory[prevIdx] = result.prevCursor;
      }
    }

    _cursorCache[cursorKey] = _CachedPage<T>(
      items: result.rows,
      totalRows: _totalRows,
      totalPages: _totalPages,
    );

    widget.controller.goToPage(_cursorPage);
    widget.controller.replaceRows(result.rows, rowBuilder: widget.rowBuilder);
    if (result.meta != null) widget.controller.setMeta(result.meta);
    widget.controller.setError(null);
    widget.onFetchComplete?.call(result);

    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _goToPage(int page) {
    if (_cursorMode) {
      // Can only navigate to pages we already have a cursor for.
      final clamped = page.clamp(1, _cursorHistory.length);
      _cursorPage = clamped;
      if (mounted) setState(() {});
      widget.controller.goToPage(clamped);
      _fetchByCursor(_cursorHistory[clamped - 1], targetPage: clamped);
      return;
    }
    final clamped = page.clamp(1, _totalPages);
    widget.controller.goToPage(clamped);
    _fetchByOffset(clamped);
  }

  void _previousPage() {
    if (_cursorMode) {
      if (_cursorPage <= 1) return;
      final prev = _cursorPage - 1;
      _cursorPage = prev;
      if (mounted) setState(() {});
      widget.controller.goToPage(prev);
      _fetchByCursor(_cursorHistory[prev - 1], targetPage: prev);
      return;
    }
    final current = widget.controller.state.query.page;
    if (current <= 1) return;
    widget.controller.previousPage();
    _fetchByOffset(current - 1);
  }

  void _nextPage() {
    if (_cursorMode) {
      // Block if we've reached the end.
      if (!_cursorHasMore && _cursorPage >= _cursorHistory.length - 1) return;
      // Block if the cursor for the next page hasn't arrived yet (fetch in
      // flight). Prevents a rapid double-tap from passing null as the cursor
      // and accidentally re-fetching page 1.
      if (_cursorHistory.length <= _cursorPage) return;
      final next = _cursorPage + 1;
      _cursorPage = next;
      if (mounted) setState(() {});
      widget.controller.goToPage(next);
      _fetchByCursor(_cursorHistory[next - 1], targetPage: next);
      return;
    }
    final current = widget.controller.state.query.page;
    if (current >= _totalPages) return;
    widget.controller.nextPage();
    _fetchByOffset(current + 1);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final q = widget.controller.state.query;
        final page = _cursorMode ? _cursorPage : q.page;
        final pageSize = q.pageSize;

        final hasNext = _cursorMode
            ? (_cursorHasMore ||
                _cursorHistory.length > _cursorPage ||
                page < _totalPages)
            : page < _totalPages;

        final info = TablexPaginationInfo(
          page: page,
          totalPages: _totalPages,
          totalRows: _totalRows,
          pageSize: pageSize,
          goToPage: _goToPage,
          previousPage: _previousPage,
          nextPage: _nextPage,
          setPageSize: widget.controller.setPageSize,
          isCursorMode: _cursorMode,
          hasNextPage: hasNext,
        );

        if (widget.footerBuilder != null) {
          return widget.footerBuilder!(context, info);
        }

        return _DefaultPaginationFooter(
          info: info,
          isLoading: widget.controller.state.isLoading,
          pageSizeOptions: widget.pageSizeOptions,
          theme: widget.theme,
          enablePageJump: widget.enablePageJump && !_cursorMode,
        );
      },
    );
  }
}

// ============================================================================
// Default footer UI
// ============================================================================

class _DefaultPaginationFooter extends StatelessWidget {
  const _DefaultPaginationFooter({
    required this.info,
    required this.isLoading,
    required this.pageSizeOptions,
    required this.theme,
    required this.enablePageJump,
  });

  final TablexPaginationInfo info;
  final bool isLoading;
  final List<int> pageSizeOptions;
  final TablexThemeData theme;
  final bool enablePageJump;

  @override
  Widget build(BuildContext context) {
    final totalPages = info.totalPages <= 0 ? 1 : info.totalPages;
    final currentPage = info.page.clamp(1, totalPages);
    final hasPrev = currentPage > 1;
    final hasNext = info.hasNextPage ?? (currentPage < totalPages);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2 px loading strip — always reserves the height so the layout
        // doesn't shift when loading starts/stops.
        SizedBox(
          height: 2,
          child: isLoading
              ? LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.6),
                )
              : null,
        ),
        // Nav row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: theme.paginationBackgroundColor,
          child: Row(
            children: [
              // Page navigation — centred so the pill row sits in the middle
              // regardless of the page-size widget width.
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NavButton(
                          label: tablexStrings(context).previous,
                          icon: Icons.chevron_left,
                          enabled: hasPrev,
                          onPressed: info.previousPage,
                        ),
                        const SizedBox(width: 4),
                        if (info.isCursorMode)
                          _CursorPageIndicator(page: currentPage)
                        else if (enablePageJump)
                          _PageJumpIndicator(info: info, totalPages: totalPages)
                        else
                          ..._buildPagePills(
                              context, currentPage, totalPages, info),
                        const SizedBox(width: 4),
                        _NavButton(
                          label: tablexStrings(context).next,
                          icon: Icons.chevron_right,
                          enabled: hasNext,
                          onPressed: info.nextPage,
                          iconAfter: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Page-size selector — right-aligned.
              TablexPageSizeSelector(
                currentSize: info.pageSize,
                options: pageSizeOptions,
                onChanged: info.setPageSize,
                theme: theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPagePills(
    BuildContext context,
    int current,
    int total,
    TablexPaginationInfo info,
  ) {
    if (total <= 1) return [];

    const window = 3;
    var start = current - (window ~/ 2);
    if (start < 1) start = 1;
    var end = start + window - 1;
    if (end > total) {
      end = total;
      start = (end - window + 1).clamp(1, total);
    }

    final pages = [for (var p = start; p <= end; p++) p];
    final showLeading = pages.first > 1;
    final showTrailing = pages.last < total;

    return [
      if (showLeading) ...[
        _PagePill(
            page: 1, isActive: current == 1, onPressed: () => info.goToPage(1)),
        const _Ellipsis(),
      ],
      for (final p in pages)
        _PagePill(
            page: p, isActive: p == current, onPressed: () => info.goToPage(p)),
      if (showTrailing) ...[
        const _Ellipsis(),
        _PagePill(
            page: total,
            isActive: total == current,
            onPressed: () => info.goToPage(total)),
      ],
    ];
  }
}

// ============================================================================
// Nav button  (← Previous / Next →)
// ============================================================================

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.iconAfter = false,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final bool iconAfter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38);
    final iconWidget = Icon(icon, size: 16, color: color);
    final textWidget = Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    );

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconAfter
              ? [textWidget, const SizedBox(width: 4), iconWidget]
              : [iconWidget, const SizedBox(width: 4), textWidget],
        ),
      ),
    );
  }
}

// ============================================================================
// Page pill
// ============================================================================

class _PagePill extends StatelessWidget {
  const _PagePill({
    required this.page,
    required this.isActive,
    required this.onPressed,
  });

  final int page;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = Text(
      '$page',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? cs.onSurface : null,
          ),
    );

    if (isActive) {
      return Container(
        constraints: const BoxConstraints(minWidth: 32),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: label,
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minWidth: 32),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        child: label,
      ),
    );
  }
}

// ============================================================================
// Ellipsis separator
// ============================================================================

class _Ellipsis extends StatelessWidget {
  const _Ellipsis();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(
        Icons.more_horiz,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ============================================================================
// Cursor mode: current page number indicator (non-interactive)
// ============================================================================

class _CursorPageIndicator extends StatelessWidget {
  const _CursorPageIndicator({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall;
    final label = page.toString();

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(label, style: style?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

// ============================================================================
// Offset mode + enablePageJump: editable "[ 3 ] of 23" indicator
// ============================================================================

class _PageJumpIndicator extends StatefulWidget {
  const _PageJumpIndicator({required this.info, required this.totalPages});

  final TablexPaginationInfo info;
  final int totalPages;

  @override
  State<_PageJumpIndicator> createState() => _PageJumpIndicatorState();
}

class _PageJumpIndicatorState extends State<_PageJumpIndicator> {
  late final TextEditingController _text;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: '${widget.info.page}');
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_PageJumpIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && oldWidget.info.page != widget.info.page) {
      _text.text = '${widget.info.page}';
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) _text.text = '${widget.info.page}';
    if (mounted) setState(() {});
  }

  void _submit(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      widget.info.goToPage(parsed);
    } else {
      _text.text = '${widget.info.page}';
    }
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall;
    final focused = _focus.hasFocus;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(
              color: focused ? cs.primary : cs.outlineVariant,
              width: focused ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _text,
            focusNode: _focus,
            textAlign: TextAlign.center,
            style: textStyle?.copyWith(fontWeight: FontWeight.w600),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4),
            ),
            onSubmitted: _submit,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Private helpers
// ============================================================================

class _CachedPage<T> {
  _CachedPage({
    required this.items,
    required this.totalRows,
    required this.totalPages,
  });

  final List<T> items;
  final int totalRows;
  final int totalPages;
}
