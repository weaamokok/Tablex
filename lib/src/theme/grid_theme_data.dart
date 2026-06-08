import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// ============================================================================
// Checkbox theme
// ============================================================================

/// Visual configuration for selection checkboxes in a Tablex grid.
///
/// Pass to [TablexThemeData.checkboxTheme] to customise checkbox appearance
/// without touching the rest of the grid theme.
///
/// ```dart
/// TablexThemeData(
///   checkboxTheme: TablexCheckboxTheme(
///     activeColor: Colors.teal,
///     checkColor: Colors.white,
///     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
///   ),
/// )
/// ```
@immutable
class TablexCheckboxTheme {
  const TablexCheckboxTheme({
    this.activeColor,
    this.checkColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth = 1.5,
    this.doubleBorder = false,
    this.shape,
    this.size = 20.0,
  });

  /// Fill colour of the checkbox when checked.
  /// Defaults to [ColorScheme.primary].
  final Color? activeColor;

  /// Colour of the check mark drawn inside the checkbox.
  /// Defaults to [ColorScheme.onPrimary].
  final Color? checkColor;

  /// Border colour when the checkbox is unchecked.
  /// Defaults to [ColorScheme.outlineVariant].
  final Color? borderColor;

  /// Stroke width of the unchecked border. Defaults to `1.5`.
  final double borderWidth;

  /// Corner radius of the checkbox when [shape] is a [RoundedRectangleBorder].
  /// Defaults to `3` px.
  final double? borderRadius;

  /// Whether to draw a second border when the checkbox is checked, using
  /// [borderColor] and a stroke width of `borderWidth / 2`. This
  /// is a common style in Material 3 designs to make the active state more
  /// distinct, especially when [activeColor] is similar to the background color.
  final bool doubleBorder;

  /// Shape of the checkbox widget. Defaults to a rounded rectangle with a
  /// 2 px corner radius (Material 3 default).
  final OutlinedBorder? shape;

  /// Width and height of the checkbox, in logical pixels. Defaults to `20`.
  final double size;

  /// Returns a copy with all nullable fields resolved from [context]'s
  /// [ColorScheme]. Call once in `build()` alongside [TablexThemeData.resolve].
  TablexCheckboxTheme resolve(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TablexCheckboxTheme(
      activeColor: activeColor ?? cs.primary,
      checkColor: checkColor ?? cs.onPrimary,
      borderColor: borderColor ?? cs.outlineVariant,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      doubleBorder: doubleBorder,
      shape: shape,
      size: size,
    );
  }

  /// Returns a copy with the given fields replaced.
  TablexCheckboxTheme copyWith({
    Color? activeColor,
    Color? checkColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    bool? doubleBorder,
    OutlinedBorder? shape,
    double? size,
  }) {
    return TablexCheckboxTheme(
      activeColor: activeColor ?? this.activeColor,
      checkColor: checkColor ?? this.checkColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      doubleBorder: doubleBorder ?? this.doubleBorder,
      shape: shape ?? this.shape,
      size: size ?? this.size,
    );
  }
}

// ============================================================================
// Grid theme
// ============================================================================

/// Visual configuration for a Tablex grid.
///
/// All colour fields are nullable — call [resolve] inside `build()` to fill
/// every gap from the ambient Material 3 [ColorScheme]. The resolved copy is
/// what the grid widgets actually consume.
///
/// **App-wide theming:** wrap your app (or a subtree) with [TablexTheme]:
///
/// ```dart
/// TablexTheme(
///   data: TablexThemeData(headerBackgroundColor: Colors.indigo.shade900),
///   child: MyApp(),
/// )
/// ```
///
/// **Per-widget override:** pass [theme] directly to [TablexConsumer] or
/// any [Tablex] constructor. Per-widget overrides take precedence over the
/// inherited theme.
@immutable
class TablexThemeData {
  const TablexThemeData({
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
    this.checkboxTheme,
    this.paginationBackgroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.editInputDecoration,
    this.selectionSummaryBarColor,
    this.enableTextSelection = kIsWeb,
    this.emptyCellPlaceholder,
  });

