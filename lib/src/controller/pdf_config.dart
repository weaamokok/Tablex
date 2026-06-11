import 'dart:typed_data';

/// Configuration passed to [TablexController.exportToPdf] and
/// [TablexController.exportSelectedToPdf].
///
/// The built-in PDF fonts (Helvetica / Times) only cover the Latin character
/// set. Supply [fontData] (and optionally [fontBoldData]) loaded from your
/// app's assets whenever your data contains Arabic, Hebrew, CJK, or any other
/// non-Latin script. No `pdf` package import is required — just pass the raw
/// [ByteData] from `rootBundle.load()`.
///
/// **Usage example (Arabic data):**
/// ```dart
/// // 1. Add a TTF font to your app's assets (pubspec.yaml):
/// //    assets:
/// //      - assets/fonts/Cairo-Regular.ttf
/// //      - assets/fonts/Cairo-Bold.ttf
///
/// // 2. Set the config once on the controller:
/// controller.pdfConfig = TablexPdfConfig(
///   fontData: await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
///   fontBoldData: await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
///   rtl: true,
/// );
/// ```
///
/// After that, all PDF exports — including toolbar buttons — use the config
/// automatically with no further arguments needed.
class TablexPdfConfig {
  const TablexPdfConfig({
    this.fontData,
    this.fontBoldData,
    this.rtl = false,
  });

  /// Raw TTF font data for cell content, loaded via `rootBundle.load()`.
  ///
  /// Must contain glyphs for every character in your data. When `null` the
  /// PDF library's built-in Latin font is used.
  final ByteData? fontData;

  /// Raw TTF font data for column headers. Falls back to [fontData] when `null`.
  final ByteData? fontBoldData;

  /// Set to `true` for right-to-left scripts (Arabic, Hebrew, etc.).
  ///
  /// Flips text direction and adjusts numeric column alignment automatically.
  /// Defaults to `false`.
  final bool rtl;
}
