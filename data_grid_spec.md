# Flutter Data Grid Package — Design Specification

> This document is a self-contained specification for building a production-grade, fully custom
> Flutter data grid package. It describes every required feature, expected behavior, API contract,
> and architectural rule. An implementation agent should be able to build the package from this
> document alone with no external context.

---

## 0. Goals and Non-Goals

### Goals
- A Flutter data grid with **zero dependency on any third-party grid engine**
- Clean, type-safe public API — callers never touch internal rendering types
- A single package that covers all common data presentation patterns: static lists, server-paged
  tables, infinite scroll, and selection pickers
- The controller owns all state — column visibility, selection, query, loading — and is a plain
  `ChangeNotifier` that callers can listen to normally
- All lifecycle management is correct by design — no "used after disposed" crashes, no double
  dispose, no listeners attached to dead objects
- Full RTL support throughout — layout, freeze direction, and text alignment all flip with
  `Directionality`
- Designed for web and desktop as well as mobile — bi-axial virtualization, hover states,
  keyboard navigation, copy-to-clipboard

### Non-Goals
- This package does **not** wrap PlutoGrid, SyncFusion, or any other existing grid engine
- This package does **not** provide a backend API client — callers supply a fetch function
- Row drag-to-reorder is deferred to v2
- In-line cell editing is optional and can be deferred to v2
- Excel/XLSX export is deferred to v2

---

## 1. Package Structure

```
app_data_grid/
├── lib/
│   ├── app_data_grid.dart              ← public barrel; only this file is imported by callers
│   └── src/
│       ├── model/
│       │   ├── column.dart             ← AppDataColumn<TRow, TValue> + base class
│       │   ├── row.dart                ← AppDataRow<T>
│       │   ├── query.dart              ← AppDataGridQuery, AppColumnSort, AppColumnFilter
│       │   ├── response.dart           ← AppGridFetchResult<T>, AppGridResponseMeta
│       │   └── enums.dart              ← AppGridDensity, AppColumnFrozen, AppSelectionMode,
│       │                                  AppColumnType, AppSortDirection, AppFilterOperator
│       ├── controller/
│       │   ├── controller.dart         ← AppDataGridController<T>
│       │   └── state.dart              ← AppDataGridState<T>
│       ├── widget/
│       │   ├── app_data_grid.dart      ← top-level factory widget (4 named constructors)
│       │   ├── consumer.dart           ← AppDataGridConsumer<T> convenience wrapper
│       │   ├── core/
│       │   │   ├── grid_layout.dart    ← root layout widget
│       │   │   ├── header_row.dart     ← column headers + resize handles
│       │   │   ├── body.dart           ← virtualized row list
│       │   │   ├── row.dart            ← single row widget
│       │   │   ├── cell.dart           ← single cell widget
│       │   │   ├── footer_row.dart     ← per-column footer cells
│       │   │   └── column_group_header.dart
│       │   ├── pagination/
│       │   │   ├── pagination_footer.dart
│       │   │   └── page_size_selector.dart
│       │   ├── selection/
│       │   │   ├── selection_summary_bar.dart
│       │   │   └── checkbox_cell.dart
│       │   └── column_manager/
│       │       └── column_manager_button.dart
│       ├── renderer/
│       │   ├── cell_renderers.dart     ← all built-in static cell renderer factories
│       │   └── cell_context.dart       ← AppGridCellContext passed to every renderer
│       └── theme/
│           ├── grid_theme_data.dart    ← AppGridThemeData
│           └── grid_theme.dart         ← InheritedWidget that provides the theme
```

**Rule**: Nothing from `src/` is re-exported except through `app_data_grid.dart`. Internal widgets
and helpers are not part of the public API.

---

## 2. Data Models

### 2.1 `AppDataRow<T>`

A thin wrapper that associates a domain object with its display values and a stable identity key.

```dart
class AppDataRow<T> {
  const AppDataRow({
    required this.data,       // the domain object this row represents
    required this.cells,      // Map<String, dynamic>  field → display value
    this.key,                 // optional stable string; auto-generated (UUID) if null
    this.checked = false,     // initial checkbox state
  });

  final T data;
  final Map<String, dynamic> cells;
  final String? key;
  final bool checked;
}
```

**Behavior**:
- The `key` is used as the stable identity for selection tracking and page-cache eviction.
  If null, the grid generates one at registration time.
- `cells` values are what get passed to renderers and formatters. The caller populates them from
  the domain object in `rowBuilder`.
- `data` is recovered from the grid in all user-facing callbacks (tap, selection, export).

---

### 2.2 Column Model

#### `AppDataColumn<TRow>` — abstract base

