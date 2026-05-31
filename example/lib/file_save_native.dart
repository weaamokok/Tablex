import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveFile(String filename, Uint8List bytes) async {
  final ext = filename.split('.').last;
  final path = await FilePicker.saveFile(
    dialogTitle: 'Save $filename',
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: [ext],
  );
  if (path == null) return false;
  await File(path).writeAsBytes(bytes);
  return true;
}
