import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'cell_context.dart';

/// Describes a single icon-button action rendered inside an actions column.
///
/// Pass a list of these to [TablexRenderers.actions].
///
/// ```dart
/// TablexRenderers.actions(actions: [
///   TablexAction(
///     icon: Icons.edit,
///     tooltip: 'Edit',
///     onPressed: (employee) => _edit(employee),
///   ),
///   TablexAction(
///     icon: Icons.delete,
///     tooltip: 'Delete',
///     isEnabled: (employee) => employee.canDelete,
///     onPressed: (employee) => _delete(employee),
///   ),
/// ])
/// ```
class TablexAction<TRow> {
  const TablexAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isVisible,
    this.isEnabled,
  });

  final IconData icon;
  final String tooltip;

  /// Called when the user taps the action button for a row.
  final void Function(TRow row) onPressed;

  /// Optional predicate that hides the button for certain rows.
  /// Defaults to always visible when `null`.
  final bool Function(TRow row)? isVisible;

  /// Optional predicate that disables (grays out) the button for certain rows.
  /// Defaults to always enabled when `null`.
  final bool Function(TRow row)? isEnabled;
}

/// Factory class for all built-in cell renderers.
///
/// Every method returns a `Widget Function(TRow, TValue, TablexCellContext)`
/// that you pass directly to [TablexColumn.cellRenderer]:
///
/// ```dart
/// TablexColumn<Employee, String>(
///   fieldKey: 'name',
///   title: 'Name',
///   valueGetter: (e) => e.name,
///   cellRenderer: TablexRenderers.twoLine(
///     secondLine: (e) => e.department,
///   ),
/// )
/// ```
class TablexRenderers {
  const TablexRenderers._();

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  /// Plain text cell with optional colour and style overrides.
  ///
  /// The value is truncated with an ellipsis when it overflows the column width.
  static Widget Function(TRow, String, TablexCellContext) text<TRow>({
    Color? color,
    TextStyle? style,
    TextAlign? align,
  }) =>
      (row, value, ctx) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              value,
              textAlign: align ?? _toTextAlign(ctx),
              overflow: TextOverflow.ellipsis,
              style: style?.copyWith(color: color) ?? TextStyle(color: color),
            ),
          );

  // ---------------------------------------------------------------------------
  // Currency
  // ---------------------------------------------------------------------------

  /// Formatted monetary amount with sign-aware colouring.
  ///
  /// Positive values use [positiveColor] (defaults to the theme's tertiary
  /// colour); negative values use [negativeColor] (defaults to theme error).
  /// Numbers are right-aligned with tabular figures for clean column alignment.
  static Widget Function(TRow, num, TablexCellContext) currency<TRow>({
    Color? positiveColor,
    Color? negativeColor,
    String symbol = '\$',
    int decimalDigits = 2,
  }) =>
      (row, value, ctx) => _CurrencyCell<TRow>(
            row: row,
            value: value,
            ctx: ctx,
            positiveColor: positiveColor,
            negativeColor: negativeColor,
            symbol: symbol,
            decimalDigits: decimalDigits,
          );

  // ---------------------------------------------------------------------------
  // Date
  // ---------------------------------------------------------------------------

  /// Formats a [DateTime] as a date string (no time component).
  ///
  /// [format] follows `package:intl` pattern syntax.
  /// Default: `'dd MMM yyyy'` → `'21 May 2026'`.
  static Widget Function(TRow, DateTime, TablexCellContext) date<TRow>({
    String format = 'dd MMM yyyy',
  }) =>
      (row, value, ctx) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              intl.DateFormat(format).format(value),
              overflow: TextOverflow.ellipsis,
            ),
          );

  // ---------------------------------------------------------------------------
  // DateTime
  // ---------------------------------------------------------------------------

  /// Formats a [DateTime] with both date and time components.
  ///
  /// [format] follows `package:intl` pattern syntax.
  /// Default: `'dd MMM yyyy HH:mm'` → `'21 May 2026 14:30'`.
  static Widget Function(TRow, DateTime, TablexCellContext) dateTime<TRow>({
    String format = 'dd MMM yyyy HH:mm',
  }) =>
      (row, value, ctx) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              intl.DateFormat(format).format(value),
              overflow: TextOverflow.ellipsis,
            ),
          );

  // ---------------------------------------------------------------------------
  // Boolean
  // ---------------------------------------------------------------------------

  /// A read-only [Checkbox]. Pass [onChanged] to make it interactive.
  static Widget Function(TRow, bool, TablexCellContext) boolean<TRow>({
    void Function(bool)? onChanged,
  }) =>
      (row, value, ctx) => Center(
            child: Checkbox(
              value: value,
              onChanged:
                  onChanged == null ? null : (v) => onChanged(v ?? value),
              visualDensity: VisualDensity.compact,
            ),
          );

  // ---------------------------------------------------------------------------
  // Status chip
  // ---------------------------------------------------------------------------

  /// A pill-shaped status chip whose colour is driven by the cell value.
  ///
  /// [colors] maps each possible value to a background colour. The chip is
  /// rendered at 12% opacity fill with a matching border. [labels] maps values
  /// to display strings; falls back to `value.toString()` when omitted.
  ///
  /// ```dart
  /// TablexRenderers.statusChip<Employee, EmployeeStatus>(
  ///   colors: {
  ///     EmployeeStatus.active:   Colors.green,
  ///     EmployeeStatus.inactive: Colors.red,
  ///   },
  ///   labels: {
  ///     EmployeeStatus.active:   'Active',
  ///     EmployeeStatus.inactive: 'Inactive',
  ///   },
  /// )
  /// ```
  static Widget Function(TRow, K, TablexCellContext) statusChip<TRow, K>({
    required Map<K, Color> colors,
    Map<K, String>? labels,
    BorderRadiusGeometry? radius,
    BoxBorder? border,
  }) =>
      (row, value, ctx) {
        final color = colors[value] ?? Colors.grey;
        final label = labels?[value] ?? value.toString();
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              border: border ?? Border.all(color: color.withAlpha(120)),
              borderRadius: radius ?? BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      };

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// A row of [IconButton]s for per-row actions.
  ///
  /// Each [TablexAction] can individually control visibility and enabledness
  /// per row. Invisible actions are omitted from the layout entirely.
  static Widget Function(TRow, dynamic, TablexCellContext) actions<TRow>({
    required List<TablexAction<TRow>> actions,
  }) =>
      (row, _, ctx) => Row(
            mainAxisSize: MainAxisSize.min,
            children: actions
                .where((a) => a.isVisible == null || a.isVisible!(row))
                .map(
                  (a) => IconButton(
                    icon: Icon(a.icon, size: 18),
                    tooltip: a.tooltip,
                    onPressed: (a.isEnabled == null || a.isEnabled!(row))
                        ? () => a.onPressed(row)
                        : null,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                  ),
                )
                .toList(),
          );

  // ---------------------------------------------------------------------------
  // Copyable text
  // ---------------------------------------------------------------------------

  /// A selectable text cell that copies its value on long-press or right-click.
  ///
  /// Unlike [identifier], this renderer shows the copy affordance only on
  /// long-press / right-click and does not display a copy icon on hover.
  static Widget Function(TRow, String, TablexCellContext) copyableText<TRow>({
    Color? color,
    TextStyle? style,
  }) =>
      (row, value, ctx) => GestureDetector(
            onLongPress: () => Clipboard.setData(ClipboardData(text: value)),
            onSecondaryTap: () => Clipboard.setData(ClipboardData(text: value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SelectableText(
                value,
                style: style?.copyWith(color: color) ?? TextStyle(color: color),
                maxLines: 1,
              ),
            ),
          );

  // ---------------------------------------------------------------------------
  // Two-line
  // ---------------------------------------------------------------------------

  /// A cell with a bold primary line and a smaller secondary line below it.
  ///
  /// Requires [TablexDensity.comfortable] or [TablexDensity.standard] to
  /// have enough vertical space for both lines.
  static Widget Function(TRow, String, TablexCellContext) twoLine<TRow>({
    required String Function(TRow) secondLine,
    TextStyle? secondLineStyle,
  }) =>
      (row, value, ctx) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  secondLine(row),
                  overflow: TextOverflow.ellipsis,
                  style: secondLineStyle ??
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );

  // ---------------------------------------------------------------------------
  // Avatar + two-line
  // ---------------------------------------------------------------------------

  /// A [CircleAvatar] followed by a primary and secondary text line.
  ///
  /// [avatar] returns an [ImageProvider] for the row (e.g. `NetworkImage`),
  /// or `null` to fall back to the first letter of the primary value.
  ///
  /// Requires [TablexDensity.comfortable] for sufficient row height.
  static Widget Function(TRow, String, TablexCellContext) avatarTwoLine<TRow>({
    required String Function(TRow) secondLine,
    required ImageProvider? Function(TRow) avatar,
  }) =>
      (row, value, ctx) {
        final img = avatar(row);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: img,
                child: img == null
                    ? Text(
                        value.isNotEmpty ? value[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      secondLine(row),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      };

  // ---------------------------------------------------------------------------
  // Link
  // ---------------------------------------------------------------------------

  /// An underlined, tappable text link.
  ///
  /// [onTap] receives the full row object so you can navigate or open a detail
  /// sheet with all available data.
  static Widget Function(TRow, String, TablexCellContext) link<TRow>({
    required void Function(TRow) onTap,
    Color? color,
  }) =>
      (row, value, ctx) => _LinkCell<TRow>(
            row: row,
            value: value,
            onTap: onTap,
            color: color,
          );

  // ---------------------------------------------------------------------------
  // Identifier — monospace, full value, tap to copy
  // ---------------------------------------------------------------------------

  /// A compact identifier cell that shows the full value and reveals a copy
  /// icon on hover.
  ///
  /// Tapping the cell copies the value to the clipboard. The icon switches to
  /// a green checkmark for two seconds as confirmation. A tooltip showing the
  /// full value is also shown after a short delay — useful when the column is
  /// too narrow to display the value completely.
  ///
  /// Pair with [TablexColumnType.identifier] for correct semantic metadata:
  /// ```dart
  /// TablexColumn<Order, String>(
  ///   fieldKey: 'id',
  ///   title: 'Order ID',
  ///   type: TablexColumnType.identifier,
  ///   valueGetter: (o) => o.id,
  ///   cellRenderer: TablexRenderers.identifier(),
  /// )
  /// ```
  static Widget Function(TRow, String, TablexCellContext) identifier<TRow>({
    Color? color,
    TextStyle? style,
  }) =>
      (row, value, ctx) => _IdentifierCell<TRow>(
            value: value,
            color: color,
            style: style,
          );

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static TextAlign _toTextAlign(TablexCellContext ctx) =>
      ctx.textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left;
}

// ============================================================================
// Private helper widgets
// ============================================================================

class _CurrencyCell<TRow> extends StatelessWidget {
  const _CurrencyCell({
    required this.row,
    required this.value,
    required this.ctx,
    this.positiveColor,
    this.negativeColor,
    this.symbol = '\$',
    this.decimalDigits = 2,
  });

  final TRow row;
  final num value;
  final TablexCellContext ctx;
  final Color? positiveColor;
  final Color? negativeColor;
  final String symbol;
  final int decimalDigits;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pos = positiveColor ?? colorScheme.tertiary;
    final neg = negativeColor ?? colorScheme.error;
    final color = value >= 0 ? pos : neg;
    final formatted =
        intl.NumberFormat.currency(symbol: symbol, decimalDigits: decimalDigits)
            .format(value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        formatted,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _LinkCell<TRow> extends StatelessWidget {
  const _LinkCell({
    required this.row,
    required this.value,
    required this.onTap,
    this.color,
  });

  final TRow row;
  final String value;
  final void Function(TRow) onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => onTap(row),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          value,
          style: TextStyle(
            color: c,
            decoration: TextDecoration.underline,
            decorationColor: c,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _IdentifierCell<TRow> extends StatefulWidget {
  const _IdentifierCell(
      {required this.value, this.color, this.icon, this.style});

  final String value;
  final Color? color;
  final TextStyle? style;
  final Widget? icon;

  @override
  State<_IdentifierCell<TRow>> createState() => _IdentifierCellState<TRow>();
}

class _IdentifierCellState<TRow> extends State<_IdentifierCell<TRow>> {
  bool _isHovered = false;
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final textColor = widget.color ?? cs.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _copy,
        child: Tooltip(
          message: widget.value,
          waitDuration: const Duration(milliseconds: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value,
                    overflow: TextOverflow.ellipsis,
                    style: widget.style ??
                        ts.labelMedium?.copyWith(color: textColor),
                  ),
                ),
                if (_isHovered || _copied)
                  widget.icon ??
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          _copied ? Icons.check : Icons.copy,
                          size: 14,
                          color: _copied ? Colors.green : cs.onSurfaceVariant,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
