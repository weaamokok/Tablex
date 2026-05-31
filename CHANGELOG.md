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
