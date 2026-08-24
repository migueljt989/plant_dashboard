import 'metric_type.dart';

class Sensor {
  final String id;
  final String deviceId;
  final String name;
  final MetricType metric;
  final String unit;
  final double? minOk;
  final double? maxOk;
  final bool isActive;
  final DateTime createdAt;

  const Sensor({
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
}
