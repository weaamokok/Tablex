import 'dart:math' show pi;

import 'package:flutter/material.dart';
import '../../controller/controller.dart';
import '../../model/column.dart';
import '../../model/enums.dart';
import '../../../i18n/strings.g.dart';

/// An [IconButton] that opens a dropdown menu for toggling column visibility
/// and freezing columns to the start or end of the scroll area.
///
/// Drop it into your `tableHeader` slot (or anywhere in the widget tree that
/// has access to the controller):
///
/// ```dart
/// tableHeader: Row(
///   children: [
///     const Spacer(),
///     TablexColumnManagerButton(
///       controller: controller,
///       columns: columns,
///     ),
///   ],
/// ),
/// ```
///
/// [columnPredicate] filters which columns appear in the menu — for example,
/// to exclude action columns that should never be hidden:
///
/// ```dart
/// columnPredicate: (col) => col.type != TablexColumnType.action,
/// ```
///
/// [title] adds a small label at the top of the dropdown. [menuWidth] controls
/// the dropdown width. [icon] overrides the default `view_column_outlined` icon.
///
/// [columnTileBuilder] replaces the default row (visibility checkbox + freeze
/// pin) for each column entry. Receives the column definition, whether it is
/// currently visible, and a callback to toggle visibility:
///
/// ```dart
/// columnTileBuilder: (context, col, isVisible, onToggle) => SwitchListTile(
///   title: Text(col.title),
///   value: isVisible,
///   onChanged: (_) => onToggle(),
/// ),
/// ```
class TablexColumnManagerButton<TRow> extends StatelessWidget {
  const TablexColumnManagerButton({
    super.key,
    required this.controller,
    required this.columns,
    this.icon,
    this.menuWidth = 220,
    this.title,
    this.columnPredicate,
    this.columnTileBuilder,
    this.pinIconBuilder,
  });

  final TablexController<TRow> controller;
  final List<TablexColumnBase<TRow>> columns;

  /// Custom icon widget for the toggle button. Defaults to
  /// [Icons.view_column_outlined].
  final Widget? icon;

  /// Width of the dropdown menu in logical pixels. Defaults to 220.
  final double menuWidth;

  /// Optional label shown at the top of the dropdown.
  final String? title;

  /// Optional filter predicate — only columns for which this returns `true`
  /// appear in the menu. When `null` all columns are listed.
  final bool Function(TablexColumnBase<TRow>)? columnPredicate;

  /// Optional builder that replaces the default tile (visibility checkbox +
  /// freeze pin) for each column entry. Receives the column, its current
  /// visibility state, and a [VoidCallback] that toggles the column when called.
  ///
  /// The returned widget is placed directly inside the [MenuAnchor] child list,
  /// so prefer [MenuItemButton] or a widget of comparable height for
  /// consistent styling. Return `null` to fall back to the default tile.
  final Widget? Function(
    BuildContext context,
    TablexColumnBase<TRow> column,
    bool isVisible,
    VoidCallback onToggle,
  )? columnTileBuilder;

  /// Optional builder for the freeze pin icon shown at the trailing edge of
  /// each default column tile. Receives the column and its current effective
  /// frozen state. Return a widget to replace the default pin icon, or `null`
  /// to keep the default.
  ///
  /// ```dart
  /// pinIconBuilder: (context, col, frozen) => Icon(
  ///   frozen == TablexColumnFrozen.none
  ///     ? Icons.lock_open_outlined
  ///     : Icons.lock_outline,
  ///   size: 16,
  ///   color: frozen != TablexColumnFrozen.none
  ///     ? Theme.of(context).colorScheme.primary
  ///     : null,
  /// ),
  /// ```
  final Widget? Function(
    BuildContext context,
    TablexColumnBase<TRow> column,
    TablexColumnFrozen frozen,
  )? pinIconBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final visible = columnPredicate == null
            ? columns
            : columns.where(columnPredicate!).toList();

        return MenuAnchor(
          menuChildren: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ...visible.map((col) {
              final isVisible = !controller.isColumnHidden(col.fieldKey);
              void onToggle() => controller.toggleColumnHidden(col.fieldKey);
              if (columnTileBuilder != null) {
                final custom =
                    columnTileBuilder!(context, col, isVisible, onToggle);
                if (custom != null) return custom;
              }
              return _ColumnManagerTile<TRow>(
                column: col,
                isVisible: isVisible,
                onToggleVisible: onToggle,
                controller: controller,
                menuWidth: menuWidth,
                pinIconBuilder: pinIconBuilder,
              );
            }),
          ],
          builder: (context, menuController, _) => IconButton(
            icon: icon ?? const Icon(Icons.view_column_outlined),
            tooltip: tablexStrings(context).manageColumns,
            onPressed: menuController.isOpen
                ? menuController.close
                : menuController.open,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Default column tile: visibility checkbox + title + freeze pin
// ---------------------------------------------------------------------------

class _ColumnManagerTile<TRow> extends StatelessWidget {
  const _ColumnManagerTile({
    super.key,
    required this.column,
    required this.isVisible,
    required this.onToggleVisible,
    required this.controller,
    required this.menuWidth,
    this.pinIconBuilder,
  });

  final TablexColumnBase<TRow> column;
  final bool isVisible;
  final VoidCallback onToggleVisible;
  final TablexController<TRow> controller;
  final double menuWidth;
  final Widget? Function(
    BuildContext context,
    TablexColumnBase<TRow> column,
    TablexColumnFrozen frozen,
  )? pinIconBuilder;

  void _cycleFrozen() {
    final effective =
        controller.getColumnFrozen(column.fieldKey, column.frozen);
    final next = switch (effective) {
      TablexColumnFrozen.none => TablexColumnFrozen.start,
      TablexColumnFrozen.start => TablexColumnFrozen.end,
      TablexColumnFrozen.end => TablexColumnFrozen.none,
    };
    controller.setColumnFrozen(column.fieldKey, next);
  }

  @override
  Widget build(BuildContext context) {
    final effective =
        controller.getColumnFrozen(column.fieldKey, column.frozen);
    final colorScheme = Theme.of(context).colorScheme;

    final pinColor = effective == TablexColumnFrozen.none
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
        : colorScheme.primary;

    final pinTooltip = switch (effective) {
      TablexColumnFrozen.none => 'Pin to start',
      TablexColumnFrozen.start => 'Pinned to start — tap to pin to end',
      TablexColumnFrozen.end => 'Pinned to end — tap to unpin',
    };

    final pinIcon = effective == TablexColumnFrozen.none
        ? Icons.push_pin_outlined
        : Icons.push_pin;

    return SizedBox(
      width: menuWidth,
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Visibility toggle
            InkWell(
              onTap: onToggleVisible,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isVisible
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Column title — tapping also toggles visibility
            Expanded(
              child: GestureDetector(
                onTap: onToggleVisible,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    column.title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Freeze pin toggle
            Tooltip(
              message: pinTooltip,
              child: InkWell(
                onTap: _cycleFrozen,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: pinIconBuilder?.call(context, column, effective) ??
                      (effective == TablexColumnFrozen.end
                          ? Transform.rotate(
                              angle: pi,
                              child: Icon(pinIcon, size: 16, color: pinColor),
                            )
                          : Icon(pinIcon, size: 16, color: pinColor)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
