# tabular — Architecture Decisions

> All open questions from the original spec are resolved here.
> This file is the source of truth. Update it whenever a decision changes,
> and reference it in PR descriptions.

---

## D-00 · Package name & public API prefix

**Decision:** The package is named **`tabular`**.

**Import:**
```dart
import 'package:tabular/tabular.dart';
```

**Naming convention:** All public types drop the `App` / `AppGrid` / `AppColumn` prefixes
and use the `Tabular` prefix instead.

| Original spec name | Final name |
|---|---|
| `AppDataGrid` | `Tabular` |
| `AppDataGridController` | `TabularController` |
| `AppDataGridColumn` | `TabularColumn` |
| `AppDataGridConsumer` | `TabularConsumer` |
| `AppDataGridQuery` | `TabularQuery` |
| `AppDataGridState` | `TabularState` |
| `AppDataRow` | `TabularRow` |
| `AppGridThemeData` | `TabularThemeData` |
| `AppGridTheme` | `TabularTheme` |
| `AppGridCellContext` | `TabularCellContext` |
| `AppColumnFooterContext` | `TabularFooterContext` |
| `AppGridCellRenderers` | `TabularRenderers` |
| `AppGridFetchResult` | `TabularFetchResult` |
| `AppGridResponseMeta` | `TabularResponseMeta` |
| `AppGridFetchTask` | `TabularFetchTask` |
| `AppActiveFilter` | `TabularActiveFilter` |
| `AppActiveFilterValue` | `TabularActiveFilterValue` |
| `AppColumnGroup` | `TabularColumnGroup` |
| `AppColumnSort` | `TabularColumnSort` |
| `AppColumnFilter` | `TabularColumnFilter` |
| `AppGridAction` | `TabularAction` |
| `AppGridSelectionAction` | `TabularSelectionAction` |
| `AppGridFilterBar` | `TabularFilterBar` |
| `AppGridDensity` | `TabularDensity` |
| `AppColumnFrozen` | `TabularColumnFrozen` |
| `AppSelectionMode` | `TabularSelectionMode` |
| `AppColumnType` | `TabularColumnType` |
| `AppSortDirection` | `TabularSortDirection` |
| `AppFilterOperator` | `TabularFilterOperator` |

**Barrel file:** `lib/tabular.dart` — the only file callers import.

---

## D-01 · Minimum Flutter SDK version

**Decision:** Flutter ≥ 3.13 (Dart ≥ 3.1)

**Rationale:** `TwoDimensionalScrollView` and `TwoDimensionalChildBuilderDelegate` became stable
in Flutter 3.13. Targeting this version gives true bi-axial virtualization — off-screen cells
on both axes are never built. The nested `ListView` / `SingleChildScrollView` fallback is dropped
entirely; it does not virtualize the horizontal axis and would be a performance liability for
wide grids.

**Impact on pubspec.yaml:**
```yaml
environment:
  sdk: ">=3.1.0 <4.0.0"
  flutter: ">=3.13.0"
```

---

## D-02 · Inline cell editing

**Decision:** Include in v1.

**Behavior:**
- Tap a cell whose column has `enableEditing: true` → cell switches to edit mode
- Edit mode renders an inline `TextField` (text/number columns) or appropriate picker
  (date, boolean, select columns)
- Confirm: tap outside the cell, press Enter, or tap a confirm icon → calls
  `controller.updateRow(index, updatedItem, rowBuilder: ...)`
- Cancel: press Escape → reverts to display value with no controller update
- `TabularCellContext.isEditing` is `true` while the cell is in edit mode — custom
  `cellRenderer` implementations should handle this flag if they want custom edit UI
- Only one cell can be in edit mode at a time; entering edit mode on a second cell
  auto-confirms the first

**API additions to `TabularController`:**
```dart
void beginEdit(int rowIndex, String field);
void confirmEdit(int rowIndex, String field, dynamic newValue);
void cancelEdit();
int? get editingRowIndex;
String? get editingField;
```

**Deferred to v2:** Rich pickers (color, image), validation with error display, bulk edit.

---

