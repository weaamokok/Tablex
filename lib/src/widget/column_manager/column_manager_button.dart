import 'package:flutter/material.dart';
import '../../controller/controller.dart';
import '../../model/column.dart';
import '../../../i18n/strings.g.dart';

/// An [IconButton] that opens a dropdown menu for toggling column visibility.
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
/// [columnTileBuilder] replaces the default checkbox row for each column entry.
/// Receives the column definition, whether it is currently visible, and a
/// callback to toggle it:
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

  /// Optional builder that replaces the default checkbox tile for each column
  /// entry. Receives the column, its current visibility state, and a
  /// [VoidCallback] that toggles the column when called.
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
              return MenuItemButton(
                onPressed: onToggle,
                leadingIcon: Icon(
                  isVisible ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                ),
                child: Text(col.title),
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
