import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/scheduler.dart';
import '../model/column.dart';
import '../model/enums.dart';
import '../model/query.dart';
import '../model/response.dart';
import '../model/row.dart';
import 'state.dart';
import 'pdf_config.dart';

part '_controller_rows.dart';
part '_controller_query.dart';
part '_controller_selection.dart';
part '_controller_columns.dart';
part '_controller_export.dart';

/// Central controller for a Tablex grid.
///
/// `TablexController` is a [ChangeNotifier] — the grid rebuilds whenever any
/// mutating method is called. You can also add your own listeners:
///
/// ```dart
/// controller.addListener(() {
///   print('selection: ${controller.selectedRows}');
/// });
/// ```
///
/// **Lifecycle:** if you create the controller yourself, dispose it when the
/// owning widget is disposed:
///
/// ```dart
/// final _controller = TablexController<Employee>();
///
/// @override
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
/// ```
///
/// When passed to [TablexConsumer] or [Tablex] without creating your own
/// controller, the widget manages the lifecycle automatically.
class TablexController<T> extends ChangeNotifier {
  /// Creates a controller.
  ///
  /// [initialQuery] sets the starting page, page-size, sort, and filters.
  /// [selectionMode] is kept in sync with the widget — pass it here when you
  /// create the controller outside the widget tree and need selection APIs to
  /// respect the mode from the start.
  TablexController({
    TablexQuery initialQuery = const TablexQuery(),
    TablexSelectionMode selectionMode = TablexSelectionMode.none,
    this.pdfConfig = const TablexPdfConfig(),
  })  : _selectionMode = selectionMode,
        _state = TablexState<T>(query: initialQuery);

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  TablexState<T> _state;

  /// The current immutable state snapshot. Prefer the typed getters for
  /// common operations; read [state] directly only when you need multiple
  /// fields from the same snapshot.
  TablexState<T> get state => _state;

  /// PDF export configuration (font, text direction) used by [exportToPdf]
  /// and [exportSelectedToPdf]. Set once on the controller so every export
  /// path — including toolbar buttons — picks it up automatically.
  ///
  /// ```dart
  /// controller.pdfConfig = TablexPdfConfig(
  ///   font: pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf')),
  ///   fontBold: pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf')),
  ///   textDirection: pw.TextDirection.rtl,
  /// );
  /// ```
  TablexPdfConfig pdfConfig;

  bool _disposed = false;
  bool _pendingNotify = false;

  final Map<String, TablexRow<T>> _rowMap = {};
  final List<String> _rowOrder = [];

  final ValueNotifier<int> _refreshSignal = ValueNotifier(0);

  /// A listenable that increments every time [refresh] is called.
  /// The grid's pagination / infinite-scroll layer listens to this to
  /// invalidate caches and re-fetch.
  ValueListenable<int> get refreshSignal => _refreshSignal;

  TablexSelectionMode _selectionMode;

  // Package-private setter — called once by the widget layer during init.
  set selectionMode(TablexSelectionMode m) => _selectionMode = m;

  static int _keyCounter = 0;
  String _generateKey() => 'row_${++_keyCounter}';

  // ---------------------------------------------------------------------------
  // Guard helpers
  // ---------------------------------------------------------------------------

  void _checkDisposed() {
    if (_disposed) throw StateError('TablexController has been disposed.');
  }

  void _notify() {
    if (_disposed) return;
    // Defer if we're in the middle of a build phase to avoid "setState called
    // during build" when replaceRows is called from a widget's initState while
    // sibling widgets have already subscribed to this controller.
    // Deduplicate: multiple mutations in the same build frame share one callback.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_pendingNotify) return;
      _pendingNotify = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _pendingNotify = false;
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _disposed = true;
    _rowMap.clear();
    _rowOrder.clear();
    _refreshSignal.dispose();
    super.dispose();
  }
}