```dart
abstract class AppDataColumn<TRow> {
  const AppDataColumn({
    required this.field,
    required this.title,
    this.width,
    this.minWidth = 100,
    this.frozen = AppColumnFrozen.none,
    this.hide = false,
    this.enableSorting = true,
    this.enableFiltering = true,
    this.enableEditing = false,
    this.enableContextMenu = true,
    this.textAlign = TextAlign.start,
    this.backgroundColor,
    this.emptyCellPlaceholder,
    this.showEmptyAsDash = true,
    this.type = AppColumnType.text,
    this.footerRenderer,
  });

  final String field;            // unique key; matches AppDataRow.cells keys
  final String title;            // header label
  final double? width;           // initial width; null = grid decides
  final double minWidth;         // floor during resize; default 100
  final AppColumnFrozen frozen;  // none | start | end
  final bool hide;               // initially hidden
  final bool enableSorting;
  final bool enableFiltering;
  final bool enableEditing;
  final bool enableContextMenu;
  final TextAlign textAlign;     // resolved against Directionality at render time
  final Color? backgroundColor;
  final String? emptyCellPlaceholder; // overrides the default "—"
  final bool showEmptyAsDash;    // show "—" for null/empty values; default true
  final AppColumnType type;
  final Widget Function(AppColumnFooterContext context)? footerRenderer;

  // Subclasses implement these:
  Widget? buildCell(TRow row, dynamic rawValue, AppGridCellContext context);
  dynamic extractValue(TRow row);
}
```

#### `AppDataGridColumn<TRow, TValue>` — the concrete typed column

```dart
class AppDataGridColumn<TRow, TValue> extends AppDataColumn<TRow> {
  const AppDataGridColumn({
    required super.field,
    required super.title,
    required this.valueGetter,   // TValue Function(TRow) — type-safe extraction
    this.cellRenderer,           // typed renderer; null = default text rendering
    this.formatter,              // String Function(TValue) — custom display string
    // ... all super params
  });

  final TValue Function(TRow row) valueGetter;
  final Widget Function(TRow row, TValue value, AppGridCellContext context)? cellRenderer;
  final String Function(TValue value)? formatter;
}
```

**Rules**:
- `cellRenderer` receives `TValue`, not `dynamic`. The base class handles the cast internally.
- When `cellRenderer` is null and `formatter` is null, the cell renders `value.toString()`.
- When `cellRenderer` is null and `formatter` is set, the cell renders `formatter(value)` as text.
- When `cellRenderer` is set, it takes full control of the cell widget. The `emptyCellPlaceholder`
  is NOT applied — the renderer is responsible for handling null/empty.
- `valueGetter` is called at row-build time to produce the value stored in `AppDataRow.cells[field]`.

#### `AppGridCellContext`

Passed to every `cellRenderer` call. No internal grid types.

```dart
class AppGridCellContext {
  const AppGridCellContext({
    required this.rowIndex,
    required this.isHovered,
    required this.isSelected,
    required this.isEditing,
    required this.textDirection,
    required this.density,
    required this.column,
  });

  final int rowIndex;
  final bool isHovered;
  final bool isSelected;
  final bool isEditing;
  final TextDirection textDirection;
  final AppGridDensity density;
  final AppDataColumn column;
}
```

#### `AppColumnFooterContext`

Passed to `footerRenderer`. No internal grid types.

```dart
class AppColumnFooterContext {
  const AppColumnFooterContext({
    required this.field,
    required this.column,
    required this.allRowData,      // List<T> — every registered domain object
    required this.visibleRowData,  // List<T> — only currently visible rows
  });
}
```

#### `AppColumnGroup`

For nested column headers.

```dart
class AppColumnGroup {
  const AppColumnGroup({
    required this.title,
    this.fields,       // leaf group: list of column fields under this header
    this.children,     // nested groups (mutually exclusive with fields)
    this.backgroundColor,
    this.titleTextAlign = TextAlign.center,
  });
  // Either fields or children must be non-null; never both.
}
```

---

### 2.3 Query and Filter Models

```dart
class AppDataGridQuery {
  const AppDataGridQuery({
    this.page = 1,
    this.pageSize = 25,
    this.sort,
    this.filters = const [],
    this.params = const {},       // arbitrary extra server params
  });

  final int page;
  final int pageSize;
  final AppColumnSort? sort;
  final List<AppColumnFilter> filters;
  final Map<String, dynamic> params;

  AppDataGridQuery copyWith({...});
  bool operator ==(Object other);   // deep equality via DeepCollectionEquality
  int get hashCode;
}

class AppColumnSort {
  const AppColumnSort({required this.field, required this.direction});
  final String field;
  final AppSortDirection direction;  // ascending | descending
}

class AppColumnFilter {
  const AppColumnFilter({
    required this.field,
    required this.operator,
    required this.value,
    this.valueTo,    // only used for 'between' operator
  });
  final String field;
  final AppFilterOperator operator;
  final dynamic value;
  final dynamic valueTo;
}

enum AppFilterOperator {
  equals, notEquals,
  contains, notContains,
  startsWith, endsWith,
  greaterThan, greaterThanOrEqual,
  lessThan, lessThanOrEqual,
  between,
  isNull, isNotNull,
}
```

---

### 2.4 Fetch Result

**All async grid variants use the same fetch signature** — no split between "returns List" and
"returns Response object" depending on variant.

