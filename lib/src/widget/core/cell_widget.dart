import 'package:flutter/material.dart';
import '../../model/column.dart';
import '../../model/enums.dart';
import '../../model/row.dart';
import '../../renderer/cell_context.dart';
import '../../renderer/cell_renderers.dart';
import '../../theme/grid_theme_data.dart';


class TablexCellWidget<TRow> extends StatelessWidget {
  const TablexCellWidget({
    super.key,
    required this.column,
    required this.row,
    required this.rowIndex,
    required this.isHovered,
    required this.isSelected,
    required this.isEditing,
    required this.density,
    required this.theme,
    required this.width,
    this.onEditConfirm,
  });

  final TablexColumnBase<TRow> column;
  final TablexRow<TRow> row;
  final int rowIndex;
  final bool isHovered;
  final bool isSelected;
  final bool isEditing;
  final TablexDensity density;
  final TablexThemeData theme;
  final double width;
  final void Function(dynamic newValue)? onEditConfirm;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final rawValue = row.cells[column.fieldKey];

    final ctx = TablexCellContext(
      rowIndex: rowIndex,
      isHovered: isHovered,
      isSelected: isSelected,
      isEditing: isEditing,
      textDirection: direction,
      density: density,
      columnField: column.fieldKey,
      columnTitle: column.title,
      columnType: column.type,
    );

    Widget content;

    if (isEditing && column.enableEditing) {
      content = _buildEditCell(context, rawValue);
    } else {
      final built = column.buildCell(row.data, rawValue, ctx);
      if (built != null) {
        content = built;
      } else if (rawValue == null && column.showEmptyAsDash) {
        content = _textCell(column.effectivePlaceholder, context);
      } else {
        content = _buildDefaultForType(context, rawValue, ctx);
      }
    }

    final bgColor = column.backgroundColor ??
        (isSelected
            ? theme.rowSelectedColor
            : isHovered
                ? theme.rowHoverColor
                : (rowIndex.isEven ? theme.rowEvenColor : theme.rowOddColor));

    return Container(
      width: width,
      height: density.rowHeight,
      color: bgColor,
      child: content,
    );
  }

  /// Dispatches to the built-in renderer that matches [column.type].
  /// Falls back to formatted text for types that have no default renderer
  /// (e.g. [TablexColumnType.select], [TablexColumnType.action]) or when
  /// the raw value doesn't match the expected Dart type (e.g. type is
  /// [TablexColumnType.date] but the cell value is a String).
  Widget _buildDefaultForType(
      BuildContext context, dynamic rawValue, TablexCellContext ctx) {
    final type = column.type;

    if (type == TablexColumnType.id || type == TablexColumnType.identifier) {
      return TablexRenderers.identifier<TRow>()(
          row.data, rawValue?.toString() ?? '', ctx);
    }

    if (type == TablexColumnType.boolean && rawValue is bool) {
      return TablexRenderers.boolean<TRow>()(row.data, rawValue, ctx);
    }

    if (type == TablexColumnType.date && rawValue is DateTime) {
      return TablexRenderers.date<TRow>()(row.data, rawValue, ctx);
    }

    if (type == TablexColumnType.dateTime && rawValue is DateTime) {
      return TablexRenderers.dateTime<TRow>()(row.data, rawValue, ctx);
    }

    if (type == TablexColumnType.currency && rawValue is num) {
      return TablexRenderers.currency<TRow>()(row.data, rawValue, ctx);
    }

    final formatted =
        column.formatValueRaw(rawValue) ?? rawValue?.toString() ?? '';

    // Numbers default to end (right in LTR) alignment.
    if (type == TablexColumnType.number) {
      return _textCell(formatted, context, endAlign: true);
    }

    return _textCell(formatted, context);
  }

  Widget _textCell(String text, BuildContext context, {bool endAlign = false}) {
    final direction = Directionality.of(context);
    final isLtr = direction == TextDirection.ltr;
    TextAlign align;
    Alignment boxAlign;
    if (endAlign) {
      align = isLtr ? TextAlign.right : TextAlign.left;
      boxAlign = isLtr ? Alignment.centerRight : Alignment.centerLeft;
    } else if (column.textAlign == TextAlign.start) {
      align = isLtr ? TextAlign.left : TextAlign.right;
      boxAlign = isLtr ? Alignment.centerLeft : Alignment.centerRight;
    } else if (column.textAlign == TextAlign.end) {
      align = isLtr ? TextAlign.right : TextAlign.left;
      boxAlign = isLtr ? Alignment.centerRight : Alignment.centerLeft;
    } else {
      align = column.textAlign;
      boxAlign = isLtr ? Alignment.centerLeft : Alignment.centerRight;
    }
    return Padding(
      padding: theme.cellPadding,
      child: Align(
        alignment: boxAlign,
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: theme.cellTextStyle,
        ),
      ),
    );
  }

  Widget _buildEditCell(BuildContext context, dynamic rawValue) {
    final controller = TextEditingController(text: rawValue?.toString() ?? '');
    return Padding(
      padding: theme.cellPadding,
      child: TextField(
        controller: controller,
        autofocus: true,
        style: theme.cellTextStyle,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          border: UnderlineInputBorder(),
        ),
        onSubmitted: (v) => onEditConfirm?.call(v),
        onTapOutside: (_) => onEditConfirm?.call(controller.text),
      ),
    );
  }
}