## D-03 · Column drag-to-reorder

**Decision:** Include in v1.

**Behavior:**
- Long-press (mobile) or click-and-drag (desktop/web) a column header to begin reorder
- A drag ghost (semi-transparent copy of the header) follows the pointer
- Drop between two columns to reorder; drop outside the grid cancels
- Frozen columns (`TabularColumnFrozen.start` / `.end`) cannot be reordered out of their
  frozen zone; non-frozen columns cannot be dragged into a frozen zone
- Reorder is stored in `TabularState.columnOrder: List<String>` — a list of `field` values
  in display order; replaces the default (declaration order)

**API additions to `TabularController`:**
```dart
List<String> get columnOrder;
void reorderColumn(String field, int newIndex);
void resetColumnOrder();
```

**Callback on `Tabular` widgets:**
```dart
void Function(List<String> newOrder)? onColumnReorder,
```

---

## D-04 · Column width persistence

**Decision:** Left entirely to the caller. No persistence interface in this package.

**Rationale:** Adding a persistence layer would pull in a `SharedPreferences` (or similar)
dependency, conflicting with the zero-unnecessary-dependency goal. `TabularController` already
exposes `state.columnWidths` as a plain `Map<String, double>`. Callers persist and restore it
however they prefer — the grid itself only holds widths for the lifetime of the controller.

**Resize behavior:**
- Drag the handle on the column header edge → `controller.setColumnWidth(field, newWidth)`
  is called live on each drag update
- Width stored in `TabularState.columnWidths` for the session
- `controller.resetColumnWidths()` clears back to defaults
- When the controller is disposed, widths are gone — no persistence, by design

**Caller example (optional persistence):**
```dart
// Save
ListenableBuilder(
  listenable: controller,
  builder: (_, __) {
    prefs.setString('col_widths', jsonEncode(controller.state.columnWidths));
    return const SizedBox.shrink();
  },
);

// Restore on init
controller.state = controller.state.copyWith(
  columnWidths: Map<String, double>.from(
    jsonDecode(prefs.getString('col_widths') ?? '{}'),
  ),
);
```

---

## D-05 · TabularColumnGroup nesting depth

**Decision:** Maximum 2 levels (one parent group containing leaf groups or columns).

**Rationale:** A third nesting level adds disproportionate layout complexity for a rare
real-world need. Enforced via assertion in debug mode; silently flattened in release mode.

**Valid structure (2 levels):**
```
Group A
  ├─ Column 1
  └─ Column 2
Group B
  ├─ Sub-group B1
  │   ├─ Column 3
  │   └─ Column 4
  └─ Sub-group B2
      └─ Column 5
```

**Invalid (3 levels) — assertion thrown in debug:**
```
Group A
  └─ Sub-group B
      └─ Sub-sub-group C   ← depth 3, not allowed
          └─ Column 1
```

---

## D-06 · Frozen column direction

**Decision:** `TabularColumnFrozen.start` always freezes to the **leading edge** of the
current `Directionality`. `TabularColumnFrozen.end` freezes to the trailing edge.

| `Directionality` | `TabularColumnFrozen.start` | `TabularColumnFrozen.end` |
|---|---|---|
| LTR (English, etc.) | Left edge | Right edge |
| RTL (Arabic, Hebrew, etc.) | Right edge | Left edge |

**Implementation note:** The layout `RenderBox` reads `Directionality.of(context)` at layout
time — never hardcodes left/right. The resize handle position, freeze divider/shadow, and
scroll offset calculations all branch on `textDirection`.

---

## Summary table

| # | Question | Decision |
|---|---|---|
| D-00 | Package name | `tabular`; all public types prefixed `Tabular` |
| D-01 | Min Flutter version | ≥ 3.13; use `TwoDimensionalScrollView` |
| D-02 | Inline cell editing | v1 |
| D-03 | Column drag-to-reorder | v1 |
| D-04 | Column width persistence | Caller's responsibility; no package interface |
| D-05 | `TabularColumnGroup` nesting depth | Max 2 levels |
| D-06 | Frozen column direction | Locale-relative (`start` = leading edge) |