```dart
typedef AppGridFetchTask<T> = Future<AppGridFetchResult<T>> Function(AppDataGridQuery query);

class AppGridFetchResult<T> {
  const AppGridFetchResult({
    required this.rows,
    required this.totalRows,
    this.totalPages,           // optional; grid calculates from totalRows/pageSize if null
    this.meta,
  });

  final List<T> rows;
  final int totalRows;
  final int? totalPages;
  final AppGridResponseMeta? meta;

  int effectiveTotalPages(int pageSize) =>
      totalPages ?? (totalRows / pageSize).ceil();
}

class AppGridResponseMeta {
  const AppGridResponseMeta({
    this.filters = const [],   // active server-side filters for display in filter bar
    this.extra = const {},     // any additional metadata from the server
  });

  final List<AppActiveFilter> filters;  // shown as dismissible pills
  final Map<String, dynamic> extra;
}

class AppActiveFilter {
  const AppActiveFilter({
    required this.key,
    required this.label,
    required this.values,      // List<AppActiveFilterValue>
    this.singleSelect = false,
  });
  final String key;
  final String label;
  final List<AppActiveFilterValue> values;
  final bool singleSelect;
}

class AppActiveFilterValue {
  const AppActiveFilterValue({required this.value, required this.label});
  final String value;
  final String label;
}
```

---

### 2.5 Enums

```dart
enum AppGridDensity {
  comfortable,  // rowHeight: 66, headerHeight: 56
  standard,     // rowHeight: 56, headerHeight: 52
  compact,      // rowHeight: 46, headerHeight: 44
}

enum AppColumnFrozen { none, start, end }

enum AppSelectionMode { none, single, multiple }

enum AppColumnType {
  text,       // plain string
  number,     // numeric; right-aligned by default
  currency,   // monetary; right-aligned, negative color
  date,       // date only
  dateTime,   // date + time (distinct from date — does not lose time component)
  boolean,    // true/false
  select,     // enum/status value
  action,     // cell contains action buttons; not sortable, not filterable
  id,         // special: renders a checkbox for row selection; not sortable, not filterable
}

enum AppSortDirection { ascending, descending }
```

---

## 3. Controller

The controller is the **single source of truth** for all grid state. It extends `ChangeNotifier`.
Callers can listen to it with `ListenableBuilder`, `AnimatedBuilder`, or any listener pattern.

### 3.1 State

```dart
class AppDataGridState<T> {
  const AppDataGridState({
    this.isLoading = false,
    this.isInitialized = false,
    this.query = const AppDataGridQuery(),
    this.selectedRows = const [],
    this.hiddenColumnFields = const {},   // Set<String> — controller owns this
    this.columnWidths = const {},         // Map<String, double> — resize state
    this.meta,
    this.error,
  });

  final bool isLoading;
  final bool isInitialized;
  final AppDataGridQuery query;
  final List<T> selectedRows;
  final Set<String> hiddenColumnFields;   // serializable; can be persisted/restored
  final Map<String, double> columnWidths; // per-field override widths from resize
  final AppGridResponseMeta? meta;
  final Object? error;

  AppDataGridState<T> copyWith({...});
}
```

**Rule**: Column visibility is a `Set<String>` in the state — NOT stored inside any rendering
engine. This means it can be serialized, persisted to shared preferences, or driven by a Riverpod
provider without touching internal grid objects.

**Rule**: Column resize widths are also in state — NOT in the render tree. A theme change or parent
rebuild must never reset column widths.

### 3.2 Row Management

```dart
// Full replace — resets the data map and optionally clears selection
void replaceRows(List<T> items, {
  required AppDataRow<T> Function(T) rowBuilder,
  bool clearSelection = true,
});

// Append — used by infinite scroll; does NOT clear existing rows
void appendRows(List<T> items, {
  required AppDataRow<T> Function(T) rowBuilder,
});

// In-place update of a single row by index — updates cells and domain object
void updateRow(int index, T item, {
  required AppDataRow<T> Function(T) rowBuilder,
});

void removeRow(int index);
void removeRowsByKey(List<String> keys);
void clearRows();

// Recover the typed domain object from a stable row key
T? getRowData(String rowKey);
List<T> getAllRowData();
```

**Rule**: Every callback that exposes a row to the caller (tap, double-tap, selection change)
provides the typed `T` object — never a row index alone.

### 3.3 Query Management

```dart
void updateQuery(AppDataGridQuery query);        // full replace; no-op if equal
void setParam(String key, dynamic value, {bool resetPage = true});
void removeParam(String key, {bool resetPage = true});
void clearParams({bool resetPage = true});
void goToPage(int page);
void nextPage();
void previousPage();
void setPageSize(int size);      // always resets to page 1
void setSort(AppColumnSort? sort);
void setFilters(List<AppColumnFilter> filters);
void refresh();                  // triggers a re-fetch without changing the query
void setLoading(bool loading);
void setMeta(AppGridResponseMeta? meta);
void setError(Object? error);
```

**Rule**: Any query mutation that would change the result set (param change, filter, sort) must
reset the page to 1. The `resetPage` flag on `setParam`/`removeParam`/`clearParams` controls this
and defaults to `true`.

**Rule**: `updateQuery` is a no-op when the new query is equal to the current one (using deep
equality). This prevents infinite rebuild loops when a parent widget passes a query on every build.

### 3.4 Selection

```dart
void selectRow(T item);
void deselectRow(T item);
void toggleRowSelection(T item);
void setSelection(List<T> items);
void clearSelection();
void selectAll(List<T> allItems);   // bulk-select provided list

List<T> get selectedRows;
bool isSelected(T item);
```

