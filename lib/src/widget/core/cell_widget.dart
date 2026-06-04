import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.onEditCancel,
    this.onNavigate,
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
  final VoidCallback? onEditCancel;
  final void Function(dynamic value, TablexEditDirection direction)? onNavigate;

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
    final custom = column.buildEditCell(
      context,
      row.data,
      rawValue,
      (v) => onEditConfirm?.call(v),
      () => onEditCancel?.call(),
    );
    if (custom != null) {
      // Wrap custom widgets so Escape still cancels the edit.
      return Focus(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            onEditCancel?.call();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: custom,
      );
    }

    return _DefaultEditCell(
      rawValue: rawValue,
      columnType: column.type,
      textAlign: column.textAlign,
      theme: theme,
      onSubmit: (v) => onEditConfirm?.call(v),
      onCancel: () => onEditCancel?.call(),
      onNavigate: onNavigate,
    );
  }
}

// ---------------------------------------------------------------------------
// Default edit cell — stateful to properly manage TextEditingController.
// ---------------------------------------------------------------------------

class _DefaultEditCell extends StatefulWidget {
  const _DefaultEditCell({
    required this.rawValue,
    required this.columnType,
    required this.textAlign,
    required this.theme,
    required this.onSubmit,
    required this.onCancel,
    this.onNavigate,
  });

  final dynamic rawValue;
  final TablexColumnType columnType;
  final TextAlign textAlign;
  final TablexThemeData theme;
  final void Function(dynamic) onSubmit;
  final VoidCallback onCancel;
  final void Function(dynamic value, TablexEditDirection direction)? onNavigate;

  @override
  State<_DefaultEditCell> createState() => _DefaultEditCellState();
}

class _DefaultEditCellState extends State<_DefaultEditCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.rawValue?.toString() ?? '',
    );
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => widget.onSubmit(_parseValue(_controller.text));

  dynamic _parseValue(String text) {
    switch (widget.columnType) {
      case TablexColumnType.number:
        return num.tryParse(text) ?? text;
      case TablexColumnType.currency:
        return double.tryParse(text) ?? text;
      default:
        return text;
    }
  }

  TextInputType get _keyboardType {
    switch (widget.columnType) {
      case TablexColumnType.number:
      case TablexColumnType.currency:
        return const TextInputType.numberWithOptions(
            decimal: true, signed: true);
      default:
        return TextInputType.text;
    }
  }

  TextAlign get _resolvedTextAlign {
    switch (widget.columnType) {
      case TablexColumnType.number:
      case TablexColumnType.currency:
        return TextAlign.right;
      default:
        if (widget.textAlign == TextAlign.start ||
            widget.textAlign == TextAlign.left) {
          return TextAlign.left;
        }
        if (widget.textAlign == TextAlign.end ||
            widget.textAlign == TextAlign.right) {
          return TextAlign.right;
        }
        return widget.textAlign;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;

        if (key == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return KeyEventResult.handled;
        }

        if (widget.onNavigate != null) {
          final parsed = _parseValue(_controller.text);
          if (key == LogicalKeyboardKey.tab) {
            final backward = HardwareKeyboard.instance.isShiftPressed;
            widget.onNavigate!(
              parsed,
              backward
                  ? TablexEditDirection.tabBackward
                  : TablexEditDirection.tabForward,
            );
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowDown) {
            widget.onNavigate!(parsed, TablexEditDirection.arrowDown);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowUp) {
            widget.onNavigate!(parsed, TablexEditDirection.arrowUp);
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: widget.theme.cellPadding,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: widget.theme.cellTextStyle,
            keyboardType: _keyboardType,
            textAlign: _resolvedTextAlign,
            decoration: widget.theme.editInputDecoration ??
                const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  border: UnderlineInputBorder(),
                ),
            onSubmitted: (_) => _submit(),
            onTapOutside: (_) => _submit(),
          ),
        ),
      ),
    );
  }
}
