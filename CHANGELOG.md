## 0.5.7

### Breaking changes

* **`exportFormatter` signature changed from `dynamic` to `TRow`** — the type of `TablexColumnBase.exportFormatter` has changed from `String Function(dynamic rawValue)?` to `String Function(TRow row)?`. This gives full access to the typed row object rather than just the raw cell value, enabling export strings derived from multiple fields or computed values. Update any existing `exportFormatter` callbacks to accept the row type instead of `dynamic`.

---

## 0.5.6

### New features

* **Per-column `hideIfEmpty` flag** — set `hideIfEmpty: true` on any `TablexColumn` to automatically hide that column when every loaded row has a null or empty value for it. The column reappears as soon as any row provides a non-empty value. Complements the existing grid-level `hideEmptyColumns` flag, which applies the same behaviour to all columns at once.

* **`exportFormatter` on `TablexColumnBase`** — an optional `String Function(TRow row)` that overrides the default export string for CSV, Excel, and PDF. Receives the full typed row object so you can derive the export value from any combination of fields. Resolution order: `exportFormatter` → column `formatter` → `Enum.name` (automatic, no config needed) → `toString()`.

### Bug fixes

* **Column flicker with `hideEmptyColumns` / `hideIfEmpty` while paging** — columns no longer disappear and reappear as the user pages through data. Visibility is now computed from an accumulated `_seenNonEmptyFields` set that only ever grows within a session, so a column stays visible once it has been shown.

* **Header / body column misalignment with `hideIfEmpty`** — `TablexBody` was reading `state.hiddenColumnFields` internally, bypassing the widget-level `hiddenFields` set (which includes the empty-column logic). The computed `hiddenFields` is now passed into `TablexBody` directly, keeping the header and body in sync.

* **Action columns included in exports** — columns with `type: TablexColumnType.action` are now excluded from CSV, Excel, and PDF exports.

* **Enum values exported with class prefix** — enum cell values (e.g. `EmployeeStatus.active`) are now exported as their short `.name` (`'active'`) automatically, with no column configuration required.

* **Cell renderers now accept nullable values** — all built-in renderers (`text`, `currency`, `dateTime`, `boolean`, `statusChip`, `twoLine`, `avatarTwoLine`, `link`, `identifier`, `copyableText`) have been updated to accept `TValue?`. Renderers return `SizedBox.shrink()` for `null` values; the `boolean` renderer uses a tristate `Checkbox` for `null`.

### Refactoring

* **Split `tablex_widget.dart` into part files** — the 955-line file is now broken into three focused `part of` files:
  * `_tablex_state.dart` — `_TablexState<T>` + `_InfiniteLoadingBar`
  * `_selection_summary_header.dart` — `_SelectionSummaryHeader<T>` + `_SelectionSummaryHeaderState<T>`
  * `_tablex_state_mixin.dart` — unchanged, already extracted
  * `tablex_widget.dart` retains only the `_TablexVariant` enum and the `Tablex` widget declaration (~383 lines).

* **Split `controller.dart` into part files** — the 692-line controller is now broken into five focused `part of` files:
  * `_controller_rows.dart` — row CRUD (`replaceRows`, `appendRows`, `prependRows`, `removeRow*`, `clearRows`, `getRow*`, `rows`, `rowCount`)
  * `_controller_query.dart` — query/pagination/sort/filter and loading/meta/error state
  * `_controller_selection.dart` — selection (`selectRow`, `deselectRow`, `toggleRowSelection`, `selectAll`, `clearSelection`, `selectedRows`, `isSelected`)
  * `_controller_columns.dart` — column visibility, width, order, frozen pinning, and inline editing
  * `_controller_export.dart` — CSV/Excel/PDF import/export (unchanged)
  * `controller.dart` retains only the class skeleton — fields, constructor, `_checkDisposed`, `_notify`, and `dispose` (~129 lines).

---

## 0.5.5

### Documentation

* Bumped version to `0.5.5`.

---

## 0.5.4

### Documentation

* Bumped version to `0.5.4`.

---

## 0.5.3

### Documentation

* Bumped version to `0.5.3`.

---

## 0.5.2

### New features

* **Select-all / deselect-all checkbox in the selection summary bar** — in `multiple` selection mode a tristate `Checkbox` is shown at the leading edge of the bar. The checkbox is checked when every loaded row is selected, indeterminate when some are selected, and tapping it toggles between select-all and clear-selection. It follows the grid's `TablexCheckboxTheme` (active colour, check colour, border, shape, and size) for visual consistency with the row and header checkboxes.
  * `_SelectionSummaryHeader` (inside `Tablex`) reads the checkbox theme from the resolved `TablexThemeData`.
  * `TablexSelectionSummaryBar` (standalone widget) gains two new optional params — `totalCount` and `onSelectAll` — to opt into the same behaviour from outside the grid.
  * `TablexConsumer` automatically wires `totalCount` and `onSelectAll` when `selectionMode` is `multiple`.

