import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';
import '../../theme/grid_theme.dart';
import '../../theme/grid_theme_data.dart';

/// The built-in selection summary bar shown at the top of a grid when one or
/// more rows are selected.
///
/// Supply [onExportSelectedCsv], [onExportSelectedExcel], and/or
/// [onExportSelectedPdf] to show export-selected buttons alongside the row
/// count and clear button.
class TablexSelectionSummaryBar extends StatefulWidget {
  const TablexSelectionSummaryBar({
    super.key,
    required this.count,
    required this.onClear,
    this.totalCount,
    this.onSelectAll,
    this.actions,
    this.onExportSelectedCsv,
    this.onExportSelectedExcel,
    this.onExportSelectedPdf,
  });

  final int count;
  final VoidCallback onClear;

  /// Total number of rows in the grid. Used to determine the tristate checkbox
  /// value (all selected vs. some selected) when [onSelectAll] is provided.
  final int? totalCount;

  /// Called when the user taps the select-all checkbox to select all rows.
  /// When non-null a tristate checkbox is shown at the leading edge of the bar.
  /// Tapping when all rows are selected calls [onClear] instead.
  final VoidCallback? onSelectAll;

  /// Extra action widgets rendered between the row count and the export buttons.
  final List<Widget>? actions;

  /// Called when the user taps the "Export CSV" button in the summary bar.
  /// The callback is responsible for generating and saving/showing the CSV
  /// (e.g. via [TablexController.exportSelectedToCsv]).
  final Future<void> Function()? onExportSelectedCsv;

  /// Called when the user taps the "Export Excel" button in the summary bar.
  final Future<void> Function()? onExportSelectedExcel;

  /// Called when the user taps the "Export PDF" button in the summary bar.
  final Future<void> Function()? onExportSelectedPdf;

  @override
  State<TablexSelectionSummaryBar> createState() =>
      _TablexSelectionSummaryBarState();
}

class _TablexSelectionSummaryBarState extends State<TablexSelectionSummaryBar> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedTheme =
        (TablexTheme.maybeOf(context) ?? const TablexThemeData())
            .resolve(context);
    final cb = resolvedTheme.checkboxTheme ?? const TablexCheckboxTheme();
    final hasExport = widget.onExportSelectedCsv != null ||
        widget.onExportSelectedExcel != null ||
        widget.onExportSelectedPdf != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: resolvedTheme.selectionSummaryBarColor,
      child: Row(
        children: [
          if (widget.onSelectAll != null) ...[
            SizedBox(
              width: cb.size,
              height: cb.size,
              child: Checkbox(
                tristate: true,
                value: widget.totalCount != null &&
                        widget.totalCount! > 0 &&
                        widget.count == widget.totalCount
                    ? true
                    : null,
                onChanged: (_) {
                  if (widget.count == widget.totalCount) {
                    widget.onClear();
                  } else {
                    widget.onSelectAll!();
                  }
                },
                activeColor: cb.activeColor,
                checkColor: cb.checkColor,
                side: BorderSide(
                  color: cb.borderColor ?? cs.outlineVariant,
                  width: cb.borderWidth,
                ),
                shape: cb.shape,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
          ],
          const SizedBox(
            width: 50,
          ),
          Text(
            tablexStrings(context).selected(widget.count),
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (widget.actions != null) ...widget.actions!,
          if (hasExport) ...[
            if (widget.actions?.isNotEmpty == true) const SizedBox(width: 4),
            if (widget.onExportSelectedCsv != null)
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 18),
                tooltip: 'Export selected as CSV',
                color: cs.onPrimaryContainer,
                visualDensity: VisualDensity.compact,
                onPressed:
                    _busy ? null : () => _run(widget.onExportSelectedCsv!),
              ),
            if (widget.onExportSelectedExcel != null)
              IconButton(
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                tooltip: 'Export selected as Excel',
                color: cs.onPrimaryContainer,
                visualDensity: VisualDensity.compact,
                onPressed:
                    _busy ? null : () => _run(widget.onExportSelectedExcel!),
              ),
            if (widget.onExportSelectedPdf != null)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                tooltip: 'Export selected as PDF',
                color: cs.onPrimaryContainer,
                visualDensity: VisualDensity.compact,
                onPressed:
                    _busy ? null : () => _run(widget.onExportSelectedPdf!),
              ),
            if (_busy)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
          ],
          TextButton(
            onPressed: widget.onClear,
            child: Text(
              tablexStrings(context).clear,
              style: TextStyle(color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
