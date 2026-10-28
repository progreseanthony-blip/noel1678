import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Image data retained for previews and uploads after the native picker closes.
class SelectedImage {
  final String name;
  final String? extension;
  final Uint8List bytes;

  const SelectedImage({
    required this.name,
    required this.extension,
    required this.bytes,
  });
}

Future<List<SelectedImage>> pickImages({bool multiple = false}) async {
  final List<PlatformFile> files;
  if (multiple) {
    files = await FilePicker.pickFiles(type: FileType.image);
  } else {
    final file = await FilePicker.pickFile(type: FileType.image);
    files = file == null ? [] : [file];
  }
  return Future.wait(
    files.map(
      (file) async => SelectedImage(
        name: file.name,
        extension: file.extension,
        bytes: await file.readAsBytes(),
      ),
    ),
  );
}
