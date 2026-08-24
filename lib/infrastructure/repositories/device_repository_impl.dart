import '../../domain/entities/device.dart';
import '../../domain/entities/device_type.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/device/device_remote_datasource.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource _dataSource;

  DeviceRepositoryImpl(this._dataSource);

  @override
  Future<List<Device>> getAll() async {
    final dtos = await _dataSource.fetchAll();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<DeviceRegistration> register(String name, DeviceType type) async {
    final raw = await _dataSource.register(name, type.name);
    final device = Device(
      id: raw['id'] as String,
      name: raw['name'] as String,
      type: DeviceType.fromString(raw['type'] as String),
      isActive: true,
      createdAt: DateTime.now(),
    );
    final apiKey = raw['api_key'] as String;
    return (device: device, apiKey: apiKey);
  }

  @override
  Future<Device> revoke(String deviceId) async {
    final dto = await _dataSource.revoke(deviceId);
    return dto.toEntity();
  }
}
