import 'metric_type.dart';

class Reading {
  final String id;
  final String sensorId;
  final String sensorName;
  final String deviceId;
  final MetricType metric;
  final String unit;
  final double value;
  final DateTime recordedAt;

  const Reading({
    required this.id,
    required this.sensorId,
    required this.sensorName,
    required this.deviceId,
    required this.metric,
    required this.unit,
    required this.value,
    required this.recordedAt,
  });
}
