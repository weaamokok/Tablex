import 'package:pdf/widgets.dart' as pw;

/// Configuration passed to [TablexController.exportToPdf] and
/// [TablexController.exportSelectedToPdf].
///
/// The built-in PDF fonts (Helvetica / Times) only cover the Latin character
/// set. Pass a [font] loaded from your app's assets whenever your data
/// contains Arabic, Hebrew, CJK, or any other non-Latin script.
///
/// **Usage example (Arabic data):**
/// ```dart
/// // 1. Add a TTF font to your app's assets (pubspec.yaml):
/// //    assets:
/// //      - assets/fonts/Cairo-Regular.ttf
/// //      - assets/fonts/Cairo-Bold.ttf
///
/// // 2. Load and pass the font at export time:
/// final font = pw.Font.ttf(
///   await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
/// );
/// final boldFont = pw.Font.ttf(
///   await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
/// );
///
/// final bytes = await controller.exportToPdf(
///   columns,
///   pdfConfig: TablexPdfConfig(
///     font: font,
///     fontBold: boldFont,
///     textDirection: pw.TextDirection.rtl,
///   ),
/// );
/// ```
class TablexPdfConfig {
  const TablexPdfConfig({
    this.font,
    this.fontBold,
    this.textDirection = pw.TextDirection.ltr,
  });

  /// Font used for all cell content. Must contain glyphs for every character
  /// in your data. When `null` the PDF library's built-in Latin font is used.
  final pw.Font? font;

  /// Font used for column headers. Falls back to [font] when `null`.
  final pw.Font? fontBold;

  /// Text direction applied to headers and cells.
  ///
  /// Set to [pw.TextDirection.rtl] for Arabic, Hebrew, or other right-to-left
  /// scripts. Defaults to [pw.TextDirection.ltr].
  final pw.TextDirection textDirection;
}
