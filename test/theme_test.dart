import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tablex/tablex.dart';

// Helper: pump a MaterialApp and expose BuildContext for theme resolution
Future<BuildContext> _pumpContext(WidgetTester tester,
    {ThemeData? theme}) async {
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox.shrink();
    }),
  ));
  return ctx;
}

void main() {
  // =========================================================================
  group('TablexCheckboxTheme', () {
    test('default values', () {
      const t = TablexCheckboxTheme();
      expect(t.activeColor, isNull);
      expect(t.checkColor, isNull);
      expect(t.borderColor, isNull);
      expect(t.borderWidth, 1.5);
      expect(t.shape, isNull);
      expect(t.size, 20.0);
    });

    testWidgets('resolve fills null colors from ColorScheme', (tester) async {
      final ctx = await _pumpContext(tester);
      final resolved = const TablexCheckboxTheme().resolve(ctx);
      final cs = Theme.of(ctx).colorScheme;
      expect(resolved.activeColor, cs.primary);
      expect(resolved.checkColor, cs.onPrimary);
      expect(resolved.borderColor, cs.outlineVariant);
    });

    testWidgets('resolve keeps explicitly set colors', (tester) async {
      final ctx = await _pumpContext(tester);
      const t = TablexCheckboxTheme(
        activeColor: Colors.red,
        checkColor: Colors.blue,
        borderColor: Colors.green,
        borderWidth: 3.0,
        size: 24.0,
      );
      final resolved = t.resolve(ctx);
      expect(resolved.activeColor, Colors.red);
      expect(resolved.checkColor, Colors.blue);
      expect(resolved.borderColor, Colors.green);
      expect(resolved.borderWidth, 3.0);
      expect(resolved.size, 24.0);
    });

    testWidgets('resolve preserves non-null shape', (tester) async {
      final ctx = await _pumpContext(tester);
      const shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)));
      final resolved = const TablexCheckboxTheme(shape: shape).resolve(ctx);
      expect(resolved.shape, shape);
    });

    test('copyWith replaces specified fields only', () {
      const original = TablexCheckboxTheme(
        activeColor: Colors.red,
        checkColor: Colors.blue,
        borderColor: Colors.green,
        borderWidth: 2.0,
        size: 18.0,
      );
      final copy = original.copyWith(activeColor: Colors.purple, size: 22.0);
      expect(copy.activeColor, Colors.purple);
      expect(copy.checkColor, Colors.blue); // unchanged
      expect(copy.borderColor, Colors.green); // unchanged
      expect(copy.borderWidth, 2.0); // unchanged
      expect(copy.size, 22.0);
    });

    test('copyWith with no arguments produces equal object', () {
      const original = TablexCheckboxTheme(
          activeColor: Colors.teal, borderWidth: 2.0, size: 16.0);
      final copy = original.copyWith();
      expect(copy.activeColor, original.activeColor);
      expect(copy.borderWidth, original.borderWidth);
      expect(copy.size, original.size);
    });
  });

  // =========================================================================
  group('TablexThemeData', () {
    testWidgets('resolve fills all nullable color fields', (tester) async {
      final ctx = await _pumpContext(tester);
      final resolved = const TablexThemeData().resolve(ctx);
      expect(resolved.backgroundColor, isNotNull);
      expect(resolved.headerBackgroundColor, isNotNull);
      expect(resolved.rowEvenColor, isNotNull);
      expect(resolved.rowOddColor, isNotNull);
      expect(resolved.rowHoverColor, isNotNull);
      expect(resolved.rowSelectedColor, isNotNull);
      expect(resolved.borderColor, isNotNull);
      expect(resolved.headerTextStyle, isNotNull);
      expect(resolved.cellTextStyle, isNotNull);
      expect(resolved.loadingIndicatorColor, isNotNull);
      expect(resolved.paginationBackgroundColor, isNotNull);
    });

    testWidgets('resolve keeps explicitly set colors', (tester) async {
      final ctx = await _pumpContext(tester);
      const theme = TablexThemeData(
        backgroundColor: Colors.amber,
        headerBackgroundColor: Colors.indigo,
        rowEvenColor: Colors.white,
        rowOddColor: Colors.grey,
        rowHoverColor: Colors.blue,
        rowSelectedColor: Colors.green,
        borderColor: Colors.red,
      );
      final resolved = theme.resolve(ctx);
      expect(resolved.backgroundColor, Colors.amber);
      expect(resolved.headerBackgroundColor, Colors.indigo);
      expect(resolved.rowEvenColor, Colors.white);
      expect(resolved.rowOddColor, Colors.grey);
      expect(resolved.rowHoverColor, Colors.blue);
      expect(resolved.rowSelectedColor, Colors.green);
      expect(resolved.borderColor, Colors.red);
    });

    testWidgets('resolve resolves nested checkboxTheme', (tester) async {
      final ctx = await _pumpContext(tester);
      // No explicit checkboxTheme — should be resolved from scheme
      final resolved = const TablexThemeData().resolve(ctx);
      expect(resolved.checkboxTheme, isNotNull);
      expect(resolved.checkboxTheme!.activeColor, isNotNull);
      expect(resolved.checkboxTheme!.checkColor, isNotNull);
      expect(resolved.checkboxTheme!.borderColor, isNotNull);
    });

    testWidgets('resolve respects explicit checkboxTheme', (tester) async {
      final ctx = await _pumpContext(tester);
      const theme = TablexThemeData(
        checkboxTheme: TablexCheckboxTheme(
          activeColor: Colors.pink,
          size: 22.0,
        ),
      );
      final resolved = theme.resolve(ctx);
      expect(resolved.checkboxTheme!.activeColor, Colors.pink);
      expect(resolved.checkboxTheme!.size, 22.0);
    });

    test('copyWith replaces only specified fields', () {
      const original = TablexThemeData(
        backgroundColor: Colors.white,
        borderColor: Colors.black,
        iconSize: 18,
        showVerticalCellBorders: true,
      );
      final copy = original.copyWith(
        backgroundColor: Colors.grey,
        iconSize: 20,
      );
      expect(copy.backgroundColor, Colors.grey);
      expect(copy.borderColor, Colors.black); // unchanged
      expect(copy.iconSize, 20);
      expect(copy.showVerticalCellBorders, true); // unchanged
    });

    test('copyWith with checkboxTheme replaces it', () {
      const original = TablexThemeData(
        checkboxTheme: TablexCheckboxTheme(activeColor: Colors.red),
      );
      final copy = original.copyWith(
        checkboxTheme: const TablexCheckboxTheme(activeColor: Colors.blue),
      );
      expect(copy.checkboxTheme!.activeColor, Colors.blue);
    });

    test('non-color fields use their defaults when not specified', () {
      const t = TablexThemeData();
      expect(t.iconSize, 15);
      expect(t.showVerticalCellBorders, false);
      expect(t.showVerticalHeaderBorders, false);
      expect(t.borderRadius, const BorderRadius.all(Radius.circular(8)));
    });
  });
}
