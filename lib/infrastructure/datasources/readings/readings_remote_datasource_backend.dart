import 'package:dio/dio.dart';

import '../../../domain/entities/metric_type.dart';
import '../../../domain/failures/app_failure.dart';
import '../../models/paginated_response.dart';
import '../../models/reading_dto.dart';
import 'readings_remote_datasource.dart';

class ReadingsRemoteDataSourceBackend implements ReadingsRemoteDataSource {
  final Dio _dio;

  ReadingsRemoteDataSourceBackend(this._dio);

  @override
  Future<PaginatedResponse<ReadingDto>> fetchReadings({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (sensorId != null) queryParams['sensor_id'] = sensorId;
      if (deviceId != null) queryParams['device_id'] = deviceId;
      if (metric != null) queryParams['metric'] = metric.toBackendString();
      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/readings',
        queryParameters: queryParams,
      );

      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        ReadingDto.fromJson,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundFailure(e.message ?? 'Recurso no encontrado');
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<ReadingDto> fetchLatestReading({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (sensorId != null) queryParams['sensor_id'] = sensorId;
      if (deviceId != null) queryParams['device_id'] = deviceId;
      if (metric != null) queryParams['metric'] = metric.toBackendString();

      final response = await _dio.get(
        '/readings/latest',
        queryParameters: queryParams,
      );

      return ReadingDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundFailure(e.message ?? 'Lectura no encontrada');
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }
}
