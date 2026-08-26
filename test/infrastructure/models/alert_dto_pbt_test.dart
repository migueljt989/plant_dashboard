import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:plant_dashboard/infrastructure/models/alert_dto.dart';

/// Feature: readings-and-alerts, Property 2: AlertDto round-trip serialization
/// Validates: Requirements 2.2, 2.3, 2.4
void main() {
  Glados<int>().test(
    'Feature: readings-and-alerts, Property 2: AlertDto round-trip serialization',
    (seed) {
      final dto = _generateAlertDto(seed);
      final json1 = dto.toJson();
      final restored = AlertDto.fromJson(json1);
      final json2 = restored.toJson();
      expect(json2, equals(json1));
    },
  );
}

AlertDto _generateAlertDto(int seed) {
  final metrics = ['soil_moisture', 'air_humidity', 'temperature', 'uv_index'];
  final alertTypes = ['breach', 'recovery'];
  final breachedBounds = ['min_ok', 'max_ok'];
  final deliveryStatuses = ['pending', 'sent', 'failed', 'skipped'];

  final hasBreachedBound = seed % 3 != 0; // ~66% have breached bound

  return AlertDto(
    id: 'alert_$seed',
    sensorId: 'sensor_${seed.abs() % 20}',
    sensorName: 'Sensor ${seed.abs() % 10}',
    deviceId: 'device_${seed.abs() % 5}',
    metric: metrics[seed.abs() % metrics.length],
    unit: seed % 2 == 0 ? '°C' : '%',
    alertType: alertTypes[seed.abs() % alertTypes.length],
    value: (seed % 500) / 10.0,
    breachedBound:
        hasBreachedBound
            ? breachedBounds[seed.abs() % breachedBounds.length]
            : null,
    minOk: hasBreachedBound ? (seed.abs() % 50) / 10.0 : null,
    maxOk: hasBreachedBound ? (seed.abs() % 50 + 50) / 10.0 : null,
    triggeredAt:
        DateTime(
          2020 + seed.abs() % 5,
          1 + seed.abs() % 12,
          1 + seed.abs() % 28,
        ).toIso8601String(),
    deliveryStatus: deliveryStatuses[seed.abs() % deliveryStatuses.length],
  );
}
