import 'package:flutter/material.dart';

/// Configuration for the first-load skeleton state on [Tablex.lazyPaged]
/// and [Tablex.infinite].
///
/// [skeletonData] pre-populates the table with placeholder rows so
/// [builder] has real content to shimmer over.
/// [builder] is only called while `!isInitialized`; it never fires on
/// subsequent page fetches.
///
/// ```dart
/// loadingBuilder: TablexLoadingBuilder(
///   skeletonData: List.generate(13, (_) => Employee.placeholder()),
///   builder: (context, table) => Skeletonizer(enabled: true, child: table),
/// ),
/// ```
class TablexLoadingBuilder<T> {
  const TablexLoadingBuilder({
    required this.skeletonData,
    required this.builder,
  });

  final List<T> skeletonData;
  final Widget Function(BuildContext context, Widget table) builder;
}

/// Replaces the table entirely when a fetch error occurs.
typedef TablexErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
);

/// Fully replaces the selection summary header that appears above the grid
/// when one or more rows are selected.
///
/// Receives the current [selectedRows] and a [clearSelection] callback.
/// When this builder is provided, [selectionActions] and
/// [includeClearSelectionAction] are ignored — the widget returned here is
/// used as-is.
///
/// ```dart
/// selectionSummaryBuilder: (context, selected, clear) => ColoredBox(
///   color: Colors.amber.shade100,
///   child: Row(children: [
///     Text('${selected.length} items'),
///     IconButton(icon: const Icon(Icons.close), onPressed: clear),
///   ]),
/// ),
/// ```
typedef TablexSelectionSummaryBuilder<T> = Widget Function(
  BuildContext context,
  List<T> selectedRows,
  VoidCallback clearSelection,
);

/// An action button rendered in the [TablexConsumer] selection summary bar.
///
/// Each action appears as a [TextButton] with an icon next to a label. The
/// button receives the list of currently selected rows when pressed.
///
/// ```dart
/// selectionActions: [
///   TablexSelectionAction(
///     label: 'Delete selected',
///     icon: Icons.delete_outline,
///     onPressed: (selected) => _bulkDelete(selected),
///   ),
/// ]
/// ```
class TablexSelectionAction<T> {
  const TablexSelectionAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;

  /// Called with all currently selected rows when the user taps this action.
  final void Function(List<T> selected) onPressed;
}
