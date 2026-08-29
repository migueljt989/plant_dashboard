import 'package:dio/dio.dart';

import '../../../domain/failures/app_failure.dart';
import '../../models/batch_delete_result_dto.dart';
import '../../models/paginated_response.dart';
import '../../models/photo_dto.dart';
import 'camera_datasource.dart';

/// Implementación REST de [CameraDataSource] usando una instancia de [Dio]
/// autenticada (inyectada por constructor).
///
/// Mapea los errores de red a fallos de dominio:
/// - 404 -> [NotFoundFailure]
/// - cualquier otro error de red -> [NetworkFailure]
class CameraDataSourceBackend implements CameraDataSource {
  final Dio _dio;

  CameraDataSourceBackend(this._dio);

  @override
  Future<PaginatedResponse<PhotoDto>> fetchPhotos({
    String? deviceId,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (deviceId != null) queryParams['device_id'] = deviceId;
      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/cameras/photos',
        queryParameters: queryParams,
      );

      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        PhotoDto.fromJson,
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Recurso no encontrado');
    }
  }

  @override
  Future<PhotoDto> fetchPhotoMetadata(String photoId) async {
    try {
      final response = await _dio.get('/cameras/photos/$photoId');
      return PhotoDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Foto no encontrada');
    }
  }

  @override
  String getPhotoDownloadUrl(String photoId) {
    return '${_baseUrl()}/cameras/photos/$photoId/file';
  }

  @override
  Future<PhotoDto> capturePhoto(String deviceId) async {
    try {
      final response = await _dio.post('/cameras/$deviceId/capture');
      return PhotoDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, 'Cámara no encontrada');
    }
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    try {
      await _dio.delete('/cameras/photos/$photoId');
    } on DioException catch (e) {
      throw _mapError(e, 'Foto no encontrada');
    }
  }

  @override
  Future<BatchDeleteResultDto> deletePhotos(List<String> photoIds) async {
    if (photoIds.isEmpty || photoIds.length > 50) {
      throw ArgumentError.value(
        photoIds.length,
        'photoIds',
        'La lista de fotos a eliminar debe contener entre 1 y 50 elementos',
      );
    }

    try {
      final response = await _dio.delete(
        '/cameras/photos',
        data: {'photo_ids': photoIds},
      );
      return BatchDeleteResultDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Recurso no encontrado');
    }
  }

  @override
  String getStreamUrl(String deviceId) {
    return '${_baseUrl()}/cameras/$deviceId/stream';
  }

  /// Devuelve la base URL de Dio sin barra final, para evitar barras dobles
  /// al concatenar las rutas de cámara.
  String _baseUrl() {
    final baseUrl = _dio.options.baseUrl;
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  /// Mapea una [DioException] al fallo de dominio correspondiente.
  AppFailure _mapError(DioException e, String notFoundMessage) {
    if (e.response?.statusCode == 404) {
      return NotFoundFailure(e.message ?? notFoundMessage);
    }
    return NetworkFailure(e.message ?? 'Error de red');
  }
}
