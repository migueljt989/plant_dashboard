import 'metric_type.dart';
import 'alert_type.dart';
import 'breached_bound.dart';
import 'delivery_status.dart';

class Alert {
  final String id;
  final String sensorId;
  final String sensorName;
  final String deviceId;
  final MetricType metric;
  final String unit;
  final AlertType alertType;
  final double value;
  final BreachedBound? breachedBound;
  final double? minOk;
  final double? maxOk;
  final DateTime triggeredAt;
  final DeliveryStatus deliveryStatus;

  const Alert({
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
}
