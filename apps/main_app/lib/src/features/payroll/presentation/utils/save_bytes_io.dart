import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Abre el dialogo "guardar como" y escribe [bytes] en la ruta elegida.
/// Si el usuario cancela, no hace nada.
Future<void> saveBytes(List<int> bytes, String filename, String mimeType) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Guardar $filename',
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: [filename.split('.').last],
  );
  if (path != null) {
    await File(path).writeAsBytes(bytes);
  }
}
