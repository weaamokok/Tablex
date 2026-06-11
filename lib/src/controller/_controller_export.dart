part of 'controller.dart';

// CSV export and import logic, extracted from TablexController to keep the
// reactive ChangeNotifier core separate from serialization concerns.
// Uses `part of` so all `_private` members of TablexController are accessible.
//
// Pure helpers are top-level functions (no `this`); the public API methods
// live in an extension so they appear as first-class controller methods.

// ---------------------------------------------------------------------------
// Pure CSV helpers (library-private top-level functions)
// ---------------------------------------------------------------------------

/// Sanitises a single value for CSV output (injection prevention + quoting).
String _csvCell(String value) {
  // Prevent CSV injection: values starting with formula chars get a tab
  // prefix. A tab is invisible in spreadsheet cells, survives round-trips
  // through this library without ambiguity, and cannot appear at the start
  // of legitimate data in typical use.
  if (value.isNotEmpty &&
      (value.startsWith('=') ||
          value.startsWith('+') ||
          value.startsWith('-') ||
          value.startsWith('@'))) {
    value = '\t$value';
  }
  // Wrap in double quotes if the value contains a comma, newline, double
  // quote, or the tab we may have just prepended.
  if (value.contains(',') ||
      value.contains('\n') ||
      value.contains('"') ||
      value.contains('\t')) {
    value = '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// RFC 4180 CSV parser. Returns rows as lists of field strings.
List<List<String>> _parseCsvRows(String csv) {
  final rows = <List<String>>[];
  final currentRow = <String>[];
  final buf = StringBuffer();
  bool inQuotes = false;
  int i = 0;

  while (i < csv.length) {
    final ch = csv[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < csv.length && csv[i + 1] == '"') {
          buf.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
      } else {
        buf.write(ch);
      }
    } else {
      if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        currentRow.add(_unescapeCsvCell(buf.toString()));
        buf.clear();
      } else if (ch == '\n') {
        currentRow.add(_unescapeCsvCell(buf.toString()));
        buf.clear();
        rows.add(List.of(currentRow));
        currentRow.clear();
      } else if (ch != '\r') {
        buf.write(ch);
      }
    }
    i++;
  }

  // Flush final field and row.
  currentRow.add(_unescapeCsvCell(buf.toString()));
  if (currentRow.any((f) => f.isNotEmpty)) {
    rows.add(List.of(currentRow));
  }

  return rows;
}

/// Strips the injection-prevention tab prefix added by [_csvCell] so that
/// a CSV round-trip preserves the original value.
String _unescapeCsvCell(String value) {
  if (value.startsWith('\t') && value.length > 1) {
    final rest = value.substring(1);
    if (rest.startsWith('=') ||
        rest.startsWith('+') ||
        rest.startsWith('-') ||
        rest.startsWith('@')) {
      return rest;
    }
  }
  return value;
}

// ---------------------------------------------------------------------------
// Pure Excel helpers (library-private top-level functions)
// ---------------------------------------------------------------------------

/// Maps a raw cell value to a typed [CellValue] for Excel export.
CellValue _toCellValue(dynamic raw, String? formatted) {
  if (raw is int) return IntCellValue(raw);
  if (raw is double) return DoubleCellValue(raw);
  if (raw is bool) return BoolCellValue(raw);
  return TextCellValue(formatted ?? raw.toString());
}

/// Converts an Excel [CellValue] to a plain string for import.
String _cellValueToString(CellValue? value) {
  if (value == null) return '';
  if (value is TextCellValue) return value.value.text ?? '';
  if (value is IntCellValue) return value.value.toString();
  if (value is DoubleCellValue) return value.value.toString();
  if (value is BoolCellValue) return value.value.toString();
  if (value is DateCellValue) {
    return value.asDateTimeLocal().toIso8601String().split('T').first;
  }
  if (value is DateTimeCellValue) {
    return value.asDateTimeLocal().toIso8601String();
  }
  if (value is TimeCellValue) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
  return value.toString();
}

