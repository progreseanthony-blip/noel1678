// Guarda bytes en un archivo segun la plataforma:
// - Web: descarga en el navegador (dart:html).
// - Movil/escritorio: dialogo "guardar como" (file_picker + dart:io).
export 'save_bytes_io.dart' if (dart.library.html) 'save_bytes_web.dart';