**Rule**: Selection equality uses the domain object's own `==`. Callers are responsible for
ensuring their domain objects have correct `==` and `hashCode` implementations.

**Rule**: When `selectionMode == AppSelectionMode.single`, calling `selectRow` automatically
deselects any currently selected row before selecting the new one.

### 3.5 Column Visibility and Resize

```dart
void setColumnHidden(String field, bool hidden);
void toggleColumnHidden(String field);
bool isColumnHidden(String field);
List<String> get hiddenColumnFields;

void setColumnWidth(String field, double width);  // called by resize handle drag
void resetColumnWidths();
```

### 3.6 Hover and Scroll

```dart
// Called by the grid body on pointer move; coalesced to one per frame
void setHoveredRow(int? rowIndex);
int? get hoveredRowIdx;

void scrollToRow(int index);
void scrollToTop();
```

**Rule**: Hover events from the pointer must be coalesced to one update per frame using
`WidgetsBinding.instance.addPostFrameCallback`. Calling `setHoveredRow` on every raw pointer
event would cause excessive rebuilds and jank on fast mouse movement.

### 3.7 Refresh Signal

```dart
ValueListenable<int> get refreshSignal;
```

A `ValueNotifier<int>` that increments on every `refresh()` call. The pagination footer listens
to this to trigger a re-fetch without the caller needing to know about internal footer state.

### 3.8 Export

```dart
String exportToCsv();
```

**Behavior**:
- Iterates all registered rows in insertion order
- Uses `column.formatter` if set; otherwise `value.toString()`
- Skips hidden columns
- Sanitizes cell values that start with `=`, `+`, `-`, `@` by prepending `'` (prevents formula
  injection when opened in spreadsheet apps)
- Returns a UTF-8 CSV string with header row

### 3.9 Lifecycle

```dart
@override
void dispose();
```

**Rules**:
- `dispose()` clears all row data, nulls all internal references, disposes the refresh signal,
  and calls `super.dispose()`
- After `dispose()`, calling any method on the controller must be a no-op or throw `StateError`
  — never silently corrupt state
- The grid widget that creates the controller (when no external controller is provided) disposes
  it in its own `dispose()`. The grid widget that receives an external controller does NOT dispose
  it — ownership stays with the caller.

---

## 4. Widget API

### 4.1 `AppDataGrid<T>` — 4 named constructors

#### Static (in-memory list)

```dart
AppDataGrid.static({
  required List<AppDataColumn<T>> columns,
  required List<T> rows,
  required AppDataRow<T> Function(T) rowBuilder,
  AppDataGridController<T>? controller,
  AppGridDensity density = AppGridDensity.comfortable,
  AppSelectionMode selectionMode = AppSelectionMode.none,
  List<T>? initialSelection,
  void Function(T row)? onRowTap,
  void Function(T row)? onRowDoubleTap,
  void Function(List<T> selected)? onSelectionChanged,
  bool enableColumnResize = true,
  bool enableColumnReorder = false,
  bool showHeader = true,
  List<AppColumnGroup>? columnGroups,
  Widget? noDataWidget,
  Widget? loadingWidget,
  Widget Function(AppDataGridController<T> controller)? tableHeader,
})
```

**Behavior**:
- Rows are built once via `rowBuilder` and registered in the controller
- When `rows` changes in `didUpdateWidget`, the controller's rows are replaced via `replaceRows`
- `didUpdateWidget` uses `listEquals` to avoid unnecessary rebuilds

#### Lazy Paged (server-side paging)

```dart
AppDataGrid.lazyPaged({
  required List<AppDataColumn<T>> columns,
  required AppGridFetchTask<T> fetchTask,
  required AppDataRow<T> Function(T) rowBuilder,
  AppDataGridController<T>? controller,
  AppGridDensity density = AppGridDensity.comfortable,
  AppSelectionMode selectionMode = AppSelectionMode.none,
  void Function(T row)? onRowTap,
  void Function(T row)? onRowDoubleTap,
  void Function(List<T> selected)? onSelectionChanged,
  bool enableColumnResize = true,
  bool enableColumnReorder = false,
  bool showHeader = true,
  bool fetchWithSorting = true,
  bool fetchWithFiltering = true,
  bool hideEmptyColumns = false,
  int initialPageSize = 25,
  List<AppColumnGroup>? columnGroups,
  Widget? noDataWidget,
  Widget? loadingWidget,
  Widget Function(AppDataGridController<T> controller)? tableHeader,
  Key? paginationKey,
})
```

**Behavior**:
- Displays a pagination footer with page selector, page-size dropdown, and total count
- Fetches are triggered by: initial load, page change, `controller.refresh()`, sort (if
  `fetchWithSorting: true`), filter (if `fetchWithFiltering: true`), query param changes
- A page cache (default max 10 pages, FIFO eviction) prevents re-fetching already-loaded pages
- When the cache is evicted, those rows are unregistered from the controller data map
- Cache is invalidated (cleared) on: sort change, filter change, param change, `refresh()`
- While loading (before first page arrives): shows `loadingWidget` if provided, otherwise shows
  a skeleton shimmer over the column headers
- After first page: `noDataWidget` is shown if `totalRows == 0`
- Duplicate concurrent fetches for the same page are deduplicated — only one in-flight request
  per page at a time