// ---------------------------------------------------------------------------
// Public export / import API — extension on TablexController
// ---------------------------------------------------------------------------

extension TablexControllerExport<T> on TablexController<T> {
  // ── Private helpers ─────────────────────────────────────────────────────────

  List<TablexColumnBase<T>> _visibleColumns(List<TablexColumnBase<T>> columns) =>
      columns
          .where((c) =>
              !c.hide &&
              !isColumnHidden(c.fieldKey) &&
              c.type != TablexColumnType.action)
          .toList(growable: false);

  /// Converts a cell to a display string for export (CSV / Excel / PDF).
  ///
  /// Resolution order:
  /// 1. [TablexColumnBase.exportFormatter] — called with the typed row object.
  /// 2. [TablexColumnBase.formatValueRaw] — uses the column's typed formatter.
  /// 3. Enum `.name` — short name without the class prefix.
  /// 4. [Object.toString] — final fallback.
  String _exportString(TablexColumnBase<T> col, T rowData, dynamic raw) {
    if (raw == null) return '';
    if (col.exportFormatter != null) return col.exportFormatter!(rowData);
    final fmt = col.formatValueRaw(raw);
    if (fmt != null) return fmt;
    if (raw is Enum) return raw.name;
    return raw.toString();
  }

  /// Returns the row keys for [items], preserving display order.
  List<String> _keysForItems(List<T> items) {
    final set = Set<T>.identity()..addAll(items);
    return _rowOrder.where((k) => set.contains(_rowMap[k]!.data)).toList();
  }

  String _buildCsv(List<TablexColumnBase<T>> visible, List<String> keys) {
    final buffer = StringBuffer();
    buffer.writeln(visible.map((c) => _csvCell(c.title)).join(','));
    for (final key in keys) {
      final row = _rowMap[key]!;
      buffer.writeln(visible
          .map((col) =>
              _csvCell(_exportString(col, row.data, row.cells[col.fieldKey])))
          .join(','));
    }
    return buffer.toString();
  }

  Uint8List _buildExcel(
    List<TablexColumnBase<T>> visible,
    List<String> keys,
    String sheetName,
  ) {
    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet();
    final sheet = workbook[sheetName];
    if (defaultSheet != null && defaultSheet != sheetName) {
      workbook.delete(defaultSheet);
    }
    sheet.appendRow(
        visible.map<CellValue>((c) => TextCellValue(c.title)).toList());
    for (final key in keys) {
      final row = _rowMap[key]!;
      sheet.appendRow(visible.map<CellValue>((col) {
        final raw = row.cells[col.fieldKey];
        if (raw == null) return TextCellValue('');
        return _toCellValue(raw, _exportString(col, row.data, raw));
      }).toList());
    }
    final encoded = workbook.encode();
    if (encoded == null) throw StateError('Excel encoding produced no output.');
    return Uint8List.fromList(encoded);
  }

