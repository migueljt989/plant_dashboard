import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_type.dart';
import '../../domain/entities/breached_bound.dart';
import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/metric_type.dart';

class AlertDto {
  final String id;
  final String sensorId;
  final String sensorName;
  final String deviceId;
  final String metric;
  final String unit;
  final String alertType;
  final double value;
  final String? breachedBound;
  final double? minOk;
  final double? maxOk;
  final String triggeredAt;
  final String deliveryStatus;

  const AlertDto({
    required this.id,
    required this.sensorId,
    required this.sensorName,
    required this.deviceId,
    required this.metric,
    required this.unit,
    required this.alertType,
    required this.value,
    this.breachedBound,
    this.minOk,
    this.maxOk,
    required this.triggeredAt,
    required this.deliveryStatus,
  });

  factory AlertDto.fromJson(Map<String, dynamic> json) => AlertDto(
        id: json['id'] as String,
        sensorId: json['sensor_id'] as String,
        sensorName: json['sensor_name'] as String,
        deviceId: json['device_id'] as String,
        metric: json['metric'] as String,
        unit: json['unit'] as String,
        alertType: json['alert_type'] as String,
        value: (json['value'] as num).toDouble(),
        breachedBound: json['breached_bound'] as String?,
        minOk: (json['min_ok'] as num?)?.toDouble(),
        maxOk: (json['max_ok'] as num?)?.toDouble(),
        triggeredAt: json['triggered_at'] as String,
        deliveryStatus: json['delivery_status'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sensor_id': sensorId,
        'sensor_name': sensorName,
        'device_id': deviceId,
        'metric': metric,
        'unit': unit,
        'alert_type': alertType,
        'value': value,
        'breached_bound': breachedBound,
        'min_ok': minOk,
        'max_ok': maxOk,
        'triggered_at': triggeredAt,
        'delivery_status': deliveryStatus,
      };

  Alert toEntity() => Alert(
        id: id,
        sensorId: sensorId,
        sensorName: sensorName,
        deviceId: deviceId,
        metric: MetricType.fromString(metric),
        unit: unit,
        alertType: AlertType.fromString(alertType),
        value: value,
        breachedBound: breachedBound != null
            ? BreachedBound.fromString(breachedBound!)
            : null,
        minOk: minOk,
        maxOk: maxOk,
        triggeredAt: DateTime.parse(triggeredAt),
        deliveryStatus: DeliveryStatus.fromString(deliveryStatus),
      );
}
