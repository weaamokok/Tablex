import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List?> pickFile(List<String> extensions) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
    withData: true,
  );
  return result?.files.firstOrNull?.bytes;
}
