import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Abre el dialogo "guardar como" y escribe [bytes] en la ruta elegida.
/// Si el usuario cancela, no hace nada.
Future<void> saveBytes(List<int> bytes, String filename, String mimeType) async {
  await FilePicker.saveFile(
    dialogTitle: 'Guardar $filename',
    fileName: filename,
    bytes: Uint8List.fromList(bytes),
    mimeType: mimeType,
  );
}
