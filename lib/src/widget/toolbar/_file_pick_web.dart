import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

Future<Uint8List?> pickFile(List<String> extensions) {
  final completer = Completer<Uint8List?>();
  final input = document.createElement('input') as HTMLInputElement;
  input.type = 'file';
  input.accept = extensions.map((e) => '.$e').join(',');

  input.addEventListener(
    'change',
    (Event _) {
      final file = input.files?.item(0);
      if (file == null) {
        completer.complete(null);
        return;
      }
      final reader = FileReader();
      reader.addEventListener(
        'load',
        (Event _) {
          final jsResult = reader.result;
          if (jsResult == null) {
            completer.complete(null);
          } else {
            completer.complete(
              Uint8List.view((jsResult as JSArrayBuffer).toDart),
            );
          }
        }.toJS,
      );
      reader.addEventListener(
        'error',
        (Event _) {
          completer.complete(null);
        }.toJS,
      );
      reader.readAsArrayBuffer(file);
    }.toJS,
  );

  // Modern browsers fire 'cancel' when the user dismisses the dialog.
  input.addEventListener(
    'cancel',
    (Event _) {
      completer.complete(null);
    }.toJS,
  );

  input.click();
  return completer.future;
}
