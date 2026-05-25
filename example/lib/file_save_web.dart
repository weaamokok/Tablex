import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

Future<bool> saveFile(String filename, Uint8List bytes) async {
  final blob = Blob(
    [bytes.toJS].toJS,
    BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = URL.createObjectURL(blob);
  (document.createElement('a') as HTMLAnchorElement)
    ..href = url
    ..download = filename
    ..click();
  URL.revokeObjectURL(url);
  return true;
}
