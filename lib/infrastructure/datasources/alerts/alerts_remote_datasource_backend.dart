import 'package:dio/dio.dart';

import '../../../domain/entities/alert_type.dart';
import '../../../domain/entities/metric_type.dart';
import '../../../domain/failures/app_failure.dart';
import '../../models/alert_dto.dart';
import '../../models/paginated_response.dart';
import 'alerts_remote_datasource.dart';

class AlertsRemoteDataSourceBackend implements AlertsRemoteDataSource {
  final Dio _dio;

  AlertsRemoteDataSourceBackend(this._dio);

  @override
  Future<PaginatedResponse<AlertDto>> fetchAlerts({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    AlertType? alertType,
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
      if (alertType != null) {
        queryParams['alert_type'] = alertType.toBackendString();
      }
      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/alerts',
        queryParameters: queryParams,
      );

      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        AlertDto.fromJson,
      );
    } on DioException catch (e) {
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }
}
