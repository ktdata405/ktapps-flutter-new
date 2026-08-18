import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Web: read bytes from path — not used on web, bytes always come from dart:html.
Future<Uint8List?> readBytesFromPath(String path) async => null;

/// Web: open a native browser file-input dialog and return (bytes, filename).
Future<(Uint8List, String)?> pickFileBytes() async {
  final completer = Completer<(Uint8List, String)?>();

  final input = html.FileUploadInputElement()
    ..accept = '.xlsx,.xls,.csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,'
        'application/vnd.ms-excel,text/csv';

  // Listen before click to avoid race condition
  input.onChange.listen((event) async {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is List<int>) {
        completer.complete((Uint8List.fromList(result), file.name));
      } else if (result is ByteBuffer) {
        completer.complete((result.asUint8List(), file.name));
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) => completer.complete(null));
  });

  // Attach to DOM briefly (required by some browsers)
  html.document.body?.append(input);
  input.click();

  // Clean up after a short delay
  Future.delayed(const Duration(minutes: 5), () {
    input.remove();
    if (!completer.isCompleted) completer.complete(null);
  });

  return completer.future;
}

