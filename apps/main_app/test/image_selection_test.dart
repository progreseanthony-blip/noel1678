import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noel_app/src/shared/utils/image_selection.dart';

class _Picker extends FilePickerPlatform {
  List<PlatformFile> files = [];
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => files.isEmpty ? null : files.first;
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => files;
}

final class _ImageFile extends PlatformFile {
  @override
  final String name;
  final Uint8List contents;
  _ImageFile(this.name, List<int> bytes) : contents = Uint8List.fromList(bytes);
  @override
  Future<Uint8List> readAsBytes() async => contents;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FilePickerPlatform original;
  late _Picker picker;
  setUp(() {
    original = FilePickerPlatform.instance;
    picker = _Picker();
    FilePickerPlatform.instance = picker;
  });
  tearDown(() => FilePickerPlatform.instance = original);

  test('canceling single or multiple selection returns no images', () async {
    expect(await pickImages(), isEmpty);
    expect(await pickImages(multiple: true), isEmpty);
  });
  test('reads selected image data for preview and upload', () async {
    picker.files = [
      _ImageFile('photo.jpg', [1, 2, 3]),
    ];
    final images = await pickImages();
    expect(images.single.name, 'photo.jpg');
    expect(images.single.extension, 'jpg');
    expect(images.single.bytes, [1, 2, 3]);
  });
  test('multiple selection retains every image and its order', () async {
    picker.files = [
      _ImageFile('a.png', [1]),
      _ImageFile('b.jpg', [2]),
    ];
    final images = await pickImages(multiple: true);
    expect(images.map((image) => image.name), ['a.png', 'b.jpg']);
    expect(images.map((image) => image.bytes.single), [1, 2]);
  });
}
