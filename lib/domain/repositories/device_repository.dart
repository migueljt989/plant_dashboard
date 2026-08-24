import '../entities/device.dart';
import '../entities/device_type.dart';

/// Record type for register result: the device + its one-time API key.
typedef DeviceRegistration = ({Device device, String apiKey});

abstract class DeviceRepository {
  Future<List<Device>> getAll();
  Future<DeviceRegistration> register(String name, DeviceType type);
  Future<Device> revoke(String deviceId);
}