- `hideEmptyColumns: true` auto-hides columns where every visible row has a null/empty value;
  re-shows them on cache invalidation; never hides columns that were explicitly hidden via
  `column.hide = true`

#### Infinite Scroll

```dart
AppDataGrid.infinite({
  required List<AppDataColumn<T>> columns,
  required AppGridFetchTask<T> fetchTask,
  required AppDataRow<T> Function(T) rowBuilder,
  AppDataGridController<T>? controller,
  AppGridDensity density = AppGridDensity.comfortable,
  AppSelectionMode selectionMode = AppSelectionMode.none,
  void Function(T row)? onRowTap,
  void Function(T row)? onRowDoubleTap,
  void Function(List<T> selected)? onSelectionChanged,
  bool enableColumnResize = true,
  bool enableColumnReorder = false,
  bool fetchWithSorting = true,
  bool fetchWithFiltering = true,
  int fetchSize = 50,
  int? maxCachedRows,   // evict oldest rows when total exceeds this
  List<AppColumnGroup>? columnGroups,
  Widget? noDataWidget,
  Widget? loadingWidget,
})
```

**Behavior**:
- No pagination footer — rows append as the user scrolls toward the bottom
- Fetch is triggered when the scroll position is within 200 logical pixels of the bottom
- A `_isFetching` guard prevents duplicate concurrent fetches
- A `_lastRequestedPage` guard prevents requesting the same page twice
- When `maxCachedRows` is set, the oldest page-worth of rows is removed from the controller
  when the total exceeds the limit (FIFO eviction via a queue of page sizes)
- Sort/filter changes clear all rows and restart from page 1

#### Select (picker mode)

```dart
AppDataGrid.select({
  required List<AppDataColumn<T>> columns,
  required List<T> rows,
  required AppDataRow<T> Function(T) rowBuilder,
  AppDataGridController<T>? controller,
  AppGridDensity density = AppGridDensity.compact,
  bool multiSelect = false,
  List<T>? initialSelection,
  void Function(List<T> selected)? onSelectionChanged,
  bool showHeader = true,
  List<AppColumnGroup>? columnGroups,
  Widget? noDataWidget,
})
```

**Behavior**:
- Tapping a row immediately selects/deselects it (single-tap selection, no double-tap needed)
- When `multiSelect: false`, tapping a second row deselects the first
- No resize, reorder, sort, or filter controls are shown

---

### 4.2 `AppDataGridConsumer<T>` — Convenience Wrapper

The most commonly used entry point. Wraps `AppDataGrid.lazyPaged` inside a bordered/rounded
container with an optional header slot, optional filter slot, and built-in selection summary bar.

```dart
AppDataGridConsumer({
  required List<AppDataColumn<T>> columns,
  required AppGridFetchTask<T> fetchTask,
  AppDataGridController<T>? controller,
  AppDataRow<T> Function(T)? rowBuilder,    // if null, auto-built from columns
  Widget? tableHeader,                      // rendered above the grid
  Widget? tableFilter,                      // rendered between header and grid
  int initialPageSize = 13,
  Key? paginationKey,
  AppSelectionMode selectionMode = AppSelectionMode.none,
  void Function(T)? onRowTap,
  void Function(T)? onRowDoubleTap,
  void Function(List<T>)? onSelectionChanged,
  bool showHeader = true,
  bool enableColumnResize = true,
  bool enableColumnReorder = false,
  bool fetchWithSorting = true,
  bool fetchWithFiltering = true,
  double? tableHeight,               // constrains height when parent is unbounded
  Widget? noDataWidget,
  Widget? loadingWidget,
  bool showSelectionSummary = false,
  Widget Function(
    BuildContext context,
    int count,
    VoidCallback onClear,
  )? selectionSummaryBuilder,
  List<AppGridSelectionAction<T>>? selectionActions,
  bool includeClearSelectionAction = true,
  EdgeInsetsGeometry margin,
  List<AppColumnGroup>? columnGroups,
})
```

**Always-on behaviors in `AppDataGridConsumer`**:
- `hideEmptyColumns: true` is always set
- When `controller.currentMeta?.filters` is non-empty, an `AppGridFilterBar` is rendered
  between `tableFilter` and the grid — shows active server-side filters as dismissible pills
- When `showSelectionSummary: true` and `controller.selectedRows` is non-empty, a summary bar
  appears below the grid showing the count and a clear button
- Wrapped in a `ClipRRect` with rounded corners and a subtle border using the theme's surface
  container color
- If `tableHeight` is set and the parent provides unbounded height, the grid is wrapped in
  `SizedBox(height: tableHeight)`; otherwise it expands to fill available height

---

### 4.3 `AppDataGridColumnManagerButton<T>`

A button (icon or labeled) that opens a popup checklist for toggling column visibility.

```dart
AppDataGridColumnManagerButton({
  required AppDataGridController<T> controller,
  required List<AppDataColumn<T>> columns,
  Widget? icon,
  double menuWidth = 220,
  String? title,
  bool Function(AppDataColumn<T>)? columnPredicate,  // filter which cols appear
  bool listenToController = true,
})
```