### API additions

| Symbol | Kind | Notes |
|---|---|---|
| `TablexSelectionSummaryBar.totalCount` | param | Total row count; determines the tristate checkbox value |
| `TablexSelectionSummaryBar.onSelectAll` | param | Callback to select all rows; presence enables the checkbox |

---

## 0.5.1

### Documentation

* Updated `README.md` to cover PDF export, export-selected-rows, selectable cell text, theme-level empty-cell placeholder, and selection summary bar colour.
* Bumped the `Getting started` version constraint to `^0.5.1`.

---

## 0.5.0

### New features

* **PDF export** — `TablexController.exportToPdf(columns)` and `exportSelectedToPdf(columns)` generate a styled `.pdf` byte array. The page switches automatically to landscape when more than six visible columns are present; `number` and `currency` columns are right-aligned; rows alternate between white and light-grey. Requires the new `pdf: ^3.10.7` dependency.

* **Export selected rows** — new controller methods `exportSelectedToCsv`, `exportSelectedToExcel`, and `exportSelectedToPdf` serialise only the currently selected rows. The toolbar export buttons (CSV, Excel, PDF) automatically switch to selected-only mode when rows are selected — tooltip updates to show the count (e.g. `'Export CSV (3 selected)'`). The selection summary bar now shows CSV, Excel, and PDF icon buttons for the same purpose.

* **Selectable cell text on web** — cell text is rendered with `SelectableText` on web by default, allowing users to click-drag to copy values without leaving the grid. Controlled by `TablexThemeData.enableTextSelection` (defaults to `kIsWeb`; opt in on desktop by setting it to `true`). Applies to all built-in text renderers: `text`, `date`, `dateTime`, `twoLine`, `avatarTwoLine`, `currency`, and the default type-based cell. Row tap and double-tap interactions are unaffected.

* **Theme-level empty-cell placeholder** — `TablexThemeData.emptyCellPlaceholder` sets a grid-wide string shown for `null` cell values (e.g. `'N/A'`), without having to configure `TablexColumnBase.emptyCellPlaceholder` on every column. Precedence: column-level → theme-level → `'—'` (when `showEmptyAsDash`) → blank.

* **Themeable selection summary bar colour** — `TablexThemeData.selectionSummaryBarColor` controls the background of the selection summary bar. Defaults to `ColorScheme.surfaceContainerHighest`. Both `TablexSelectionSummaryBar` (standalone) and the built-in `_SelectionSummaryHeader` inside `Tablex` respect this value.

### API additions

| Symbol | Kind | Notes |
|---|---|---|
| `TablexController.exportToPdf()` | method | All rows → PDF bytes (async) |
| `TablexController.exportSelectedToPdf()` | method | Selected rows → PDF bytes (async) |
| `TablexController.exportSelectedToCsv()` | method | Selected rows → CSV string |
| `TablexController.exportSelectedToExcel()` | method | Selected rows → `.xlsx` bytes |
| `Tablex.*.onExportSelectedCsv` | param | Override CSV export in the summary bar |
| `Tablex.*.onExportSelectedExcel` | param | Override Excel export in the summary bar |
| `Tablex.*.onExportSelectedPdf` | param | Override PDF export in the summary bar |
| `TablexConsumer.onExportSelectedCsv` | param | Same, for `TablexConsumer` |
| `TablexConsumer.onExportSelectedExcel` | param | Same, for `TablexConsumer` |
| `TablexConsumer.onExportSelectedPdf` | param | Same, for `TablexConsumer` |
| `TablexToolbar.onExportPdf` | param | Override PDF toolbar action |
| `TablexToolbar.exportPdfIcon` | param | Custom icon for the PDF button |
| `TablexSelectionSummaryBar.onExportSelectedPdf` | param | PDF button in standalone summary bar |
| `TablexThemeData.enableTextSelection` | field | Toggle `SelectableText` in cells |
| `TablexThemeData.emptyCellPlaceholder` | field | Grid-wide null-cell placeholder |
| `TablexThemeData.selectionSummaryBarColor` | field | Summary bar background colour |
| `TablexCellContext.enableTextSelection` | field | Readable by custom renderers |

### Dependencies

* Added `pdf: ^3.10.7`.

---

## 0.4.0

### New features

