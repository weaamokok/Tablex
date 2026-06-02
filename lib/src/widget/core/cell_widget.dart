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
      } else if (column.type == TablexColumnType.id ||
          column.type == TablexColumnType.identifier) {
        content = TablexRenderers.identifier<TRow>()(
            row.data, rawValue?.toString() ?? '', ctx);
      } else {
        final formatted = column.formatValueRaw(rawValue);
        content = _textCell(formatted ?? rawValue?.toString() ?? '', context);
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

  Widget _textCell(String text, BuildContext context) {
    final direction = Directionality.of(context);
    TextAlign align;
    if (column.textAlign == TextAlign.start) {
      align = direction == TextDirection.ltr ? TextAlign.left : TextAlign.right;
    } else if (column.textAlign == TextAlign.end) {
      align = direction == TextDirection.ltr ? TextAlign.right : TextAlign.left;
    } else {
      align = column.textAlign;
    }
    return Padding(
      padding: theme.cellPadding,
      child: Align(
        alignment: direction == TextDirection.rtl
            ? Alignment.centerRight
            : Alignment.centerLeft,
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
