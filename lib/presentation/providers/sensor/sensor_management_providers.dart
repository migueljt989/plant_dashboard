import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/sensor.dart';
import '../../../domain/entities/metric_type.dart';
import '../../../domain/repositories/sensor_management_repository.dart';
import '../../../infrastructure/datasources/sensor/sensor_remote_management_datasource.dart';
import '../../../infrastructure/datasources/sensor/sensor_remote_management_datasource_backend.dart';
import '../../../infrastructure/network/dio_provider.dart';
import '../../../infrastructure/repositories/sensor_management_repository_impl.dart';

final sensorManagementDataSourceProvider =
    Provider<SensorRemoteManagementDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return SensorRemoteManagementDataSourceBackend(dio);
});

final sensorManagementRepositoryProvider =
    Provider<SensorManagementRepository>((ref) {
  return SensorManagementRepositoryImpl(
      ref.watch(sensorManagementDataSourceProvider));
});

/// AsyncNotifierProvider for the sensors list + CRUD operations.
final sensorsControllerProvider =
    AsyncNotifierProvider<SensorsController, List<Sensor>>(
        () => SensorsController());

class SensorsController extends AsyncNotifier<List<Sensor>> {
  @override
  Future<List<Sensor>> build() async {
    return ref.read(sensorManagementRepositoryProvider).getAll();
  }

  Future<void> createSensor({
    required String deviceId,
    required String name,
    required MetricType metric,
    double? minOk,
    double? maxOk,
  }) async {
    await ref.read(sensorManagementRepositoryProvider).create(
          deviceId: deviceId,
          name: name,
          metric: metric,
          minOk: minOk,
          maxOk: maxOk,
        );
    ref.invalidateSelf();
  }

  Future<void> updateSensor({
    required String sensorId,
    String? name,
    double? minOk,
    double? maxOk,
    bool? isActive,
  }) async {
    await ref.read(sensorManagementRepositoryProvider).update(
          sensorId: sensorId,
          name: name,
          minOk: minOk,
          maxOk: maxOk,
          isActive: isActive,
        );
    ref.invalidateSelf();
  }
}