  /// Background colour of the data area. Defaults to [ColorScheme.surface].
  final Color? backgroundColor;

  /// Background colour of the header row. Defaults to
  /// [ColorScheme.surfaceContainerLow].
  final Color? headerBackgroundColor;

  /// Fill colour for even-indexed rows. Defaults to [ColorScheme.surface].
  final Color? rowEvenColor;

  /// Fill colour for odd-indexed rows. Defaults to
  /// [ColorScheme.surfaceContainerLowest].
  final Color? rowOddColor;

  /// Row highlight colour when the pointer hovers over a row. Defaults to
  /// [ColorScheme.surfaceContainerHigh].
  final Color? rowHoverColor;

  /// Row fill when it is in the selection set. Defaults to a translucent
  /// [ColorScheme.primaryContainer].
  final Color? rowSelectedColor;

  /// Colour of all grid borders (outer and between cells). Defaults to
  /// [ColorScheme.outlineVariant].
  final Color? borderColor;

  /// Text style applied to header cells. Defaults to
  /// `labelMedium` with `fontWeight: w600`.
  final TextStyle? headerTextStyle;

  /// Text style applied to data cells. Defaults to `bodySmall`.
  final TextStyle? cellTextStyle;

  /// Size of sort and filter icons in the header. Defaults to `15`.
  final double iconSize;

  /// Padding inside data cells. Defaults to `EdgeInsets.symmetric(horizontal: 12)`.
  final EdgeInsetsGeometry cellPadding;

  /// Padding inside header cells. Defaults to `EdgeInsets.symmetric(horizontal: 12)`.
  final EdgeInsetsGeometry headerPadding;

  /// Whether thin vertical lines are drawn between data cells. Default `false`.
  final bool showVerticalCellBorders;

  /// Whether thin vertical lines are drawn between header cells. Default `false`.
  final bool showVerticalHeaderBorders;

  /// Colour of the circular progress indicator shown during loading.
  /// Defaults to [ColorScheme.primary].
  final Color? loadingIndicatorColor;

  /// Visual style of row and header selection checkboxes.
  /// When `null` the Material 3 defaults are used.
  /// See [TablexCheckboxTheme] for available options.
  final TablexCheckboxTheme? checkboxTheme;

  /// Background colour of the pagination footer bar. Defaults to
  /// [ColorScheme.surfaceContainerLow].
  final Color? paginationBackgroundColor;

  /// Corner radius of the outer grid border. Defaults to 8 px on all corners.
  final BorderRadius borderRadius;

  /// Background colour of the selection summary bar shown when rows are
  /// selected. Defaults to [ColorScheme.surfaceContainerHighest].
  final Color? selectionSummaryBarColor;

  /// Whether cell text is rendered as selectable (copy-able via pointer drag).
  ///
  /// Defaults to `true` on web (`kIsWeb`) and `false` everywhere else.
  /// Set to `true` on desktop if you want the same behaviour there.
  final bool enableTextSelection;

  /// Grid-wide placeholder shown for null/empty cells when no
  /// [TablexColumnBase.emptyCellPlaceholder] is set on the column.
  ///
  /// When `null` the column's own [TablexColumnBase.showEmptyAsDash] flag
  /// controls whether a `'—'` is shown (the default behaviour).
  ///
  /// Example — show `'N/A'` for every empty cell in the grid:
  /// ```dart
  /// TablexThemeData(emptyCellPlaceholder: 'N/A')
  /// ```
  final String? emptyCellPlaceholder;

  /// Decoration applied to the default inline-edit text field.
  ///
  /// When `null` the grid uses a compact underline decoration:
  /// ```dart
  /// InputDecoration(
  ///   isDense: true,
  ///   contentPadding: EdgeInsets.symmetric(vertical: 4),
  ///   border: UnderlineInputBorder(),
  /// )
  /// ```
  /// Supply this to change the border style, add a hint, or remove the
  /// underline entirely — without having to write a full [TablexColumn.editRenderer].
  final InputDecoration? editInputDecoration;

