# tablex

A production-grade Flutter data grid with no dependency on any third-party grid engine.

---

## Features

- **Four grid modes** — static, lazy-paged, infinite-scroll, and select-picker
- **Built-in cell renderers** — identifier, two-line, avatar+two-line, currency, date, status chip, action buttons
- **Column management** — resizable columns, sortable headers, show/hide column manager
- **Row selection** — single or multi-select with a customisable summary bar and bulk-action buttons
- **Density presets** — `compact`, `standard`, `comfortable`
- **Theming** — full theme override via `TablexThemeData`
- **i18n** — locale strings via `slang` (override to ship your own language)
- Zero third-party grid engine dependency

---

## Getting started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  tablex: ^0.1.0
```

---

## Usage

### Static grid

All rows are provided upfront. Supports sorting and column resize.

```dart
Tablex<Employee>.static(
  columns: [
    TablexColumn<Employee, String>(
      fieldKey: 'name',
      title: 'Name',
      width: 180,
      valueGetter: (e) => e.name,
    ),
    TablexColumn<Employee, double>(
      fieldKey: 'salary',
      title: 'Salary',
      width: 130,
      textAlign: TextAlign.end,
      valueGetter: (e) => e.salary,
      cellRenderer: TablexRenderers.currency(symbol: '\$'),
    ),
  ],
  rows: employees,
  rowBuilder: (e) => TablexRow(
    data: e,
    key: e.id.toString(),
    cells: {'name': e.name, 'salary': e.salary},
  ),
)
```

### Lazy-paged grid

Rows are fetched from a server one page at a time.

```dart
Tablex<Employee>.lazyPaged(
  columns: columns,
  fetchTask: (query) async {
    final result = await api.fetchPage(
      page: query.page,
      pageSize: query.pageSize,
      sortField: query.sort?.field,
      sortAsc: query.sort?.direction == TablexSortDirection.ascending,
    );
    return TablexFetchResult(rows: result.items, totalRows: result.total);
  },
  rowBuilder: rowBuilder,
  initialPageSize: 20,
)
```

### Infinite scroll

New rows are fetched automatically as the user scrolls to the bottom.

```dart
Tablex<Employee>.infinite(
  columns: columns,
  fetchTask: myFetchTask,
  rowBuilder: rowBuilder,
  fetchSize: 50,
)
```

### Select picker

Turns the grid into a multi-select or single-select picker.

```dart
Tablex<Country>.select(
  columns: countryColumns,
  rows: countries,
  rowBuilder: countryRowBuilder,
  multiSelect: true,
  onSelectionChanged: (selected) => setState(() => _selected = selected),
)
```

---

## Built-in renderers

| Renderer | Usage |
|---|---|
| `TablexRenderers.identifier()` | Monospaced ID cell |
| `TablexRenderers.twoLine(secondLine: ...)` | Primary + secondary text |
| `TablexRenderers.avatarTwoLine(...)` | Avatar + two lines |
| `TablexRenderers.currency(symbol: '\$')` | Formatted number with currency symbol |
| `TablexRenderers.date()` | Formatted `DateTime` |
| `TablexRenderers.statusChip(colors: ..., labels: ...)` | Coloured chip |
| `TablexRenderers.actions(actions: ...)` | Icon button row |

---

## Theming

```dart
Tablex<Employee>.static(
  theme: TablexThemeData(
    showVerticalCellBorders: false,
    borderRadius: BorderRadius.circular(8),
    checkboxTheme: TablexCheckboxTheme(
      activeColor: Colors.blue,
      checkColor: Colors.white,
    ),
  ),
  // ...
)
```

---

## Additional information

- [Source & issues](https://github.com/weaamokok/tablex)
- PRs and bug reports are welcome.
