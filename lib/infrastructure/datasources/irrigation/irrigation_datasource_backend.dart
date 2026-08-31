import 'package:dio/dio.dart';

import '../../../domain/failures/app_failure.dart';
import '../../models/irrigation_command_response_dto.dart';
import '../../models/irrigation_session_dto.dart';
import '../../models/irrigation_status_dto.dart';
import '../../models/paginated_response.dart';
import 'irrigation_datasource.dart';

/// Implementación REST de [IrrigationDataSource] usando una instancia de [Dio]
/// autenticada (inyectada por constructor).
///
/// Endpoints:
/// - POST `/irrigation/{device_id}/start`
/// - POST `/irrigation/{device_id}/stop`
/// - GET  `/irrigation/{device_id}/status`
/// - GET  `/irrigation/{device_id}/history?limit=X&offset=Y`
///
/// Validación fail-fast (antes de cualquier petición de red):
/// - `deviceId` vacío -> [ArgumentError]
/// - en `fetchHistory`, `limit` fuera de 1–100 u `offset` < 0 -> [ArgumentError]
///
/// Mapeo de errores de red a fallos de dominio:
/// - 404 -> [NotFoundFailure] (tiene prioridad sobre cualquier otra condición)
/// - 401 -> [SessionExpiredFailure]
/// - error de red u otro status inesperado (p. ej. 500) -> [NetworkFailure]
class IrrigationDataSourceBackend implements IrrigationDataSource {
  final Dio _dio;

  IrrigationDataSourceBackend(this._dio);

  @override
  Future<IrrigationCommandResponseDto> startIrrigation(String deviceId) async {
    _requireDeviceId(deviceId);
    try {
      final response = await _dio.post('/irrigation/$deviceId/start');
      return IrrigationCommandResponseDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Dispositivo de irrigación no encontrado');
    }
  }

  @override
  Future<IrrigationCommandResponseDto> stopIrrigation(String deviceId) async {
    _requireDeviceId(deviceId);
    try {
      final response = await _dio.post('/irrigation/$deviceId/stop');
      return IrrigationCommandResponseDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Dispositivo de irrigación no encontrado');
    }
  }

  @override
  Future<IrrigationStatusDto> fetchStatus(String deviceId) async {
    _requireDeviceId(deviceId);
    try {
      final response = await _dio.get('/irrigation/$deviceId/status');
      return IrrigationStatusDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Dispositivo de irrigación no encontrado');
    }
  }

  @override
  Future<PaginatedResponse<IrrigationSessionDto>> fetchHistory(
    String deviceId, {
    required int limit,
    required int offset,
  }) async {
    _requireDeviceId(deviceId);
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(
        limit,
        'limit',
        'El límite debe estar entre 1 y 100',
      );
    }
    if (offset < 0) {
      throw ArgumentError.value(
        offset,
        'offset',
        'El offset no puede ser negativo',
      );
    }

    try {
      final response = await _dio.get(
        '/irrigation/$deviceId/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        IrrigationSessionDto.fromJson,
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Dispositivo de irrigación no encontrado');
    }
  }

  /// Valida que el [deviceId] no sea vacío antes de construir la ruta o hacer
  /// cualquier petición de red.
  void _requireDeviceId(String deviceId) {
    if (deviceId.isEmpty) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'El deviceId no puede estar vacío',
      );
    }
  }

  /// Mapea una [DioException] al fallo de dominio correspondiente.
  ///
  /// El 404 se comprueba primero para que tenga prioridad sobre cualquier
  /// condición concurrente de error de red.
  AppFailure _mapError(DioException e, String notFoundMessage) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 404) {
      return NotFoundFailure(e.message ?? notFoundMessage);
    }
    if (statusCode == 401) {
      return const SessionExpiredFailure();
    }
    return NetworkFailure(e.message ?? 'Error de red');
  }
}
