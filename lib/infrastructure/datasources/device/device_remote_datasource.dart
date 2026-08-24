import '../../models/device_dto.dart';

abstract class DeviceRemoteDataSource {
  Future<List<DeviceDto>> fetchAll();

  /// Returns raw JSON map including the one-time api_key.
  Future<Map<String, dynamic>> register(String name, String type);

  Future<DeviceDto> revoke(String deviceId);
}
