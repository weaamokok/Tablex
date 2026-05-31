import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/controller.dart';
import '../../model/column.dart';
import '../../model/row.dart';
import '../column_manager/column_manager_button.dart';
import '_file_pick.dart';
import '_file_save.dart';

/// A pre-built toolbar widget that sits above a Tablex grid and provides
/// column-visibility management, CSV/Excel export, and CSV/Excel import.
///
/// ## Out-of-the-box usage
///
/// Place it in the `tableHeader` slot of [TablexConsumer], or directly above
/// a `Tablex.static` widget. Provide [importRowFactory] to enable import
/// buttons:
///
/// ```dart
/// TablexToolbar<Employee>(
///   controller: _controller,
///   columns: _columns,
///   importRowFactory: (map) => TablexRow(
///     data: Employee.fromMap(map),
///     key: map['id'],
///     cells: {'name': map['name']!, 'salary': double.parse(map['salary']!)},
///   ),
/// )
/// ```
///
/// ## Overriding individual actions
///
/// Supply one or more override callbacks to replace the built-in behaviour for
/// that action while keeping everything else as-is:
///
/// ```dart
/// TablexToolbar<Employee>(
///   controller: _controller,
///   columns: _columns,
///   // Receive the CSV string and do your own thing (e.g. server upload).
///   onExportCsv: (csv) async => await api.uploadCsv(csv),
///   // Receive the xlsx bytes and save them your way.
///   onExportExcel: (bytes) async => await FileSaver.saveFile(bytes),
///   // Fully custom import — call controller.importFromCsv yourself.
///   onImportCsv: () async { ... },
/// )
/// ```
class TablexToolbar<T> extends StatefulWidget {
  const TablexToolbar({
    super.key,
    required this.controller,
    required this.columns,
    this.showColumnManager = true,
    this.showExport = true,
    this.importRowFactory,
    this.onExportCsv,
    this.onExportExcel,
    this.onImportCsv,
    this.onImportExcel,
    this.leading,
    this.actions,
    this.importCsvIcon,
    this.importExcelIcon,
    this.exportCsvIcon,
    this.exportExcelIcon,
    this.columnManagerIcon,
    this.columnTileBuilder,
  });

  /// The controller that owns the grid's row and column state.
  final TablexController<T> controller;

  /// The column list — the same one you pass to the grid widget.
  final List<TablexColumnBase<T>> columns;

  /// Whether to show the column-visibility manager button.
  /// Defaults to `true`.
  final bool showColumnManager;

  /// Whether to show the export CSV / export Excel buttons.
  /// Defaults to `true`.
  final bool showExport;

  /// Providing this enables the built-in import buttons.
  ///
  /// The factory receives a `Map<String, String>` keyed by the header names
  /// in the file and must return a [TablexRow<T>]. The map values are always
  /// plain strings — parse them to their native types inside the factory.
  ///
  /// Leave `null` to hide import buttons (or supply [onImportCsv] /
  /// [onImportExcel] for fully custom import flows instead).
  final TablexRow<T> Function(Map<String, String> row)? importRowFactory;

  /// Override the CSV export action.
  ///
  /// Receives the ready-to-use CSV string. Use this to upload to a server,
  /// write to a custom path, etc. When `null` the built-in behaviour shows
  /// a copy-to-clipboard dialog.
  final Future<void> Function(String csv)? onExportCsv;

  /// Override the Excel export action.
  ///
  /// Receives the raw `.xlsx` bytes. When `null` the built-in behaviour opens
  /// a native save-file dialog (desktop) or triggers a browser download (web).
  final Future<void> Function(Uint8List bytes)? onExportExcel;

  /// Fully replace the CSV import flow.
  ///
  /// When provided, this is called instead of the built-in file-picker flow.
  /// You are responsible for calling [TablexController.importFromCsv] yourself.
  /// Shown as an import button even when [importRowFactory] is `null`.
  final Future<void> Function()? onImportCsv;

  /// Fully replace the Excel import flow. Same semantics as [onImportCsv].
  final Future<void> Function()? onImportExcel;

  /// Optional widget placed at the leading (left) edge of the toolbar,
  /// before the spacer. Use this for a title or search field.
  final Widget? leading;

  /// Optional extra action widgets appended after the column manager button.
  final List<Widget>? actions;

  // ---------------------------------------------------------------------------
  // Icon overrides
  // ---------------------------------------------------------------------------

  /// Icon widget for the "Import CSV" button.
  /// Defaults to `Icon(Icons.upload_outlined, size: 18)`.
  final Widget? importCsvIcon;

  /// Icon widget for the "Import Excel" button.
  /// Defaults to `Icon(Icons.upload_file_outlined, size: 18)`.
  final Widget? importExcelIcon;

