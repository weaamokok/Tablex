// Exports saveFile(filename, bytes) → Future<bool>.
// Web: triggers a browser download via dart:html.
// Native: opens a save-file dialog via file_picker and writes with dart:io.
export 'file_save_native.dart' if (dart.library.html) 'file_save_web.dart';
