import 'query.dart';

/// A single option in a server-driven filter dropdown.
///
/// [value] is the raw value sent back to the server; [label] is what the
/// user sees in the filter chip dialog.
class TablexActiveFilterValue {
  const TablexActiveFilterValue({required this.value, required this.label});

  final String value;
  final String label;
}

/// Describes a server-driven filter control shown in the filter bar.
///
/// Return one or more of these inside [TablexResponseMeta.filters] to make
/// the grid display interactive filter chips above the data rows.
///
/// [key] is the param key written to [TablexQuery.params] when the user
/// picks a value. [label] is the chip label. [values] lists all available
/// options. Set [singleSelect] to `true` to show radio buttons instead of
/// checkboxes in the filter dialog.
class TablexActiveFilter {
  const TablexActiveFilter({
    required this.key,
    required this.label,
    required this.values,
    this.singleSelect = false,
  });

  final String key;
  final String label;
  final List<TablexActiveFilterValue> values;

  /// When `true`, the filter dialog shows radio buttons (one choice at a time).
  final bool singleSelect;
}

/// Optional metadata returned alongside a [TablexFetchResult].
///
/// [filters] populates the interactive filter bar at the top of the grid.
/// [extra] can carry any domain-specific data your UI needs (e.g. aggregate
/// totals) — the grid itself ignores it.
class TablexResponseMeta {
  const TablexResponseMeta({
    this.filters = const [],
    this.extra = const {},
  });

  /// Server-driven filter controls to render in the filter bar.
  final List<TablexActiveFilter> filters;

  /// Arbitrary extra payload — ignored by the grid, available to your code.
  final Map<String, dynamic> extra;
}

/// The value your [TablexFetchTask] must resolve with.
///
/// [rows] contains the items for the current page (or batch for infinite
/// scroll). [totalRows] is the grand total across all pages — used to
/// compute pagination. [totalPages] is optional; if omitted it is derived
/// from `(totalRows / pageSize).ceil()`. [meta] is optional server-driven
/// metadata for filter chips and other extras.
///
/// **Cursor-based pagination:** return [nextCursor] (and optionally
/// [prevCursor]) to activate cursor mode. Once any result has a non-null
/// [nextCursor] the footer automatically switches — page pills are replaced
/// by a simple "Page N" indicator and the cursor history is managed
/// internally. Set [totalRows] only if your API provides a total count;
/// otherwise leave it at the default `0` (unknown).
///
/// ```dart
/// return TablexFetchResult(
///   rows: page.items,
///   nextCursor: page.nextToken,   // activates cursor mode
/// );
/// ```
class TablexFetchResult<T> {
  const TablexFetchResult({
    required this.rows,
    this.totalRows = 0,
    this.totalPages,
    this.nextCursor,
    this.prevCursor,
    this.meta,
  });

  /// Items to display on the current page / batch.
  final List<T> rows;

  /// Grand total row count across all pages.
  ///
  /// Defaults to `0` (unknown) — useful for cursor-based APIs that don't
  /// return a total count. The pagination footer hides the total when `0`.
  final int totalRows;

  /// Optional explicit page count. Derived from [totalRows] when omitted.
  final int? totalPages;

  /// Opaque cursor pointing to the start of the **next** page, or `null`
  /// when this is the last page. Returning a non-null value here activates
  /// cursor mode for the entire grid session.
  final String? nextCursor;

  /// Opaque cursor pointing to the start of the **previous** page.
  ///
  /// Optional — the footer maintains its own cursor history for
  /// back-navigation, so you only need this if your API provides it and you
  /// want to skip the history entirely on back-navigation.
  final String? prevCursor;

  /// Optional metadata for filter chips and extra payloads.
  final TablexResponseMeta? meta;

  int effectiveTotalPages(int pageSize) =>
      totalPages ??
      (totalRows > 0 ? (totalRows / pageSize).ceil() : 0);
}

/// Signature of the async data-fetch callback used by [Tablex.lazyPaged]
/// and [Tablex.infinite].
///
/// Receives the current [TablexQuery] (page, sort, filters, params) and
/// must return a [TablexFetchResult] with the matching page of data.
///
/// ```dart
/// fetchTask: (query) async {
///   final response = await api.getEmployees(
///     page: query.page,
///     pageSize: query.pageSize,
///     sortBy: query.sort?.field,
///     sortDir: query.sort?.direction.name,
///   );
///   return TablexFetchResult(
///     rows: response.items,
///     totalRows: response.total,
///   );
/// },
/// ```
typedef TablexFetchTask<T> = Future<TablexFetchResult<T>> Function(
  TablexQuery query,
);
