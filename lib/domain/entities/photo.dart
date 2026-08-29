/// Entidad de dominio que representa los metadatos de una foto capturada
/// por una cámara.
///
/// Modelo puro de dominio: sin dependencias de Flutter, red ni JSON.
class Photo {
  /// Identificador único de la foto.
  final String id;

  /// Identificador del dispositivo de cámara que capturó la foto.
  final String deviceId;

  /// Nombre del archivo de la foto.
  final String filename;

  /// Ruta del archivo en el almacenamiento del backend.
  final String filepath;

  /// Tamaño del archivo en bytes.
  final int sizeBytes;

  /// Tipo de contenido MIME de la foto (ej. "image/jpeg").
  final String contentType;

  /// Momento en que la foto fue capturada.
  final DateTime capturedAt;

  /// Momento en que el registro fue creado en el backend.
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.deviceId,
    required this.filename,
    required this.filepath,
    required this.sizeBytes,
    required this.contentType,
    required this.capturedAt,
    required this.createdAt,
  });
}
