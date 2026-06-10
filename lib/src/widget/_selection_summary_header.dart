part of 'tablex_widget.dart';

// ============================================================================
// Selection summary header
// ============================================================================

class _SelectionSummaryHeader<T> extends StatefulWidget {
  const _SelectionSummaryHeader({
    required this.selectedCount,
    required this.selectedItems,
    required this.density,
    required this.theme,
    required this.onClear,
    required this.columns,
    required this.controller,
    required this.selectionMode,
    this.actions,
    this.includeClearAction = true,
    this.onExportSelectedCsv,
    this.onExportSelectedExcel,
    this.onExportSelectedPdf,
  });

  final int selectedCount;
  final List<T> selectedItems;
  final TablexDensity density;
  final TablexThemeData theme;
  final VoidCallback onClear;
  final List<TablexColumnBase<T>> columns;
  final TablexController<T> controller;
  final TablexSelectionMode selectionMode;
  final List<TablexSelectionAction<T>>? actions;
  final bool includeClearAction;

  /// Override for the CSV export button. When provided, replaces the default
  /// behaviour (show a copy dialog). Pass `null` to keep the default.
  final Future<void> Function(String csv)? onExportSelectedCsv;

  /// Override for the Excel export button. When provided, replaces the default
  /// behaviour (save file via [saveFile]). Pass `null` to keep the default.
  final Future<void> Function(Uint8List bytes)? onExportSelectedExcel;

  /// Override for the PDF export button. When provided, replaces the default
  /// behaviour (save file via [saveFile]). Pass `null` to keep the default.
  final Future<void> Function(Uint8List bytes)? onExportSelectedPdf;

  @override
  State<_SelectionSummaryHeader<T>> createState() =>
      _SelectionSummaryHeaderState<T>();
}

class _SelectionSummaryHeaderState<T>
    extends State<_SelectionSummaryHeader<T>> {
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

  Future<void> _exportCsv() async {
    final csv = widget.controller.exportSelectedToCsv(widget.columns);
    if (widget.onExportSelectedCsv != null) {
      await widget.onExportSelectedCsv!(csv);
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export selected — CSV'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 400),
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Copy & Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel() async {
    final bytes = widget.controller.exportSelectedToExcel(widget.columns);
    if (widget.onExportSelectedExcel != null) {
      await widget.onExportSelectedExcel!(bytes);
      return;
    }
    await saveFile('export_selected.xlsx', bytes);
  }

  Future<void> _exportPdf() async {
    final bytes = await widget.controller.exportSelectedToPdf(widget.columns);
    if (widget.onExportSelectedPdf != null) {
      await widget.onExportSelectedPdf!(bytes);
      return;
    }
    await saveFile('export_selected.pdf', bytes);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = tablexStrings(context);
    final cb = widget.theme.checkboxTheme ?? const TablexCheckboxTheme();

    return Container(
      height: widget.density.headerHeight,
      color: widget.theme.selectionSummaryBarColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (widget.selectionMode == TablexSelectionMode.multiple) ...[
            SizedBox(
              width: cb.size,
              height: cb.size,
              child: Checkbox(
                tristate: true,
                value: widget.selectedCount > 0 &&
                        widget.selectedCount == widget.controller.rows.length
                    ? true
                    : null,
                onChanged: (_) {
                  if (widget.selectedCount == widget.controller.rows.length) {
                    widget.controller.clearSelection();
                  } else {
                    widget.controller
                        .selectAll(widget.controller.getAllRowData());
                  }
                },
                activeColor: cb.activeColor ?? cs.primary,
                checkColor: cb.checkColor ?? cs.onPrimary,
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
          const SizedBox(width: 20),
          Text(
            strings.selected(widget.selectedCount),
            style: widget.theme.headerTextStyle?.copyWith(
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          if (widget.actions != null)
            ...widget.actions!.map(
              (action) => TextButton.icon(
                icon: Icon(action.icon, size: 16),
                label: Text(action.label),
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurfaceVariant,
                ),
                onPressed: () => action.onPressed(widget.selectedItems),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 18),
            tooltip: 'Export selected as CSV',
            color: cs.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: _busy ? null : () => _run(_exportCsv),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            tooltip: 'Export selected as Excel',
            color: cs.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: _busy ? null : () => _run(_exportExcel),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            tooltip: 'Export selected as PDF',
            color: cs.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: _busy ? null : () => _run(_exportPdf),
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          if (widget.includeClearAction)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: strings.clear,
              color: cs.onSurfaceVariant,
              onPressed: widget.onClear,
            ),
        ],
      ),
    );
  }
}