  /// Icon widget for the "Export CSV" button.
  /// Defaults to `Icon(Icons.download_outlined, size: 18)`.
  final Widget? exportCsvIcon;

  /// Icon widget for the "Export Excel" button.
  /// Defaults to `Icon(Icons.table_chart_outlined, size: 18)`.
  final Widget? exportExcelIcon;

  /// Icon widget for the column-visibility manager button.
  /// Defaults to `Icon(Icons.view_column_outlined)`.
  final Widget? columnManagerIcon;

  // ---------------------------------------------------------------------------
  // Column manager tile builder
  // ---------------------------------------------------------------------------

  /// Optional builder that replaces the default checkbox tile for each column
  /// entry in the column-visibility dropdown.
  ///
  /// Receives the column, whether it is currently visible, and a [VoidCallback]
  /// that toggles it. Return `null` to fall back to the default tile.
  ///
  /// ```dart
  /// columnTileBuilder: (context, col, isVisible, onToggle) => SwitchListTile(
  ///   title: Text(col.title),
  ///   value: isVisible,
  ///   onChanged: (_) => onToggle(),
  /// ),
  /// ```
  final Widget? Function(
    BuildContext context,
    TablexColumnBase<T> column,
    bool isVisible,
    VoidCallback onToggle,
  )? columnTileBuilder;

  @override
  State<TablexToolbar<T>> createState() => _TablexToolbarState<T>();
}

class _TablexToolbarState<T> extends State<TablexToolbar<T>> {
  bool _busy = false;

  bool get _hasImportCsv =>
      widget.importRowFactory != null || widget.onImportCsv != null;
  bool get _hasImportExcel =>
      widget.importRowFactory != null || widget.onImportExcel != null;

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Export

  Future<void> _exportCsv() async {
    final csv = widget.controller.exportToCsv(widget.columns);
    if (widget.onExportCsv != null) {
      await widget.onExportCsv!(csv);
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export CSV'),
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
    final bytes = widget.controller.exportToExcel(widget.columns);
    if (widget.onExportExcel != null) {
      await widget.onExportExcel!(bytes);
      return;
    }
    await saveFile('export.xlsx', bytes);
  }

  // ---------------------------------------------------------------------------
  // Import

  Future<void> _importCsv() async {
    if (widget.onImportCsv != null) {
      await widget.onImportCsv!();
      return;
    }
    final bytes = await pickFile(['csv']);
    if (bytes == null) return;
    widget.controller.importFromCsv(
      utf8.decode(bytes),
      widget.importRowFactory!,
    );
  }

  Future<void> _importExcel() async {
    if (widget.onImportExcel != null) {
      await widget.onImportExcel!();
      return;
    }
    final bytes = await pickFile(['xlsx']);
    if (bytes == null) return;
    widget.controller.importFromExcel(bytes, widget.importRowFactory!);
  }

  // ---------------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              const Spacer(),
              if (_hasImportCsv)
                _ToolbarIconButton(
                  icon: widget.importCsvIcon ??
                      const Icon(Icons.upload_outlined, size: 18),
                  tooltip: 'Import CSV',
                  onPressed: _busy ? null : () => _run(_importCsv),
                ),
              if (_hasImportExcel)
                _ToolbarIconButton(
                  icon: widget.importExcelIcon ??
                      const Icon(Icons.upload_file_outlined, size: 18),
                  tooltip: 'Import Excel',
                  onPressed: _busy ? null : () => _run(_importExcel),
                ),
              if ((_hasImportCsv || _hasImportExcel) && widget.showExport)
                const _ToolbarDivider(),
              if (widget.showExport) ...[
                _ToolbarIconButton(
                  icon: widget.exportCsvIcon ??
                      const Icon(Icons.download_outlined, size: 18),
                  tooltip: 'Export CSV',
                  onPressed: _busy ? null : () => _run(_exportCsv),
                ),
                _ToolbarIconButton(
                  icon: widget.exportExcelIcon ??
                      const Icon(Icons.table_chart_outlined, size: 18),
                  tooltip: 'Export Excel',
                  onPressed: _busy ? null : () => _run(_exportExcel),
                ),
              ],
              if (widget.showColumnManager) ...[
                if (widget.showExport || _hasImportCsv || _hasImportExcel)
                  const _ToolbarDivider(),
                TablexColumnManagerButton<T>(
                  controller: widget.controller,
                  columns: widget.columns,
                  icon: widget.columnManagerIcon,
                  columnTileBuilder: widget.columnTileBuilder,
                ),
              ],
              if (widget.actions != null) ...widget.actions!,
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: VerticalDivider(
        width: 12,
        color: Theme.of(context).dividerColor,
      ),
    );
  }
}