* **Inline cell editing** — set `enableEditing: true` on any `TablexColumn` to make its cells editable. Double-tap a cell to enter edit mode; the grid renders a type-aware input widget by default:
  * `text` / default → auto-focused `TextField` with full text pre-selected.
  * `number` / `currency` → numeric keyboard, right-aligned text.
  * `boolean` → single-tap toggles the value immediately (no text input).
  * Custom → supply `editRenderer` on the column to replace the input with any widget (e.g. a dropdown, date picker, or colour swatch).
  * Commit with **Enter** or click-outside; cancel with **Escape**.

* **`TablexColumn.onEdit` callback** — fired after the user commits an edit. Receives the original row object and the new typed value. The grid has already updated the cell display optimistically; use this callback to persist to your API or local state.

* **`TablexColumn.editRenderer`** — fully custom edit widget per column. Receives `(BuildContext, TRow, TValue currentValue, onSubmit, onCancel)`. The grid wraps it in a `Focus` node so **Escape** always cancels regardless of the widget used.

* **`TablexController.updateCell(rowIndex, field, newValue)`** — updates a single cell value in place without requiring a full `rowBuilder`. Available for programmatic optimistic updates outside of inline editing.

* **`TablexThemeData.editInputDecoration`** — overrides the `InputDecoration` of the default text-field editor globally for a grid, without writing a per-column `editRenderer`.

* **Keyboard navigation in edit mode** — while a cell is in edit mode, navigation keys move focus to the next cell without leaving the keyboard:
  * **Tab** — commit and move to the next editable column; wraps to the first editable column of the next row.
  * **Shift+Tab** — commit and move to the previous editable column; wraps to the last editable column of the previous row.
  * **↓ Arrow Down** — commit and move to the same column in the next row.
  * **↑ Arrow Up** — commit and move to the same column in the previous row.
  * Arrow navigation scrolls the list automatically to keep the target cell visible.
  * `TablexEditDirection` enum is exported for custom `editRenderer` widgets that want to implement the same shortcuts.

### API additions

| Symbol | Kind | Notes |
|---|---|---|
| `TablexColumn.onEdit` | callback | Typed `(TRow, TValue)` edit callback |
| `TablexColumn.editRenderer` | builder | Fully custom edit widget |
| `TablexColumnBase.handleEdit()` | method | Override to dispatch typed `onEdit` |
| `TablexColumnBase.buildEditCell()` | method | Override to supply custom edit UI |
| `TablexController.updateCell()` | method | Single-cell in-place update |
| `TablexThemeData.editInputDecoration` | field | Overrides default edit-field decoration |
| `TablexEditDirection` | enum | Tab / Shift+Tab / ↓ / ↑ navigation directions |

### Example app

* The **I/O tab** is now fully wired for inline editing: `Name` (text field), `Salary` (numeric field), `Department` (dropdown via `editRenderer`), and `Manager` (boolean toggle). Edits propagate back through `updateRow` so CSV/Excel exports reflect the latest values.

---

## 0.3.3

### Documentation

* Added iOS, macOS, and Web screenshots to `README.md` and registered them in `pubspec.yaml` under `screenshots:` so they appear in the pub.dev package carousel.

### Example app

* Removed explicit `id("kotlin-android")` from `example/android/app/build.gradle.kts` — the Flutter Gradle Plugin now applies Kotlin internally, eliminating the KGP deprecation warning introduced in recent Flutter versions.

---

## 0.3.2

### New features

* **Cursor-based pagination** — `Tablex.lazyPaged` now supports opaque-cursor APIs alongside the existing offset-based mode. Return `nextCursor` (and optionally `prevCursor`) from your `TablexFetchTask` and the footer switches modes automatically — no constructor flag required. Back-navigation is handled via an internal cursor history so APIs that only return `nextCursor` still support going back. `TablexQuery` gains a `cursor` field; `TablexFetchResult` gains `nextCursor` and `prevCursor`. `TablexPaginationInfo` gains `isCursorMode` and `hasNextPage` for custom `footerBuilder` implementations.

* **Redesigned pagination footer** — the default footer UI has been replaced with a pill-based design: a 2 px loading strip at the top, windowed page pills (`[1] ··· [4][5][6] ··· [20]`), and labelled `← Previous` / `Next →` buttons. In cursor mode the pills are replaced by a `Page N` (or `Page N of M`) indicator. The `enablePageJump` editable-input mode is preserved.

* **Default cell renderers per column type** — columns without a `cellRenderer` now render according to their `type`: `boolean` → read-only checkbox, `date`/`dateTime` → formatted date string, `currency` → sign-aware coloured amount, `number` → end-aligned text, `id`/`identifier` → tap-to-copy monospace (unchanged). Plain text is still the fallback for `text`, `select`, and `action`.

### Bug fixes

* **`file_picker` constraint updated** — bumped to `^11.0.2`.

