import '../../models/batch_delete_result_dto.dart';
import '../../models/paginated_response.dart';
import '../../models/photo_dto.dart';

/// Contrato abstracto del datasource de cámaras.
///
/// Habla en términos de datos crudos del proveedor (DTOs), no de entidades de
/// dominio. La implementación concreta (por ejemplo [CameraDataSourceBackend])
/// se encarga de la comunicación real con el backend.
abstract class CameraDataSource {
  /// Lista fotos con filtros opcionales y paginación.
  Future<PaginatedResponse<PhotoDto>> fetchPhotos({
    String? deviceId,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  });

  /// Obtiene los metadatos de una sola foto por su id.
  Future<PhotoDto> fetchPhotoMetadata(String photoId);

  /// Construye la URL de descarga del binario de la foto (sin red).
  String getPhotoDownloadUrl(String photoId);

  /// Dispara una captura bajo demanda en el dispositivo indicado.
  Future<PhotoDto> capturePhoto(String deviceId);

  /// Elimina una sola foto por su id.
  Future<void> deletePhoto(String photoId);

  /// Elimina un lote de fotos (1 a 50 ids).
  Future<BatchDeleteResultDto> deletePhotos(List<String> photoIds);

  /// Construye la URL del stream MJPEG del dispositivo (sin red).
  String getStreamUrl(String deviceId);
}
