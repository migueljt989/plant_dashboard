import '../entities/sensor.dart';
import '../entities/metric_type.dart';

abstract class SensorManagementRepository {
  Future<List<Sensor>> getAll();
  Future<List<Sensor>> getByDevice(String deviceId);
  Future<Sensor> create({
    required String deviceId,
    required String name,
    required MetricType metric,
    double? minOk,
    double? maxOk,
  });
  Future<Sensor> update({
    required String sensorId,
    String? name,
    double? minOk,
    double? maxOk,
    bool? isActive,
  });
}