**Behavior**:
- Each column in the popup shows a checkmark when visible and a empty box when hidden
- Tapping a column calls `controller.toggleColumnHidden(field)`
- If `columnPredicate` is set, only columns where `predicate(col) == true` appear in the list
- Rebuilds on controller change when `listenToController: true`

---

## 5. Internal Architecture

### 5.1 Rendering Pipeline — No Third-Party Engine

The grid builds its own render tree. No PlutoGrid, SyncFusion, or other grid library is used
internally.

```
AppDataGrid (StatefulWidget)
└── _AppGridLayout
    ├── _AppGridColumnGroupHeader  (if columnGroups != null)
    ├── _AppGridHeaderRow
    │   └── _AppGridHeaderCell × N  (sort arrow, resize handle, context menu)
    ├── _AppGridBody               (virtualized; TwoDimensionalScrollView)
    │   └── _AppGridRow × N
    │       ├── _AppGridCheckboxCell  (if any column has type == AppColumnType.id)
    │       └── _AppGridCell × M      (calls column.buildCell or default text)
    ├── _AppGridFooterRow          (if any column has footerRenderer)
    └── _AppGridPaginationFooter   (lazyPaged variant only)
```

#### Virtualization

Use Flutter's `TwoDimensionalScrollView` + `TwoDimensionalChildBuilderDelegate` (stable since
Flutter 3.13). This virtualizes both horizontal and vertical axes so wide grids with many columns
never build off-screen cells. This is the primary performance advantage over traditional
`ListView`-based grids.

**Rule**: The grid must never build a cell widget for a column that is outside the viewport.
Both rows and columns must be lazily built based on scroll position.

#### Column Width Layout

A custom `RenderBox` computes column widths each layout pass:
1. If `controller.columnWidths[field]` is set (from resize), use it
2. If `column.width` is set, use it
3. Otherwise, distribute remaining space proportionally among flexible columns
4. Enforce `column.minWidth` as a floor at all times — resize cannot go below it

**Rule**: Column widths survive theme changes, parent rebuilds, and Riverpod provider updates
because they live in the controller's state, not in the render tree.

### 5.2 Controller Lifecycle Pattern

```dart
class _AppDataGridState<T> extends State<AppDataGrid<T>> {
  late AppDataGridController<T> _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AppDataGridController<T>();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(AppDataGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? AppDataGridController<T>();
      _controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }
}
```

**Rule**: The grid widget listens to the controller via `addListener`/`removeListener`. The
controller is a plain `ChangeNotifier`. There is no third-party notifier, no `AnimatedBuilder`
on external objects, and no `addListener` call that could throw because an object was disposed.

**Rule**: When the grid owns the controller (`widget.controller == null`), it creates AND disposes
it. When an external controller is provided, the grid only adds/removes its own listener —
disposal is the caller's responsibility.

### 5.3 Hover Coalescing

```dart
class _AppGridBodyState extends State<_AppGridBody> {
  PointerEvent? _pendingHoverEvent;
  bool _hoverScheduled = false;

  void _onPointerHover(PointerEvent event) {
    _pendingHoverEvent = event;
    if (!_hoverScheduled) {
      _hoverScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hoverScheduled = false;
        final event = _pendingHoverEvent;
        _pendingHoverEvent = null;
        if (event != null && mounted) {
          _updateHoveredRow(event);
        }
      });
    }
  }
}
```

**Rule**: Never call `controller.setHoveredRow` directly on raw pointer events. Always coalesce
to one call per frame. Fast mouse movement generates dozens of events per frame — without
coalescing this causes layout thrash and visible jank.

### 5.4 Column Resize

The resize handle is a thin (e.g. 6px) transparent `GestureDetector` at the right edge of each
header cell (left edge in RTL).

**Behavior**:
- `onHorizontalDragUpdate`: compute delta → `newWidth = max(column.minWidth, currentWidth + delta.dx)`
- Call `controller.setColumnWidth(field, newWidth)` on each update
- The controller notifies, the layout RenderBox re-reads `controller.state.columnWidths`, and
  the column reflows without destroying the widget tree

**Rule**: Resize state must survive hot reload, theme changes, and parent rebuilds. Never store
column width in a local `State` variable.

### 5.5 Page Cache (LazyPaged)

```dart
// Stored inside the grid state, not in the controller
Map<int, _CachedPage<T>> _pageCache = {};   // page number → cached rows + metadata
Queue<int> _evictionQueue = Queue();         // insertion order for FIFO eviction
static const int _maxCachedPages = 10;

class _CachedPage<T> {
  final List<String> rowKeys;   // stable keys of rows in this page
  final int totalRows;          // total rows as reported by the server for this fetch
}
```

**Cache hit flow**:
1. User navigates to page N
2. Check `_pageCache[N]` — if present, call `controller.replaceRows` with cached items immediately
3. No network call; `isLoading` stays false

**Cache miss flow**:
1. Set `controller.setLoading(true)`
2. Call `fetchTask(query.copyWith(page: N))`
3. On success: store in `_pageCache[N]`, call `controller.replaceRows`, `setLoading(false)`,
   `setMeta(result.meta)`
4. Evict oldest cache entry if `_pageCache.length > _maxCachedPages`:
   - Remove `_evictionQueue.removeFirst()` entry from `_pageCache`
   - Call `controller.removeRowsByKey(evicted.rowKeys)`
