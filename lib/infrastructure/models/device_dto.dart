import '../../domain/entities/device.dart';
import '../../domain/entities/device_type.dart';

class DeviceDto {
  final String id;
  final String name;
  final String type;
  final bool isActive;
  final String createdAt;

  const DeviceDto({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.createdAt,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) => DeviceDto(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        isActive: json['is_active'] as bool,
        createdAt: json['created_at'] as String,
      );

  Device toEntity() => Device(
        id: id,
        name: name,
        type: DeviceType.fromString(type),
        isActive: isActive,
        createdAt: DateTime.parse(createdAt),
      );
}
