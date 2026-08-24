import '../../domain/entities/sensor.dart';
import '../../domain/entities/metric_type.dart';

class SensorDto {
  final String id;
  final String deviceId;
  final String name;
  final String metric;
  final String unit;
  final double? minOk;
  final double? maxOk;
  final bool isActive;
  final String createdAt;

  const SensorDto({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.metric,
    required this.unit,
    this.minOk,
    this.maxOk,
    required this.isActive,
    required this.createdAt,
  });

  factory SensorDto.fromJson(Map<String, dynamic> json) => SensorDto(
        id: json['id'] as String,
        deviceId: json['device_id'] as String,
        name: json['name'] as String,
        metric: json['metric'] as String,
        unit: json['unit'] as String,
        minOk: (json['min_ok'] as num?)?.toDouble(),
        maxOk: (json['max_ok'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'name': name,
        'metric': metric,
        'unit': unit,
        'min_ok': minOk,
        'max_ok': maxOk,
        'is_active': isActive,
        'created_at': createdAt,
      };

  Sensor toEntity() => Sensor(
        id: id,
        deviceId: deviceId,
        name: name,
        metric: MetricType.fromString(metric),
        unit: unit,
        minOk: minOk,
        maxOk: maxOk,
        isActive: isActive,
        createdAt: DateTime.parse(createdAt),
      );
}
