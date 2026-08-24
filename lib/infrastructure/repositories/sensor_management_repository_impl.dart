import '../../domain/entities/sensor.dart';
import '../../domain/entities/metric_type.dart';
import '../../domain/repositories/sensor_management_repository.dart';
import '../datasources/sensor/sensor_remote_management_datasource.dart';

class SensorManagementRepositoryImpl implements SensorManagementRepository {
  final SensorRemoteManagementDataSource _dataSource;

  SensorManagementRepositoryImpl(this._dataSource);

  @override
  Future<List<Sensor>> getAll() async {
    final dtos = await _dataSource.fetchAll();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<List<Sensor>> getByDevice(String deviceId) async {
    final dtos = await _dataSource.fetchByDevice(deviceId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<Sensor> create({
    required String deviceId,
    required String name,
    required MetricType metric,
    double? minOk,
    double? maxOk,
  }) async {
    final dto = await _dataSource.create(
      deviceId: deviceId,
      name: name,
      metric: metric.toBackendString(),
      minOk: minOk,
      maxOk: maxOk,
    );
    return dto.toEntity();
  }

  @override
  Future<Sensor> update({
    required String sensorId,
    String? name,
    double? minOk,
    double? maxOk,
    bool? isActive,
  }) async {
    final fields = <String, dynamic>{};
    if (name != null) fields['name'] = name;
    if (minOk != null) fields['min_ok'] = minOk;
    if (maxOk != null) fields['max_ok'] = maxOk;
    if (isActive != null) fields['is_active'] = isActive;
    final dto = await _dataSource.update(sensorId, fields);
    return dto.toEntity();
  }
}
