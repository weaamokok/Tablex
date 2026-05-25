/// A single data row in a Tablex grid.
///
/// [data] is the original domain object. [cells] is a flat map of
/// `fieldKey → raw value` used internally for display and CSV export.
/// Both are set by the `rowBuilder` callback you provide to the widget.
///
/// ```dart
/// rowBuilder: (employee) => TablexRow(
///   data: employee,
///   cells: {
///     'name': employee.name,
///     'salary': employee.salary,
///   },
/// )
/// ```
///
/// [key] is an optional stable identity string. When omitted the grid
/// generates one automatically. Provide it when you need to address rows
/// programmatically (e.g. via [TablexController.removeRowsByKey]).
///
/// [checked] is reserved for future checkbox-column support and can be
/// ignored for now.
class TablexRow<T> {
  const TablexRow({
    required this.data,
    required this.cells,
    this.key,
    this.checked = false,
  });

  /// The original domain object this row represents.
  final T data;

  /// Flat map of `fieldKey → raw value` built by your `rowBuilder`.
  final Map<String, dynamic> cells;

  /// Optional stable row identifier. Auto-generated when not provided.
  final String? key;

  /// Reserved for checkbox-column support.
  final bool checked;
}
