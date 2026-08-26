import '../../domain/entities/metric_type.dart';
import '../../domain/entities/reading.dart';
import '../../domain/repositories/readings_repository.dart';
import '../datasources/readings/readings_remote_datasource.dart';
import '../models/paginated_response.dart';

class ReadingsRepositoryImpl implements ReadingsRepository {
  final ReadingsRemoteDataSource _dataSource;
  ReadingsRepositoryImpl(this._dataSource);

  @override
  Future<PaginatedResponse<Reading>> getReadings({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dataSource.fetchReadings(
      sensorId: sensorId,
      deviceId: deviceId,
      metric: metric,
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

  @override
  Future<Reading> getLatestReading({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
  }) async {
    final dto = await _dataSource.fetchLatestReading(
      sensorId: sensorId,
      deviceId: deviceId,
      metric: metric,
    );
    return dto.toEntity();
  }
}