### Internal

* Refactored `tablex_widget.dart`: public API types (`TablexLoadingBuilder`, `TablexErrorBuilder`, `TablexSelectionSummaryBuilder`, `TablexSelectionAction`) moved to `tablex_types.dart`; scroll sync, infinite-scroll, and sort logic extracted to `_tablex_state_mixin.dart` via `part of`.
* Refactored `controller.dart`: CSV and Excel export/import logic moved to `_controller_export.dart` via `part of`, keeping the reactive `ChangeNotifier` core separate from serialization.

---

## 0.3.0

### New features

* **Frozen / pinned columns** — set `frozen: TablexColumnFrozen.start` or `frozen: TablexColumnFrozen.end` on any `TablexColumn` to pin it to the left or right edge of the grid. Frozen columns remain visible while the user scrolls horizontally.
  * RTL-aware: `start` pins to the right and `end` to the left in RTL locales. Shadow direction is computed from `Directionality.of(context)`.
  * Vertical scroll is kept in sync with the main body via dedicated `ScrollController`s. Pointer scroll events and touch drag on frozen panels are forwarded to the main controller so the user can scroll from anywhere.
  * Sort and column resize work on frozen columns identical to scrollable columns. Drag-to-reorder is intentionally disabled for frozen columns.
  * Column visibility (`hide: true`) collapses a frozen panel entirely if all its columns are hidden.
  * Selection summary bar spans the full width of all three panels.

---

## 0.2.1

### Bug fixes

* **WASM compatibility** — file import (`FilePicker.pickFiles`) is now behind a conditional export so `dart:io` is never imported on web or WASM. `dart.library.js_interop` routes to an HTML `<input type="file">` + `FileReader` implementation instead.
* **Formatting** — all library files now pass `dart format`.
* **Dependency lower-bound fix** — tightened `excel` constraint to `^4.0.6` (the version that introduced `TextCellValue.value` as `TextSpan`); the previous `^4.0.0` caused a type error under `dart pub downgrade`.
* **Updated `file_picker` to `^11.0.0`** — aligns with the current stable release and migrates call sites from the removed `FilePicker.platform.*` instance methods to the new `FilePicker.*` static API.

---

## 0.2.0

### New features

* **`TablexConsumer`** — high-level widget that wraps `Tablex.lazyPaged` with a bordered container, optional title/filter header slots, automatic filter-chip bar, and controller lifecycle management.
* **Sliding-window infinite scroll** — `Tablex.infinite` now accepts a `windowPages` parameter. Old pages are evicted as new ones arrive; scroll-position compensation via `jumpTo` keeps the viewport stable.
* **Skeleton loading** — `TablexLoadingBuilder` pre-populates the grid with placeholder rows so a shimmer library (e.g. Skeletonizer) has real content to animate over, on both `lazyPaged` and `infinite` grids.
* **Custom pagination footer** — `footerBuilder` on `Tablex.lazyPaged` and `TablexConsumer` fully replaces the default footer. `enablePageJump` makes the page indicator an editable text field.
* **`TablexToolbar`** — drop-in toolbar with column-visibility management, CSV export (formula-injection protected), Excel export, CSV import, and Excel import. Each action can be overridden individually.
* **`prependRows` / `removeFirstRows` / `removeLastRows`** on `TablexController` — used internally by the sliding-window but available for manual row management.
* **Sort race-condition guard** — a generation counter on `Tablex.infinite` ensures that in-flight fetch results are discarded when a sort or reset fires before they resolve.

### Bug fixes

* Fixed infinite-scroll first-page load using `appendRows` instead of `replaceRows` after a sort reset, causing skeleton rows to persist above the sorted results.
* Fixed header row being included in the skeleton loading scope, causing column headers to shimmer on re-fetch.

### Tests

* Added 13 unit tests for the sliding-window controller methods (`prependRows`, `removeFirstRows`, `removeLastRows`).
* Added 26 widget + unit tests covering `TablexQuery.copyWith`, static sort (ascending, descending, clear, icons), lazy-paged fetch (initial query, sort re-fetch, error state, custom error widget), and infinite-scroll (skeleton replace, sort re-fetch, stale-result discard).

---

## 0.1.0

* Initial release.
* Four grid modes: `static`, `lazyPaged`, `infinite`, and `select`.
* Built-in cell renderers: `identifier`, `twoLine`, `avatarTwoLine`, `currency`, `date`, `statusChip`, `actions`.
* Column resizing, sorting, and column-visibility manager.
* Three density presets: `compact`, `standard`, `comfortable`.
* Multi-row selection with customisable summary bar and bulk actions.
* Theming via `TablexThemeData`.
* i18n support via `slang`.
