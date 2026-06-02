# PlutoGrid → Tablex Migration Guide

## Concept map at a glance

| PlutoGrid | Tablex | Notes |
|---|---|---|
| `PlutoGrid` | `Tablex.static` / `Tablex.lazyPaged` / `TablexConsumer` | Pick mode by data source |
| `PlutoColumn` | `TablexColumn<T, V>` | Typed on your model |
| `PlutoRow` / `PlutoCell` | `TablexRow<T>` | One object, not row+cells |
| `PlutoGridStateManager` | `TablexController<T>` | |
| `PlutoLazyPagination` | `Tablex.lazyPaged` | |
| `PlutoInfinityScrollRows` | `Tablex.infinite` | Sliding-window built in |
| `PlutoGridMode.select` | `Tablex.select` | |
| `PlutoGridMode.multiSelect` | `Tablex.select(multiSelect: true)` | |
| `PlutoGridConfiguration` | `TablexThemeData` + `TablexTheme` | |
| Frozen / pinned columns | ✗ not supported | |
| Inline cell editing | ✗ not supported | Tablex is read-only |
| `PlutoColumnType.number` | `TablexRenderers.currency()` | Display only |
| `PlutoColumnType.date` | `TablexRenderers.date()` | Display only |
| `PlutoColumnType.select` | `TablexRenderers.statusChip()` | Display only |
| `onChanged` (cell edit) | ✗ no equivalent | |
| `onSelected` | `onSelectionChanged` | |
| `onRowChecked` | `onSelectionChanged` | |
| `onSorted` | sort field arrives in `fetchTask` query | |
| Export toolbar | `TablexToolbar` | Built in |
| Column visibility | `TablexToolbar` / `TablexColumnManagerButton` | Built in |

---

## 1. What your wrapper needs to change

### Column definitions

**PlutoGrid**
```dart
PlutoColumn(
  title: 'Name',
  field: 'name',
  type: PlutoColumnType.text(),
  width: 180,
  enableSorting: true,
)
```

**Tablex**
```dart
TablexColumn<Employee, String>(
  fieldKey: 'name',   // matches the key in TablexRow.cells
  title: 'Name',
  width: 180,
  enableSorting: true,
  valueGetter: (e) => e.name,
)
```

The key difference: `valueGetter` replaces `PlutoColumnType`. It tells Tablex how to extract the display value from your model object. The generic type `V` (here `String`) is the value type — Tablex uses it for client-side sorting in `Tablex.static`.

---

### Row / data model

**PlutoGrid**
```dart
PlutoRow(cells: {
  'name': PlutoCell(value: employee.name),
  'salary': PlutoCell(value: employee.salary),
})
```

**Tablex**
```dart
TablexRow<Employee>(
  key: employee.id.toString(),   // unique, used for selection identity
  data: employee,                // the full model object
  cells: {
    'name': employee.name,
    'salary': employee.salary,
  },
)
```

`cells` values are plain Dart objects — no `PlutoCell` wrapper. Your `rowBuilder` function is called once per row and should return this object:

```dart
TablexRow<Employee> rowBuilder(Employee e) => TablexRow(
  key: e.id.toString(),
  data: e,
  cells: {'name': e.name, 'salary': e.salary},
);
```

---

### State manager → controller

**PlutoGrid** — `PlutoGridStateManager` is handed to you via a callback:
```dart
PlutoGrid(
  onLoaded: (e) => _stateManager = e.stateManager,
)
```

