import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> saveFile(String filename, Uint8List bytes) async {
  final ext = filename.split('.').last;

  if (Platform.isAndroid || Platform.isIOS) {
    // On mobile, file_picker.saveFile requires bytes and writes the file
    // itself — it returns the saved path but no manual write is needed.
    await FilePicker.saveFile(
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: [ext],
      bytes: bytes,
    );
    return;
  }

  // Desktop: show a save dialog, then write to the chosen path.
  final path = await FilePicker.saveFile(
    dialogTitle: 'Save $filename',
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: [ext],
  );
  if (path != null) {
    await File(path).writeAsBytes(bytes);
  }
}
