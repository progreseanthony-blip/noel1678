import 'dart:html' as html;

/// Descarga [bytes] en el navegador con el nombre [filename].
Future<void> saveBytes(List<int> bytes, String filename, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}