5. On error: call `controller.setError(e)`, `setLoading(false)`

**Cache invalidation** (sort change, filter change, param change, or `refresh()`):
1. Clear `_pageCache` and `_evictionQueue`
2. Call `controller.clearRows()`
3. Call `controller.clearSelection()`
4. Reset to page 1 if needed
5. Trigger a fresh fetch for page 1

**Deduplication**: Use `Map<int, Future<AppGridFetchResult<T>>> _inFlight` to track in-progress
fetches. Before starting a fetch for page N, check `_inFlight[N]` — if present, await the
existing future instead of starting a new one.

### 5.6 Sort and Filter Flow

**Sort** (when `fetchWithSorting: true`):
1. User clicks the sort arrow on a column header
2. Grid calls `controller.setSort(AppColumnSort(field, direction))`
3. Controller notifies
4. Grid observes query change → triggers cache invalidation → fetches page 1

**Filter** (when `fetchWithFiltering: true`):
1. User opens the filter popup for a column (via context menu or filter icon)
2. Popup shows operator dropdown + value field(s) relevant to the operator
3. On confirm: grid calls `controller.setFilters([AppColumnFilter(...)])`
4. All `AppFilterOperator` values must be selectable in the UI — hard-coding to `contains` is
   forbidden
5. Same cache invalidation → page 1 fetch flow

### 5.7 Pagination Footer

```dart
// Shown at the bottom of AppDataGrid.lazyPaged
// State lives inside the footer widget, coordinated via the controller
```

**Expected UI**:
- First page button, `...` if gap > 1, page window of ±2 around current, `...`, last page button
- Current page is highlighted
- Page size dropdown (options: 10, 13, 25, 50, 100 or custom)
- Total rows count: "Showing X–Y of Z"
- Previous / Next arrow buttons; disabled at boundaries

**Behavior**:
- On page change: call `controller.goToPage(N)` → grid observes query change → fetch
- On page size change: call `controller.setPageSize(N)` → always resets to page 1
- Pending page queue: if a fetch is in-flight when `goToPage` is called, queue the page and
  flush with `WidgetsBinding.addPostFrameCallback` after the fetch completes — never drop a
  user's navigation intent
- Unfocus keyboard on page change to prevent stale text field focus

### 5.8 Active Filter Bar

`AppGridFilterBar` is a horizontal scrolling row of filter pills. It is rendered automatically by
`AppDataGridConsumer` when `controller.currentMeta?.filters` is non-empty.

**Expected UI per pill**:
- Label (the filter name) + currently selected values listed
- Clicking a pill opens a dropdown of available values (checkboxes for multi-select, radio for
  single-select)
- Each selection immediately calls `controller.setParam(key, selectedValues.join(','))` or
  `controller.removeParam(key)` if cleared
- A global "Clear All" button appears when any filter is active

---

## 6. Built-in Cell Renderers

All renderers are static factory methods on `AppGridCellRenderers`. Each returns a value of type
`Widget Function(TRow row, TValue value, AppGridCellContext ctx)` — the typed signature used by
`AppDataGridColumn.cellRenderer`.

```dart
// Usage:
AppDataGridColumn<Order, double>(
  field: 'amount',
  title: 'Amount',
  valueGetter: (o) => o.amount,
  cellRenderer: AppGridCellRenderers.currency(
    positiveColor: Colors.green,
    negativeColor: Colors.red,
  ),
)
```

| Renderer | Signature | Behavior |
|---|---|---|
| `text({Color? color, TextStyle? style, TextAlign? align})` | `Function(TRow, String, ctx)` | Plain styled text; respects `textDirection` |
| `currency({Color? positiveColor, Color? negativeColor})` | `Function(TRow, num, ctx)` | Right-aligned monetary value; applies color based on sign |
| `date({String format = 'dd MMM yyyy'})` | `Function(TRow, DateTime, ctx)` | Formatted date |
| `dateTime({String format = 'dd MMM yyyy HH:mm'})` | `Function(TRow, DateTime, ctx)` | Formatted date + time — **separate from date renderer** |
| `boolean({void Function(bool)? onChanged})` | `Function(TRow, bool, ctx)` | Centered checkbox; tappable if `onChanged` is set |
| `statusChip({required Map<K, Color> colors, Map<K, String>? labels})` | `Function(TRow, K, ctx)` | Colored rounded pill; label from `labels[value]` or `value.toString()` |
| `actions({required List<AppGridAction<TRow>> actions})` | `Function(TRow, _, ctx)` | Row of icon buttons; each action can have `isVisible`/`isEnabled` predicates |
| `copyableText({Color? color, TextStyle? style})` | `Function(TRow, String, ctx)` | Selectable text; long-press or right-click copies to clipboard |
| `twoLine({required String Function(TRow) secondLine, TextStyle? secondLineStyle})` | `Function(TRow, String, ctx)` | Bold title + muted subtitle in one cell |
| `avatarTwoLine({required String Function(TRow) secondLine, required ImageProvider Function(TRow)? avatar})` | `Function(TRow, String, ctx)` | Leading avatar + bold title + muted subtitle |
| `link({required void Function(TRow) onTap, Color? color})` | `Function(TRow, String, ctx)` | Tappable primary-colored text |

