import 'package:flutter/widgets.dart';
import 'grid_theme_data.dart';

/// An [InheritedWidget] that propagates a [TablexThemeData] down the tree.
///
/// Wrap your app or a screen subtree to apply a theme to all [Tablex] and
/// [TablexConsumer] widgets within it without passing `theme` to each one
/// individually:
///
/// ```dart
/// TablexTheme(
///   data: TablexThemeData(
///     headerBackgroundColor: Colors.indigo.shade900,
///     rowHoverColor: Colors.indigo.shade50,
///   ),
///   child: Scaffold(body: MyTable()),
/// )
/// ```
///
/// Per-widget `theme` overrides always take precedence over this inherited
/// theme. When neither is set, the grid falls back to a
/// [TablexThemeData.resolve]d default derived from the Material 3
/// [ColorScheme].
class TablexTheme extends InheritedWidget {
  const TablexTheme({super.key, required this.data, required super.child});

  final TablexThemeData data;

  /// Returns the nearest [TablexThemeData] in the widget tree, or `null`
  /// if no [TablexTheme] ancestor exists.
  static TablexThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TablexTheme>()?.data;

  @override
  bool updateShouldNotify(TablexTheme oldWidget) => data != oldWidget.data;
}