**Tablex** — create it yourself and pass it in:
```dart
final _controller = TablexController<Employee>();

Tablex.lazyPaged(controller: _controller, ...)

// Don't forget:
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

Common controller operations:

| PlutoGrid stateManager | TablexController |
|---|---|
| `stateManager.refetchData()` | `controller.refresh()` |
| `stateManager.setPage(n)` | `controller.goToPage(n)` |
| `stateManager.sortAscending(col)` | `controller.setSort(TablexColumnSort(...))` |
| `stateManager.clearSorting()` | `controller.clearSort()` |
| `stateManager.setFilter(...)` | `controller.setParam('key', value)` |
| `stateManager.selectingRows` | `controller.selectedRows` |
| `stateManager.checkedRows` | `controller.selectedRows` |
| `stateManager.selectAll()` | `controller.selectAll(controller.getAllRowData())` |
| `stateManager.clearSelection()` | `controller.clearSelection()` |
| `stateManager.updateRow(...)` | `controller.updateRow(index, data, rowBuilder: ...)` |
| `stateManager.removeRow(row)` | `controller.removeRow(index)` |

---

### Pagination / data loading

**PlutoGrid lazy pagination**
```dart
PlutoGrid(
  createFooter: (sm) => PlutoLazyPagination(
    fetch: (req) async {
      final res = await api.fetch(page: req.page, size: req.pageSize);
      return PlutoLazyPaginationResponse(totalPage: res.totalPages, rows: rows);
    },
    stateManager: sm,
  ),
)
```

**Tablex**
```dart
Tablex<Employee>.lazyPaged(
  columns: columns,
  rowBuilder: rowBuilder,
  fetchTask: (query) async {
    final res = await api.fetch(
      page: query.page,
      pageSize: query.pageSize,
      sort: query.sort?.field,
      sortAsc: query.sort?.direction == TablexSortDirection.ascending,
      // any extra params set via controller.setParam() arrive in query.params
    );
    return TablexFetchResult(rows: res.items, totalRows: res.total);
  },
  initialPageSize: 20,
)
```

Or use `TablexConsumer` if you want the border/title/filter-chip wrapper included:
```dart
TablexConsumer<Employee>(
  columns: columns,
  fetchTask: ...,
  initialPageSize: 20,
  tableHeader: Text('Employees'),
)
```

**PlutoGrid infinite scroll**
```dart
PlutoGrid(
  createFooter: (sm) => PlutoInfinityScrollRows(
    fetch: (req) async { ... },
    stateManager: sm,
  ),
)
```

**Tablex**
```dart
Tablex<Employee>.infinite(
  columns: columns,
  rowBuilder: rowBuilder,
  fetchTask: (query) async { ... },
  fetchSize: 50,
  windowPages: 5,   // keeps only 5 pages in memory; evicts older ones
)
```

---

### Sorting

PlutoGrid fires `onSorted`; you re-fetch manually. In Tablex the sort state is part of `TablexQuery` that arrives in your `fetchTask`. No separate callback needed — just read `query.sort`:

```dart
fetchTask: (query) async {
  return api.fetch(
    sort: query.sort?.field,
    ascending: query.sort?.direction == TablexSortDirection.ascending,
  );
},
```

For `Tablex.static`, sorting is handled client-side by Tablex automatically using `valueGetter` — no code needed.

---

### Selection

**PlutoGrid**
```dart
PlutoGrid(
  mode: PlutoGridMode.multiSelect,
  onSelected: (e) => print(e.row?.cells['id']?.value),
  onRowChecked: (e) => print(e.isChecked),
)
```

**Tablex**
```dart
Tablex<Employee>.static(
  selectionMode: TablexSelectionMode.multiple,
  showSelectionSummary: true,
  onSelectionChanged: (selected) {
    // selected is List<Employee> — your model objects directly
  },
  selectionActions: [
    TablexSelectionAction<Employee>(
      label: 'Delete',
      icon: Icons.delete_outline,
      onPressed: (selected) => _bulkDelete(selected),
    ),
  ],
)
```

---

### Theming

**PlutoGrid**
```dart
PlutoGrid(
  configuration: PlutoGridConfiguration(
    style: PlutoGridStyleConfig(
      gridBorderColor: Colors.grey,
      rowColor: Colors.white,
      checkedColor: Colors.blue.withOpacity(0.1),
    ),
  ),
)
```

**Tablex**
```dart
Tablex<Employee>.static(
  theme: TablexThemeData(
    showVerticalCellBorders: false,
    borderRadius: BorderRadius.circular(12),
    checkboxTheme: TablexCheckboxTheme(activeColor: Colors.blue),
  ),
)

// Or wrap a subtree to apply to all grids:
TablexTheme(
  data: TablexThemeData(...),
  child: MyScreen(),
)
```

All colors fall back to the ambient Material 3 `ColorScheme` when not set, so you often need very little here.

---

### Export / column manager

PlutoGrid doesn't ship export or column-visibility management. If your wrapper added these, replace them with `TablexToolbar`:

```dart
TablexConsumer<Employee>(
  tableHeader: TablexToolbar<Employee>(
    controller: _controller,
    columns: _columns,
    importRowFactory: (map) => TablexRow(
      data: Employee.fromMap(map),
      key: map['id']!,
      cells: {'name': map['name']!, 'salary': map['salary']!},
    ),
  ),
  ...
)
```

This gives you CSV export, Excel export, CSV import, Excel import, and column-visibility management out of the box.

---

## 2. Features PlutoGrid has that Tablex does NOT

These require a decision from your team before migration:

| Feature | Impact | Workaround |
|---|---|---|
| **Inline cell editing** | High if your app edits data in-grid | Open a side sheet / dialog on row tap using `onRowTap` |
| **Frozen / pinned columns** | Medium | Layout-level solution (e.g. a separate sticky left panel) |
| **Per-cell context menu** | Low | Use `TablexRenderers.actions()` for row-level actions |
| `PlutoColumnType.time` | Low | Format as string in `valueGetter` |
| Keyboard navigation between cells | Low | n/a |

---

## 3. What the wrapper class needs to do

Since you already have a wrapper, you can do a **facade swap** — keep the same public API your wrapper exposes and swap the internals.

1. **Replace column mapping** — convert your wrapper's column model to `TablexColumn<T, V>`. Add a `valueGetter` for each column.

2. **Replace row mapping** — convert your data objects to `TablexRow<T>` in a single `rowBuilder` function.

3. **Replace state manager** — expose `TablexController<T>` from your wrapper instead of `PlutoGridStateManager`. Map any public methods your callers use (refresh, filter, sort, select) to their Tablex equivalents from the table in §1.

4. **Replace fetch callback signature** — your wrapper's `onFetch(page, pageSize, sort)` becomes Tablex's `fetchTask(TablexQuery)`. Pull `query.page`, `query.pageSize`, `query.sort`, `query.params` from `query`.

5. **Replace theme passthrough** — swap `PlutoGridConfiguration` for `TablexThemeData`.

6. **Remove editing callbacks** (`onChanged`, `onRowSecondaryTap` for editing) — if your callers use these you need a replacement UX (row tap → dialog).

7. **Wire selection** — `onRowChecked` / `onSelected` → `onSelectionChanged(List<T>)`.

8. **Delete the PlutoGrid dependency** from `pubspec.yaml` and add:
   ```yaml
   dependencies:
     tablex: ^0.2.1
   ```
