/// Row density — controls the height of data rows and the header.
enum TablexDensity {
  /// Tall rows (66 px data, 56 px header). Good for avatars and two-line cells.
  comfortable,

  /// Standard rows (56 px data, 52 px header). The default for most tables.
  standard,

  /// Compact rows (46 px data, 44 px header). Maximises data density.
  compact,
}

extension TablexDensityX on TablexDensity {
  double get rowHeight => switch (this) {
        TablexDensity.comfortable => 66,
        TablexDensity.standard => 56,
        TablexDensity.compact => 46,
      };
  double get headerHeight => switch (this) {
        TablexDensity.comfortable => 56,
        TablexDensity.standard => 52,
        TablexDensity.compact => 44,
      };
}

/// Whether a column is pinned to the start or end of the scroll area.
///
/// Frozen columns remain visible while the user scrolls horizontally.
enum TablexColumnFrozen {
  /// Column scrolls normally (default).
  none,

  /// Column is pinned to the left (or right in RTL).
  start,

  /// Column is pinned to the right (or left in RTL).
  end,
}

/// Row-selection behaviour for the grid.
enum TablexSelectionMode {
  /// No rows can be selected. Tap gestures only trigger [onRowTap].
  none,

  /// At most one row can be selected at a time.
  single,

  /// Any number of rows can be selected simultaneously.
  multiple,
}

/// Semantic type of a column — used by renderers and the cell-context object
/// so custom renderers can branch on column intent.
enum TablexColumnType {
  /// Plain text.
  text,

  /// A numeric value (integer or double).
  number,

  /// A monetary amount — use with [TablexRenderers.currency].
  currency,

  /// A [DateTime] rendered as a date only (no time component).
  date,

  /// A [DateTime] rendered with both date and time.
  dateTime,

  /// A boolean, rendered as a [Checkbox] by default.
  boolean,

  /// An enum-like set of distinct string values — use with
  /// [TablexRenderers.statusChip].
  select,

  /// A column that holds row-level action buttons — use with
  /// [TablexRenderers.actions].
  action,

  /// A numeric or string identifier — displayed in full width.
  id,

  /// A short code or ID displayed in full, with tap-to-copy behaviour.
  /// Use with [TablexRenderers.identifier].
  identifier,
}

/// The direction of keyboard-driven navigation from an inline-edit cell.
///
/// Returned by the grid when the user presses a navigation key while a cell
/// is in edit mode — use this in a custom [TablexColumn.editRenderer] if you
/// want to support the same keyboard shortcuts.
enum TablexEditDirection {
  /// [Tab] — commit and move to the next editable cell (right, then down).
  tabForward,

  /// [Shift]+[Tab] — commit and move to the previous editable cell (left, then up).
  tabBackward,

  /// [↓] Arrow Down — commit and move to the same column in the next row.
  arrowDown,

  /// [↑] Arrow Up — commit and move to the same column in the previous row.
  arrowUp,
}

/// The direction of a column sort.
enum TablexSortDirection {
  ascending,
  descending,
}

/// Operators available for column filters sent to [TablexFetchTask].
enum TablexFilterOperator {
  equals,
  notEquals,
  contains,
  notContains,
  startsWith,
  endsWith,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  between,
  isNull,
  isNotNull,
}

extension TablexFilterOperatorX on TablexFilterOperator {
  /// English fallback label. For a localized label use
  /// `tablexStrings(context).filterOperatorLabel(op.labelKey)`.
  String get label => switch (this) {
        TablexFilterOperator.equals => 'equals',
        TablexFilterOperator.notEquals => 'not equals',
        TablexFilterOperator.contains => 'contains',
        TablexFilterOperator.notContains => 'does not contain',
        TablexFilterOperator.startsWith => 'starts with',
        TablexFilterOperator.endsWith => 'ends with',
        TablexFilterOperator.greaterThan => 'greater than',
        TablexFilterOperator.greaterThanOrEqual => 'greater than or equal',
        TablexFilterOperator.lessThan => 'less than',
        TablexFilterOperator.lessThanOrEqual => 'less than or equal',
        TablexFilterOperator.between => 'between',
        TablexFilterOperator.isNull => 'is empty',
        TablexFilterOperator.isNotNull => 'is not empty',
      };

  /// Slang translation key — pass to
  /// `tablexStrings(context).filterOperatorLabel(op.labelKey)`.
  String get labelKey => switch (this) {
        TablexFilterOperator.equals => 'equals',
        TablexFilterOperator.notEquals => 'notEquals',
        TablexFilterOperator.contains => 'contains',
        TablexFilterOperator.notContains => 'notContains',
        TablexFilterOperator.startsWith => 'startsWith',
        TablexFilterOperator.endsWith => 'endsWith',
        TablexFilterOperator.greaterThan => 'greaterThan',
        TablexFilterOperator.greaterThanOrEqual => 'greaterThanOrEqual',
        TablexFilterOperator.lessThan => 'lessThan',
        TablexFilterOperator.lessThanOrEqual => 'lessThanOrEqual',
        TablexFilterOperator.between => 'between',
        TablexFilterOperator.isNull => 'isEmpty',
        TablexFilterOperator.isNotNull => 'isNotEmpty',
      };

  /// Whether this operator expects a [TablexColumnFilter.value].
  bool get requiresValue =>
      this != TablexFilterOperator.isNull &&
      this != TablexFilterOperator.isNotNull;

  /// Whether this operator expects a second value
  /// ([TablexColumnFilter.valueTo]) for a range comparison.
  bool get requiresSecondValue => this == TablexFilterOperator.between;
}
