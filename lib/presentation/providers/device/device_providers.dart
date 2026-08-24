import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_type.dart';
import '../../../domain/repositories/device_repository.dart';
import '../../../infrastructure/datasources/device/device_remote_datasource.dart';
import '../../../infrastructure/datasources/device/device_remote_datasource_backend.dart';
import '../../../infrastructure/network/dio_provider.dart';
import '../../../infrastructure/repositories/device_repository_impl.dart';

final deviceDataSourceProvider = Provider<DeviceRemoteDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return DeviceRemoteDataSourceBackend(dio);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(ref.watch(deviceDataSourceProvider));
});

/// AsyncNotifierProvider for the devices list + operations.
final devicesControllerProvider =
    AsyncNotifierProvider<DevicesController, List<Device>>(
        () => DevicesController());

class DevicesController extends AsyncNotifier<List<Device>> {
  @override
  Future<List<Device>> build() async {
    return ref.read(deviceRepositoryProvider).getAll();
  }

  Future<DeviceRegistration> registerDevice(
      String name, DeviceType type) async {
    final result =
        await ref.read(deviceRepositoryProvider).register(name, type);
    // Refresh list after registration
    ref.invalidateSelf();
    await future;
    return result;
  }

  Future<void> revokeDevice(String deviceId) async {
    await ref.read(deviceRepositoryProvider).revoke(deviceId);
    // Refresh list after revocation
    ref.invalidateSelf();
  }
}
