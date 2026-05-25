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
  });

  /// Current 1-based page number.
  final int page;

  /// Total number of pages given the current [pageSize] and [totalRows].
  final int totalPages;

  /// Total number of rows across all pages.
  final int totalRows;

  /// Current rows-per-page setting.
  final int pageSize;

  /// Navigate to an arbitrary page. Clamped to [1..totalPages].
  final void Function(int page) goToPage;

  /// Navigate to the previous page. No-op on page 1.
  final VoidCallback previousPage;

  /// Navigate to the next page. No-op on the last page.
  final VoidCallback nextPage;

  /// Change the page size. Resets to page 1.
  final void Function(int size) setPageSize;
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
  final bool enablePageJump;

  /// Fully replaces the built-in footer UI. Receives a [TablexPaginationInfo]
  /// with the current state and navigation callbacks.
  final TablexFooterBuilder? footerBuilder;

  @override
  State<TablexPaginationFooter<T>> createState() =>
      _TablexPaginationFooterState<T>();
}

class _TablexPaginationFooterState<T>
    extends State<TablexPaginationFooter<T>> {
  int _totalRows = 0;
  int _totalPages = 1;

  final Map<int, Future<TablexFetchResult<T>>> _inFlight = {};

  static const int _maxCachedPages = 10;
  final Map<int, _CachedPage<T>> _cache = {};
  final List<int> _evictionQueue = [];

  TablexQuery? _lastQuery;

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
  // Fetch logic
  // ---------------------------------------------------------------------------

  void _onRefreshSignal() {
    _invalidateCache();
    _fetchPage(widget.controller.state.query.page);
  }

  void _onControllerChanged() {
    final q = widget.controller.state.query;
    if (_lastQuery == null || _lastQuery != q) {
      final prev = _lastQuery;
      _lastQuery = q;
      if (prev == null) return;

      final sortChanged = prev.sort != q.sort;
      final paramsChanged = !_mapsEqual(prev.params, q.params);

      final onlySortOrFilter = sortChanged || paramsChanged;
      if (onlySortOrFilter) {
        if (sortChanged && !widget.fetchWithSorting) return;
        if (paramsChanged && !widget.fetchWithFiltering) return;
      }

      final cacheInvalid = (sortChanged && widget.fetchWithSorting) ||
          prev.pageSize != q.pageSize ||
          (paramsChanged && widget.fetchWithFiltering);

      if (cacheInvalid) _invalidateCache();
      _fetchPage(q.page);
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
    widget.controller.clearRows();
    widget.controller.clearSelection();
  }

  Future<void> _fetchPage(int page) async {
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
  // Navigation helpers exposed to the UI
  // ---------------------------------------------------------------------------

  void _goToPage(int page) {
    final clamped = page.clamp(1, _totalPages);
    widget.controller.goToPage(clamped);
    _fetchPage(clamped);
  }

  void _previousPage() {
    final current = widget.controller.state.query.page;
    if (current <= 1) return;
    widget.controller.previousPage();
    _fetchPage(current - 1);
  }

  void _nextPage() {
    final current = widget.controller.state.query.page;
    if (current >= _totalPages) return;
    widget.controller.nextPage();
    _fetchPage(current + 1);
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
        final page = q.page;
        final pageSize = q.pageSize;
        final start = (page - 1) * pageSize + 1;
        final end = (page * pageSize).clamp(0, _totalRows);

        final info = TablexPaginationInfo(
          page: page,
          totalPages: _totalPages,
          totalRows: _totalRows,
          pageSize: pageSize,
          goToPage: _goToPage,
          previousPage: _previousPage,
          nextPage: _nextPage,
          setPageSize: widget.controller.setPageSize,
        );

        if (widget.footerBuilder != null) {
          return widget.footerBuilder!(context, info);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 480;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: widget.theme.paginationBackgroundColor,
              child: wide
                  ? _WideFooter(
                      info: info,
                      start: start,
                      end: end,
                      pageSizeOptions: widget.pageSizeOptions,
                      theme: widget.theme,
                      enablePageJump: widget.enablePageJump,
                    )
                  : _NarrowFooter(
                      info: info,
                      start: start,
                      end: end,
                      pageSizeOptions: widget.pageSizeOptions,
                      theme: widget.theme,
                      enablePageJump: widget.enablePageJump,
                    ),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// Wide layout (>= 480 px)
// ============================================================================

class _WideFooter extends StatelessWidget {
  const _WideFooter({
    required this.info,
    required this.start,
    required this.end,
    required this.pageSizeOptions,
    required this.theme,
    required this.enablePageJump,
  });

  final TablexPaginationInfo info;
  final int start;
  final int end;
  final List<int> pageSizeOptions;
  final TablexThemeData theme;
  final bool enablePageJump;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          info.totalRows > 0
              ? tablexStrings(context).showing(start, end, info.totalRows)
              : tablexStrings(context).noResults,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        _PageNavigation(
          info: info,
          compact: enablePageJump,
          enablePageJump: enablePageJump,
        ),
        const SizedBox(width: 16),
        TablexPageSizeSelector(
          currentSize: info.pageSize,
          options: pageSizeOptions,
          onChanged: info.setPageSize,
          theme: theme,
        ),
      ],
    );
  }
}

// ============================================================================
// Narrow layout (< 480 px) — two rows
// ============================================================================

class _NarrowFooter extends StatelessWidget {
  const _NarrowFooter({
    required this.info,
    required this.start,
    required this.end,
    required this.pageSizeOptions,
    required this.theme,
    required this.enablePageJump,
  });

  final TablexPaginationInfo info;
  final int start;
  final int end;
  final List<int> pageSizeOptions;
  final TablexThemeData theme;
  final bool enablePageJump;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Navigation row — always compact on narrow screens
        _PageNavigation(
          info: info,
          compact: true,
          enablePageJump: enablePageJump,
        ),
        const SizedBox(height: 4),
        // Info + page size row
        Row(
          children: [
            Text(
              info.totalRows > 0
                  ? tablexStrings(context).showing(start, end, info.totalRows)
                  : tablexStrings(context).noResults,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            TablexPageSizeSelector(
              currentSize: info.pageSize,
              options: pageSizeOptions,
              onChanged: info.setPageSize,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// Page navigation — shared by wide and narrow
// ============================================================================

class _PageNavigation extends StatelessWidget {
  const _PageNavigation({
    required this.info,
    required this.compact,
    required this.enablePageJump,
  });

  final TablexPaginationInfo info;

  /// `true` = show only prev/[indicator]/next.
  /// `false` = show full page-number button list.
  final bool compact;
  final bool enablePageJump;

  @override
  Widget build(BuildContext context) {
    if (info.totalPages <= 1 && !enablePageJump) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: info.page > 1 ? info.previousPage : null,
          tooltip: tablexStrings(context).previous,
        ),
        if (compact || enablePageJump)
          _CompactPageIndicator(info: info, enablePageJump: enablePageJump)
        else
          ..._pageButtons(context),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: info.page < info.totalPages ? info.nextPage : null,
          tooltip: tablexStrings(context).next,
        ),
      ],
    );
  }

  List<Widget> _pageButtons(BuildContext context) {
    final pages = _pageWindow(info.page, info.totalPages);
    return [
      for (final p in pages)
        p == -1
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('…'),
              )
            : _PageButton(
                page: p,
                isSelected: p == info.page,
                onTap: () => info.goToPage(p),
              ),
    ];
  }

  List<int> _pageWindow(int current, int total) {
    if (total <= 7) return List.generate(total, (i) => i + 1);
    final result = <int>[];
    result.add(1);
    if (current - 2 > 2) result.add(-1);
    for (int p = (current - 2).clamp(2, total - 1);
        p <= (current + 2).clamp(2, total - 1);
        p++) {
      result.add(p);
    }
    if (current + 2 < total - 1) result.add(-1);
    result.add(total);
    return result;
  }
}

// ============================================================================
// Compact page indicator: "3 of 23" or editable "[ 3 ] of 23"
// ============================================================================

class _CompactPageIndicator extends StatefulWidget {
  const _CompactPageIndicator({
    required this.info,
    required this.enablePageJump,
  });

  final TablexPaginationInfo info;
  final bool enablePageJump;

  @override
  State<_CompactPageIndicator> createState() => _CompactPageIndicatorState();
}

class _CompactPageIndicatorState extends State<_CompactPageIndicator> {
  late final TextEditingController _text;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: '${widget.info.page}');
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_CompactPageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus &&
        oldWidget.info.page != widget.info.page) {
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
    if (!_focus.hasFocus) {
      _text.text = '${widget.info.page}';
    }
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
    final textStyle = Theme.of(context).textTheme.bodySmall;
    final cs = Theme.of(context).colorScheme;
    final muted = textStyle?.copyWith(color: cs.onSurfaceVariant);

    if (!widget.enablePageJump) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          '${widget.info.page} of ${widget.info.totalPages}',
          style: textStyle,
        ),
      );
    }

    final focused = _focus.hasFocus;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Page ', style: muted),
        Container(
          width: 52,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(
              color: focused ? cs.primary : cs.outlineVariant,
              width: focused ? 1.5 : 1.0,
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
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text('of ${widget.info.totalPages}', style: muted),
        ),
      ],
    );
  }
}

// ============================================================================
// Individual page button
// ============================================================================

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  final int page;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          '$page',
          style: TextStyle(
            color: isSelected ? cs.onPrimary : cs.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
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
