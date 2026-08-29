import '../entities/batch_delete_result.dart';
import '../entities/photo.dart';
import '../../infrastructure/models/paginated_response.dart';

/// Contrato del repositorio de operaciones de cámara.
///
/// La capa de presentación consume este contrato sin conocer detalles de
/// HTTP ni del proveedor de backend. Reutiliza [PaginatedResponse] de la
/// feature readings-and-alerts para la paginación de fotos.
abstract class CameraRepository {
  /// Obtiene fotos paginadas con filtros opcionales.
  ///
  /// Parámetros de filtro (todos opcionales):
  /// - [deviceId]: filtra por dispositivo de cámara específico.
  /// - [from]: inicio del rango temporal (inclusive).
  /// - [to]: fin del rango temporal (inclusive).
  ///
  /// Parámetros de paginación:
  /// - [limit]: cantidad máxima de items por página (default 20).
  /// - [offset]: desplazamiento desde el inicio (default 0).
  Future<PaginatedResponse<Photo>> getPhotos({
    String? deviceId,
    DateTime? from,
    DateTime? to,
    int limit = 20,
    int offset = 0,
  });

  /// Obtiene los metadatos de una foto individual por su [photoId].
  Future<Photo> getPhotoMetadata(String photoId);

  /// Construye la URL completa para descargar el binario de la foto
  /// identificada por [photoId], sin realizar una petición de red.
  String getPhotoDownloadUrl(String photoId);

  /// Dispara una captura bajo demanda en el dispositivo [deviceId] y
  /// devuelve la foto recién capturada.
  Future<Photo> capturePhoto(String deviceId);

  /// Elimina una foto individual identificada por [photoId].
  Future<void> deletePhoto(String photoId);

  /// Elimina un lote de fotos (entre 1 y 50 identificadores) y devuelve
  /// el resultado de la operación.
  Future<BatchDeleteResult> deletePhotos(List<String> photoIds);

  /// Construye la URL completa del stream MJPEG del dispositivo [deviceId],
  /// sin realizar una petición de red.
  String getStreamUrl(String deviceId);
}
