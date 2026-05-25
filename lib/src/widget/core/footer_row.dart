import 'package:flutter/material.dart';
import '../../model/column.dart';
import '../../model/enums.dart';
import '../../renderer/cell_context.dart';
import '../../theme/grid_theme_data.dart';

class TablexFooterRow<TRow> extends StatelessWidget {
  const TablexFooterRow({
    super.key,
    required this.columns,
    required this.columnWidths,
    required this.hiddenFields,
    required this.allRowData,
    required this.visibleRowData,
    required this.density,
    required this.theme,
  });

  final List<TablexColumnBase<TRow>> columns;
  final Map<String, double> columnWidths;
  final Set<String> hiddenFields;
  final List<TRow> allRowData;
  final List<TRow> visibleRowData;
  final TablexDensity density;
  final TablexThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hasFooter = columns.any(
      (c) =>
          !c.hide &&
          !hiddenFields.contains(c.fieldKey) &&
          c.footerRenderer != null,
    );

    if (!hasFooter) return const SizedBox.shrink();

    return Container(
      height: density.rowHeight,
      color: theme.headerBackgroundColor,
      child: Row(
        children: columns
            .where((c) => !c.hide && !hiddenFields.contains(c.fieldKey))
            .map((col) {
          final w = columnWidths[col.fieldKey] ?? col.width ?? 150.0;
          if (col.footerRenderer == null) {
            return SizedBox(width: w);
          }
          return SizedBox(
            width: w,
            height: density.rowHeight,
            child: col.footerRenderer!(
              TablexFooterContext<dynamic>(
                field: col.fieldKey,
                allRowData: allRowData,
                visibleRowData: visibleRowData,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