  /// Resolves all nullable fields against the Material 3 theme at [context].
  ///
  /// Call this once inside `build()` and pass the result to child widgets so
  /// they never need to call [Theme.of] themselves.
  TablexThemeData resolve(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return TablexThemeData(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      headerBackgroundColor:
          headerBackgroundColor ?? colorScheme.surfaceContainerLowest,
      rowEvenColor: rowEvenColor ?? colorScheme.surface,
      rowOddColor: rowOddColor ?? colorScheme.surface,
      rowHoverColor: rowHoverColor ?? colorScheme.surfaceContainerLowest,
      rowSelectedColor: rowSelectedColor ?? colorScheme.surfaceContainerHigh,
      borderColor: borderColor ?? colorScheme.surfaceContainerHigh,
      headerTextStyle: headerTextStyle ??
          textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
      cellTextStyle: cellTextStyle ??
          textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
      iconSize: iconSize,
      cellPadding: cellPadding,
      headerPadding: headerPadding,
      showVerticalCellBorders: showVerticalCellBorders,
      showVerticalHeaderBorders: showVerticalHeaderBorders,
      loadingIndicatorColor: loadingIndicatorColor ?? colorScheme.primary,
      checkboxTheme:
          (checkboxTheme ?? const TablexCheckboxTheme()).resolve(context),
      paginationBackgroundColor:
          paginationBackgroundColor ?? colorScheme.surfaceContainerLow,
      borderRadius: borderRadius,
      editInputDecoration: editInputDecoration,
      selectionSummaryBarColor:
          selectionSummaryBarColor ?? colorScheme.surfaceContainerHighest,
      enableTextSelection: enableTextSelection,
      emptyCellPlaceholder: emptyCellPlaceholder,
    );
  }

  /// Returns a copy with the given fields replaced.
  TablexThemeData copyWith({
    Color? backgroundColor,
    Color? headerBackgroundColor,
    Color? rowEvenColor,
    Color? rowOddColor,
    Color? rowHoverColor,
    Color? rowSelectedColor,
    Color? borderColor,
    TextStyle? headerTextStyle,
    TextStyle? cellTextStyle,
    double? iconSize,
    EdgeInsetsGeometry? cellPadding,
    EdgeInsetsGeometry? headerPadding,
    bool? showVerticalCellBorders,
    bool? showVerticalHeaderBorders,
    Color? loadingIndicatorColor,
    TablexCheckboxTheme? checkboxTheme,
    Color? paginationBackgroundColor,
    BorderRadius? borderRadius,
    InputDecoration? editInputDecoration,
    Color? selectionSummaryBarColor,
    bool? enableTextSelection,
  }) {
    return TablexThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      headerBackgroundColor:
          headerBackgroundColor ?? this.headerBackgroundColor,
      rowEvenColor: rowEvenColor ?? this.rowEvenColor,
      rowOddColor: rowOddColor ?? this.rowOddColor,
      rowHoverColor: rowHoverColor ?? this.rowHoverColor,
      rowSelectedColor: rowSelectedColor ?? this.rowSelectedColor,
      borderColor: borderColor ?? this.borderColor,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      cellTextStyle: cellTextStyle ?? this.cellTextStyle,
      iconSize: iconSize ?? this.iconSize,
      cellPadding: cellPadding ?? this.cellPadding,
      headerPadding: headerPadding ?? this.headerPadding,
      showVerticalCellBorders:
          showVerticalCellBorders ?? this.showVerticalCellBorders,
      showVerticalHeaderBorders:
          showVerticalHeaderBorders ?? this.showVerticalHeaderBorders,
      loadingIndicatorColor:
          loadingIndicatorColor ?? this.loadingIndicatorColor,
      checkboxTheme: checkboxTheme ?? this.checkboxTheme,
      paginationBackgroundColor:
          paginationBackgroundColor ?? this.paginationBackgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      editInputDecoration: editInputDecoration ?? this.editInputDecoration,
      selectionSummaryBarColor:
          selectionSummaryBarColor ?? this.selectionSummaryBarColor,
      enableTextSelection: enableTextSelection ?? this.enableTextSelection,
      // ignore: unnecessary_this
      emptyCellPlaceholder: emptyCellPlaceholder ?? this.emptyCellPlaceholder,
    );
  }
}
