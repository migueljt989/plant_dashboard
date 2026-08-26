import '../../domain/entities/metric_type.dart';
import '../../domain/entities/reading.dart';

class ReadingDto {
  final String id;
  final String sensorId;
  final String sensorName;
  final String deviceId;
  final String metric;
  final String unit;
  final double value;
  final String recordedAt;

  const ReadingDto({
    required this.id,
    required this.sensorId,
    required this.sensorName,
    required this.deviceId,
    required this.metric,
    required this.unit,
    required this.value,
    required this.recordedAt,
  });

  factory ReadingDto.fromJson(Map<String, dynamic> json) => ReadingDto(
        id: json['id'] as String,
        sensorId: json['sensor_id'] as String,
        sensorName: json['sensor_name'] as String,
        deviceId: json['device_id'] as String,
        metric: json['metric'] as String,
        unit: json['unit'] as String,
        value: (json['value'] as num).toDouble(),
        recordedAt: json['recorded_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sensor_id': sensorId,
        'sensor_name': sensorName,
        'device_id': deviceId,
        'metric': metric,
        'unit': unit,
        'value': value,
        'recorded_at': recordedAt,
      };

  Reading toEntity() => Reading(
        id: id,
        sensorId: sensorId,
        sensorName: sensorName,
        deviceId: deviceId,
        metric: MetricType.fromString(metric),
        unit: unit,
        value: value,
        recordedAt: DateTime.parse(recordedAt),
      );
}
