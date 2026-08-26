import '../../domain/entities/alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../../domain/entities/alert_type.dart';
import '../../domain/entities/metric_type.dart';
import '../datasources/alerts/alerts_remote_datasource.dart';
import '../models/paginated_response.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  final AlertsRemoteDataSource _dataSource;
  AlertsRepositoryImpl(this._dataSource);

  @override
  Future<PaginatedResponse<Alert>> getAlerts({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    AlertType? alertType,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dataSource.fetchAlerts(
      sensorId: sensorId,
      deviceId: deviceId,
      metric: metric,
      alertType: alertType,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
    return PaginatedResponse(
      items: response.items.map((dto) => dto.toEntity()).toList(),
      total: response.total,
      limit: response.limit,
      offset: response.offset,
    );
  }
}
