import 'package:plant_dashboard/domain/entities/metric_type.dart';

/// Immutable filter model for the readings page.
///
/// All fields are optional — only non-null values are included in query params.
class ReadingsFilter {
  final String? sensorId;
  final String? deviceId;
  final MetricType? metric;
  final DateTime? from;
  final DateTime? to;

  const ReadingsFilter({
    this.sensorId,
    this.deviceId,
    this.metric,
    this.from,
    this.to,
  });

  /// Creates a copy with updated fields.
  ///
  /// Use the `clear*` flags to explicitly set a field to null.
  ReadingsFilter copyWith({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    DateTime? from,
    DateTime? to,
    bool clearSensorId = false,
    bool clearDeviceId = false,
    bool clearMetric = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) =>
      ReadingsFilter(
        sensorId: clearSensorId ? null : (sensorId ?? this.sensorId),
        deviceId: clearDeviceId ? null : (deviceId ?? this.deviceId),
        metric: clearMetric ? null : (metric ?? this.metric),
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
      );

  /// Converts non-null filter values to a query parameters map.
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (sensorId != null) params['sensor_id'] = sensorId!;
    if (deviceId != null) params['device_id'] = deviceId!;
    if (metric != null) params['metric'] = metric!.toBackendString();
    if (from != null) params['from'] = from!.toIso8601String();
    if (to != null) params['to'] = to!.toIso8601String();
    return params;
  }
}
