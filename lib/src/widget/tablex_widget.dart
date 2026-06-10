import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'toolbar/_file_save.dart';

export 'tablex_types.dart';

part '_tablex_state_mixin.dart';
part '_tablex_state.dart';
part '_selection_summary_header.dart';

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
    Future<void> Function(String csv)? onExportSelectedCsv,
    Future<void> Function(Uint8List bytes)? onExportSelectedExcel,
    Future<void> Function(Uint8List bytes)? onExportSelectedPdf,
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
        _selectionSummaryBuilder = selectionSummaryBuilder,
        _onExportSelectedCsv = onExportSelectedCsv,
        _onExportSelectedExcel = onExportSelectedExcel,
        _onExportSelectedPdf = onExportSelectedPdf;

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
    Future<void> Function(String csv)? onExportSelectedCsv,
    Future<void> Function(Uint8List bytes)? onExportSelectedExcel,
    Future<void> Function(Uint8List bytes)? onExportSelectedPdf,
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
        _selectionSummaryBuilder = selectionSummaryBuilder,
        _onExportSelectedCsv = onExportSelectedCsv,
        _onExportSelectedExcel = onExportSelectedExcel,
        _onExportSelectedPdf = onExportSelectedPdf;

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
    Future<void> Function(String csv)? onExportSelectedCsv,
    Future<void> Function(Uint8List bytes)? onExportSelectedExcel,
    Future<void> Function(Uint8List bytes)? onExportSelectedPdf,
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
        _selectionSummaryBuilder = selectionSummaryBuilder,
        _onExportSelectedCsv = onExportSelectedCsv,
        _onExportSelectedExcel = onExportSelectedExcel,
        _onExportSelectedPdf = onExportSelectedPdf;

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
        _selectionSummaryBuilder = null,
        _onExportSelectedCsv = null,
        _onExportSelectedExcel = null,
        _onExportSelectedPdf = null;

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
  final Future<void> Function(String csv)? _onExportSelectedCsv;
  final Future<void> Function(Uint8List bytes)? _onExportSelectedExcel;
  final Future<void> Function(Uint8List bytes)? _onExportSelectedPdf;

  @override
  State<Tablex<T>> createState() => _TablexState<T>();
}
