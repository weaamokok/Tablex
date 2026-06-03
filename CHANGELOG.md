## 0.3.1

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
