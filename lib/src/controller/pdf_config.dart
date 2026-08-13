import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

/// Configuration passed to [TablexController.exportToPdf] and
/// [TablexController.exportSelectedToPdf].
///
/// The built-in PDF fonts (Helvetica / Times) only cover the Latin character
/// set. Supply font data whenever your table contains Arabic, Hebrew, CJK, or
/// any other non-Latin script. RTL direction is detected automatically from
/// cell content by default; set [isRtl] to override that and force a
/// specific direction instead.
///
/// **Two ways to provide a font:**
///
/// 1. **Asset bytes** — load a bundled TTF file with `rootBundle.load()`:
///    ```dart
///    controller.pdfConfig = TablexPdfConfig(
///      fontData: await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
///      fontBoldData: await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
///    );
///    ```
///
/// 2. **Pre-built font** — use `PdfGoogleFonts` from the `printing` package:
///    ```dart
///    controller.pdfConfig = TablexPdfConfig(
///      font: await PdfGoogleFonts.cairoRegular(),
///      fontBold: await PdfGoogleFonts.cairoBold(),
///    );
///    ```
///
/// [font] / [fontBold] take precedence over [fontData] / [fontBoldData] when
/// both are supplied. After setting this once on the controller, all PDF
/// exports — including toolbar buttons — use it automatically.
class TablexPdfConfig {
  const TablexPdfConfig({
    this.fontData,
    this.fontBoldData,
    this.font,
    this.fontBold,
    this.isRtl,
  });

  /// Raw TTF bytes for body text, loaded via `rootBundle.load()`.
  ///
  /// Ignored when [font] is also set.
  final ByteData? fontData;

  /// Raw TTF bytes for header text. Falls back to [fontData] when `null`.
  ///
  /// Ignored when [fontBold] is also set.
  final ByteData? fontBoldData;

  /// Pre-built font for body text (e.g. `await PdfGoogleFonts.cairoRegular()`).
  ///
  /// Takes precedence over [fontData].
  final pw.Font? font;

  /// Pre-built font for header text (e.g. `await PdfGoogleFonts.cairoBold()`).
  ///
  /// Takes precedence over [fontBoldData]. Falls back to [font] when `null`.
  final pw.Font? fontBold;

  /// Forces the PDF's text direction/alignment, overriding automatic
  /// content-based RTL detection. Pass the app's current direction at
  /// export time (e.g. `Directionality.of(context) == TextDirection.rtl`)
  /// so the exported document matches what the user is looking at,
  /// regardless of what scripts appear in the cell data. Leave `null` to
  /// keep the existing auto-detect-from-content behavior.
  ///
  /// A plain `bool` (rather than [pw.TextDirection]) so callers don't need
  /// a direct dependency on the `pdf` package just to set this.
  final bool? isRtl;
}
