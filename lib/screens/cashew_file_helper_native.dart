import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Native: read file bytes from a path using dart:io.
Future<Uint8List?> readBytesFromPath(String path) async {
  try {
    return await File(path).readAsBytes();
  } catch (_) {
    return null;
  }
}

/// Native: open file picker and return (bytes, filename).
Future<(Uint8List, String)?> pickFileBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    withData: true,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;

  Uint8List? bytes = file.bytes;
  if ((bytes == null || bytes.isEmpty) && file.path != null) {
    bytes = await File(file.path!).readAsBytes();
  }
  if (bytes == null || bytes.isEmpty) return null;
  return (bytes, file.name);
}
