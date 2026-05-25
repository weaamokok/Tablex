import 'package:flutter/material.dart';
import '../../model/column.dart';
import '../../model/enums.dart';
import '../../theme/grid_theme_data.dart';

class TablexColumnGroupHeader<TRow> extends StatelessWidget {
  const TablexColumnGroupHeader({
    super.key,
    required this.groups,
    required this.columns,
    required this.columnWidths,
    required this.hiddenFields,
    required this.density,
    required this.theme,
  });

  final List<TablexColumnGroup> groups;
  final List<TablexColumnBase<TRow>> columns;
  final Map<String, double> columnWidths;
  final Set<String> hiddenFields;
  final TablexDensity density;
  final TablexThemeData theme;

  double _columnWidth(String field) {
    final col = columns.where((c) => c.fieldKey == field).firstOrNull;
    return columnWidths[field] ?? col?.width ?? 150.0;
  }

  double _groupWidth(TablexColumnGroup group) {
    final fields = _leafFields(group);
    return fields.where((f) {
      final col = columns.where((c) => c.fieldKey == f).firstOrNull;
      return col != null && !col.hide && !hiddenFields.contains(f);
    }).fold<double>(0, (sum, f) => sum + _columnWidth(f));
  }

  List<String> _leafFields(TablexColumnGroup group) {
    if (group.fields != null) return group.fields!;
    return group.children!.expand(_leafFields).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: density.headerHeight,
      color: theme.headerBackgroundColor,
      child: Row(
        children: groups.map((g) {
          final w = _groupWidth(g);
          if (w == 0) return const SizedBox.shrink();
          return Container(
            width: w,
            height: density.headerHeight,
            decoration: BoxDecoration(
              color: g.backgroundColor ?? theme.headerBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.borderColor ?? Colors.grey.shade300,
                ),
                right: BorderSide(
                  color: theme.borderColor ?? Colors.grey.shade300,
                ),
              ),
            ),
            child: Center(
              child: Text(
                g.title,
                textAlign: g.titleTextAlign,
                style: theme.headerTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
