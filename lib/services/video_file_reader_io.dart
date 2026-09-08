import 'dart:io';
import 'dart:typed_data';

/// Native implementation to read file bytes from path
Future<Uint8List?> readFileFromPath(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  } catch (e) {
    return null;
  }
}