  Future<Uint8List> _buildPdf(
    List<TablexColumnBase<T>> visible,
    List<String> keys, {
    TablexPdfConfig config = const TablexPdfConfig(),
  }) async {
    final headers = visible.map((c) => c.title).toList();
    final rows = keys.map((key) {
      final row = _rowMap[key]!;
      return visible
          .map((col) => _exportString(col, row.data, row.cells[col.fieldKey]))
          .toList();
    }).toList();

    final isNumericCol = visible
        .map((c) =>
            c.type == TablexColumnType.number ||
            c.type == TablexColumnType.currency)
        .toList();

    final doc = pw.Document();
    final pageFormat =
        visible.length > 6 ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    // Flip numeric alignment when RTL so numbers still sit on the right
    // edge of their cell (which is the start edge in RTL layouts).
    final isRtl = config.textDirection == pw.TextDirection.rtl;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Directionality(
            textDirection: config.textDirection,
            child: pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
                font: config.fontBold ?? config.font,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: pw.TextStyle(fontSize: 8, font: config.font),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignments: {
                for (int i = 0; i < visible.length; i++)
                  i: isNumericCol[i]
                      ? (isRtl
                          ? pw.Alignment.centerLeft
                          : pw.Alignment.centerRight)
                      : (isRtl
                          ? pw.Alignment.centerRight
                          : pw.Alignment.centerLeft),
              },
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Public export API ───────────────────────────────────────────────────────

  /// Serialises **all currently loaded rows** to a CSV string.
  ///
  /// For `lazyPaged` and `infinite` grids this includes only the rows
  /// currently in memory (i.e. the loaded page / window), not the full
  /// server-side dataset. Use [exportSelectedToCsv] to export a specific
  /// subset after selecting rows.
  ///
  /// Only visible (non-hidden) columns are included.
  String exportToCsv(List<TablexColumnBase<T>> columns) {
    _checkDisposed();
    return _buildCsv(_visibleColumns(columns), _rowOrder);
  }

  /// Serialises only the **currently selected rows** to a CSV string.
  ///
  /// Returns a header-only CSV when no rows are selected.
  String exportSelectedToCsv(List<TablexColumnBase<T>> columns) {
    _checkDisposed();
    return _buildCsv(
        _visibleColumns(columns), _keysForItems(_state.selectedRows));
  }

  /// Imports rows from a CSV string.
  ///
  /// [rowFactory] receives a `Map<String, String>` keyed by header name (or
  /// by [fieldKeys] when [hasHeader] is `false`) and must return a [TablexRow].
  ///
  /// Set [append] to `true` to add the imported rows after existing ones
  /// instead of replacing them.
  ///
  /// ```dart
  /// controller.importFromCsv(
  ///   csvString,
  ///   (map) => TablexRow(
  ///     data: Employee(name: map['Name']!, salary: double.parse(map['Salary']!)),
  ///     key: map['Id'],
  ///     cells: {'name': map['Name']!, 'salary': double.parse(map['Salary']!)},
  ///   ),
  /// );
  /// ```
  void importFromCsv(
    String csvText,
    TablexRow<T> Function(Map<String, String> row) rowFactory, {
    bool hasHeader = true,
    List<String>? fieldKeys,
    bool append = false,
  }) {
    _checkDisposed();
    final rawRows = _parseCsvRows(csvText);
    if (rawRows.isEmpty) return;

    final keys = hasHeader
        ? rawRows.first
        : (fieldKeys ?? List.generate(rawRows.first.length, (i) => 'col$i'));
    final dataStart = hasHeader ? 1 : 0;

    if (!append) {
      _rowMap.clear();
      _rowOrder.clear();
    }

    for (int i = dataStart; i < rawRows.length; i++) {
      final cells = rawRows[i];
      final map = {
        for (int j = 0; j < keys.length && j < cells.length; j++)
          keys[j]: cells[j],
      };
      final row = rowFactory(map);
      final key = row.key ?? _generateKey();
      _rowMap[key] = TablexRow<T>(
          data: row.data, cells: row.cells, key: key, checked: row.checked);
      _rowOrder.add(key);
    }

    _state = _state.copyWith(
      isInitialized: true,
      selectedRows: append ? null : <T>[],
    );
    _notify();
  }

  /// Serialises **all currently loaded rows** to an Excel (.xlsx) byte array.
  ///
  /// For `lazyPaged` and `infinite` grids this includes only the rows
  /// currently in memory. Use [exportSelectedToExcel] to export a specific
  /// subset after selecting rows.
  ///
  /// Only visible (non-hidden) columns are included.
  Uint8List exportToExcel(
    List<TablexColumnBase<T>> columns, {
    String sheetName = 'Sheet1',
  }) {
    _checkDisposed();
    return _buildExcel(_visibleColumns(columns), _rowOrder, sheetName);
  }

  /// Serialises only the **currently selected rows** to an Excel (.xlsx) byte array.
  ///
  /// Returns a header-only workbook when no rows are selected.
  Uint8List exportSelectedToExcel(
    List<TablexColumnBase<T>> columns, {
    String sheetName = 'Sheet1',
  }) {
    _checkDisposed();
    return _buildExcel(
        _visibleColumns(columns), _keysForItems(_state.selectedRows), sheetName);
  }

  /// Serialises **all currently loaded rows** to a PDF byte array.
  ///
  /// For `lazyPaged` and `infinite` grids this includes only the rows
  /// currently in memory. Use [exportSelectedToPdf] to export a specific
  /// subset after selecting rows.
  ///
  /// Only visible (non-hidden) columns are included. The page is automatically
  /// switched to landscape when more than six columns are visible.
  ///
  /// Pass [pdfConfig] to override the controller's stored [TablexController.pdfConfig]
  /// for this call only. Omit it to use the controller-level config (the common case).
  Future<Uint8List> exportToPdf(
    List<TablexColumnBase<T>> columns, {
    TablexPdfConfig? pdfConfig,
  }) async {
    _checkDisposed();
    return _buildPdf(
      _visibleColumns(columns),
      _rowOrder,
      config: pdfConfig ?? this.pdfConfig,
    );
  }

  /// Serialises only the **currently selected rows** to a PDF byte array.
  ///
  /// Returns a header-only PDF when no rows are selected.
  ///
  /// Pass [pdfConfig] to override the controller's stored [TablexController.pdfConfig]
  /// for this call only. Omit it to use the controller-level config (the common case).
  Future<Uint8List> exportSelectedToPdf(
    List<TablexColumnBase<T>> columns, {
    TablexPdfConfig? pdfConfig,
  }) async {
    _checkDisposed();
    return _buildPdf(
      _visibleColumns(columns),
      _keysForItems(_state.selectedRows),
      config: pdfConfig ?? this.pdfConfig,
    );
  }

  /// Imports rows from an Excel (.xlsx) byte array.
  ///
  /// [rowFactory] receives a `Map<String, String>` keyed by header name (or
  /// by [fieldKeys] when [hasHeader] is `false`) and must return a [TablexRow].
  /// All cell values are converted to strings before being passed to the factory.
  ///
  /// Set [append] to `true` to add rows after the existing ones.
  ///
  /// ```dart
  /// controller.importFromExcel(
  ///   excelBytes,
  ///   (map) => TablexRow(
  ///     data: Employee(name: map['Name']!, salary: double.parse(map['Salary']!)),
  ///     key: map['Id'],
  ///     cells: {'name': map['Name']!, 'salary': double.parse(map['Salary']!)},
  ///   ),
  /// );
  /// ```
  void importFromExcel(
    Uint8List bytes,
    TablexRow<T> Function(Map<String, String> row) rowFactory, {
    int sheetIndex = 0,
    bool hasHeader = true,
    List<String>? fieldKeys,
    bool append = false,
  }) {
    _checkDisposed();
    final workbook = Excel.decodeBytes(bytes);
    final sheetName = workbook.sheets.keys.elementAt(sheetIndex);
    final sheet = workbook.sheets[sheetName]!;
    final dataRows = sheet.rows;
    if (dataRows.isEmpty) return;

    final keys = hasHeader
        ? dataRows.first
            .map((c) => _cellValueToString(c?.value))
            .toList(growable: false)
        : (fieldKeys ??
            List.generate(dataRows.first.length, (i) => 'col$i'));
    final dataStart = hasHeader ? 1 : 0;

    if (!append) {
      _rowMap.clear();
      _rowOrder.clear();
    }

    for (int i = dataStart; i < dataRows.length; i++) {
      final excelRow = dataRows[i];
      final map = {
        for (int j = 0; j < keys.length && j < excelRow.length; j++)
          keys[j]: _cellValueToString(excelRow[j]?.value),
      };
      final row = rowFactory(map);
      final key = row.key ?? _generateKey();
      _rowMap[key] = TablexRow<T>(
          data: row.data, cells: row.cells, key: key, checked: row.checked);
      _rowOrder.add(key);
    }

    _state = _state.copyWith(
      isInitialized: true,
      selectedRows: append ? null : <T>[],
    );
    _notify();
  }
}
