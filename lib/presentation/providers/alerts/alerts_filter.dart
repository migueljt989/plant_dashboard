import 'package:plant_dashboard/domain/entities/alert_type.dart';
import 'package:plant_dashboard/domain/entities/metric_type.dart';

/// Immutable filter model for the alerts page.
///
/// All fields are optional — only non-null values are included in query params.
class AlertsFilter {
  final String? sensorId;
  final String? deviceId;
  final MetricType? metric;
  final AlertType? alertType;
  final DateTime? from;
  final DateTime? to;

  const AlertsFilter({
    this.sensorId,
    this.deviceId,
    this.metric,
    this.alertType,
    this.from,
    this.to,
  });

  /// Creates a copy with updated fields.
  ///
  /// Use the `clear*` flags to explicitly set a field to null.
  AlertsFilter copyWith({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    AlertType? alertType,
    DateTime? from,
    DateTime? to,
    bool clearSensorId = false,
    bool clearDeviceId = false,
    bool clearMetric = false,
    bool clearAlertType = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) =>
      AlertsFilter(
        sensorId: clearSensorId ? null : (sensorId ?? this.sensorId),
        deviceId: clearDeviceId ? null : (deviceId ?? this.deviceId),
        metric: clearMetric ? null : (metric ?? this.metric),
        alertType: clearAlertType ? null : (alertType ?? this.alertType),
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
      );

  /// Converts non-null filter values to a query parameters map.
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (sensorId != null) params['sensor_id'] = sensorId!;
    if (deviceId != null) params['device_id'] = deviceId!;
    if (metric != null) params['metric'] = metric!.toBackendString();
    if (alertType != null) params['alert_type'] = alertType!.toBackendString();
    if (from != null) params['from'] = from!.toIso8601String();
    if (to != null) params['to'] = to!.toIso8601String();
    return params;
  }
}
