import '../../models/sensor_dto.dart';

abstract class SensorRemoteManagementDataSource {
  Future<List<SensorDto>> fetchAll();
  Future<List<SensorDto>> fetchByDevice(String deviceId);
  Future<SensorDto> create({
    required String deviceId,
    required String name,
    required String metric,
    double? minOk,
    double? maxOk,
  });
  Future<SensorDto> update(String sensorId, Map<String, dynamic> fields);
}