```dart
class AppGridAction<TRow> {
  const AppGridAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isVisible,    // bool Function(TRow) — hide button for specific rows
    this.isEnabled,    // bool Function(TRow) — disable button for specific rows
  });

  final IconData icon;
  final String tooltip;
  final void Function(TRow row) onPressed;
  final bool Function(TRow row)? isVisible;
  final bool Function(TRow row)? isEnabled;
}
```

**Rule**: Renderers that accept colors should default to the current theme's semantic colors, not
hardcoded values. A renderer with `positiveColor: null` should fall back to `Theme.of(context)`.

---

## 7. Theming

All visual configuration flows through `AppGridThemeData`, provided via `AppGridTheme` (an
`InheritedWidget`) or falling back to default values derived from the surrounding `Theme`.

```dart
class AppGridThemeData {
  const AppGridThemeData({
    this.backgroundColor,
    this.headerBackgroundColor,
    this.rowEvenColor,
    this.rowOddColor,
    this.rowHoverColor,
    this.rowSelectedColor,
    this.borderColor,
    this.headerTextStyle,
    this.cellTextStyle,
    this.iconSize = 15,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.showVerticalCellBorders = false,
    this.showVerticalHeaderBorders = false,
    this.loadingIndicatorColor,
    this.checkboxActiveColor,
    this.paginationBackgroundColor,
  });
}
```

**Rule**: A theme change must **never** destroy the grid's widget tree, reset scroll position,
reset sort state, or reset column widths. Theme updates are applied in-place via `InheritedWidget`
propagation.

**Rule**: The `density` parameter drives row and header height only. All other sizing comes from
`AppGridThemeData`.

---

## 8. Required Behaviors Checklist

The following behaviors are required in any correct implementation. An AI agent implementing this
package should verify each one:

### Lifecycle Safety
- [ ] `addListener` is never called on an object after it has been disposed
- [ ] `dispose()` is never called twice on any object
- [ ] `super.dispose()` is called exactly once at the end of `dispose()` overrides
- [ ] After a widget rebuilds with a new controller reference, the listener is moved correctly
      (removed from old, added to new)

### Theme Resilience
- [ ] Changing the `density` does not destroy the grid widget tree
- [ ] Changing the `AppGridThemeData` does not reset scroll position, sort, or column widths
- [ ] Column widths persisted in the controller survive hot reload

### Concurrency Safety
- [ ] Only one in-flight fetch per page number at a time (deduplication)
- [ ] A `refresh()` call that arrives while a fetch is in-progress does not produce a double-fetch
- [ ] `setLoading(false)` is always called even when `fetchTask` throws

### Correctness
- [ ] `dateTime` columns display both date AND time — not just the date
- [ ] All `AppFilterOperator` values are selectable in the filter UI — none are hard-coded
- [ ] Sort changes reset the page to 1 before fetching
- [ ] `hideEmptyColumns` never hides a column that was explicitly set to `hide: true` by the caller
- [ ] Selection equality uses the domain object's `==`, not row index
- [ ] `exportToCsv()` sanitizes formula-injection characters
- [ ] Frozen columns respect `Directionality` — `AppColumnFrozen.start` freezes to the LEFT in
      LTR and to the RIGHT in RTL
- [ ] Resize cannot push a column below its `minWidth`
- [ ] Hover events are coalesced to one per frame

### Encapsulation
- [ ] No internal rendering type is exposed through the public API
- [ ] `app_data_grid.dart` barrel export is the only import callers need
- [ ] `AppColumnFooterContext` and `AppGridCellContext` use no internal types
- [ ] The controller's `dispose()` can be called safely from a `useEffect` cleanup without
      "used after dispose" errors on pending async operations

---

## 9. Open Decisions

These must be resolved before implementation begins:

1. **Underlying scroll mechanism** — `TwoDimensionalScrollView` (Flutter 3.13+) requires a minimum
   Flutter SDK version. Confirm the target minimum version. If < 3.13, fall back to a nested
   `ListView`/`SingleChildScrollView` approach (worse performance but wider compatibility).

2. **Inline cell editing** — include in v1 or defer? If included, the edit flow is: tap cell →
   shows inline `TextField` or picker → confirm/cancel → calls `controller.updateRow(...)`. If
   deferred, `enableEditing` on columns is accepted but ignored.

3. **Column reorder** — include in v1 or defer? If included, drag a column header to reorder.
   Order is stored in `AppDataGridState.columnOrder: List<String>` (list of fields in display order).

4. **Column width persistence** — should `AppDataGridController` accept an optional
   `ColumnWidthStore` callback (`void Function(Map<String, double>)`) so callers can persist
   widths to `SharedPreferences`? Or is this always left to the caller via `ListenableBuilder`?

5. **Multi-level column groups** — the spec allows nested `AppColumnGroup.children`. Is more
   than 2 levels of nesting required? Deeper nesting adds significant layout complexity.

6. **RTL freeze direction** — confirm: `AppColumnFrozen.start` should freeze to the right edge
   when `Directionality` is RTL. Verify with the design team.

7. **Minimum Flutter version** — targeting Flutter stable; specify the minimum version to set
   `TwoDimensionalScrollView` usage safely.
