import 'device_type.dart';

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final bool isActive;
  final DateTime createdAt;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.createdAt,
  });
}
