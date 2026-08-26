import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:plant_dashboard/domain/entities/alert_type.dart';
import 'package:plant_dashboard/domain/entities/breached_bound.dart';
import 'package:plant_dashboard/domain/entities/delivery_status.dart';

/// **Validates: Requirements 3.1, 3.2, 3.3**
void main() {
  Glados<int>().test(
    'Feature: readings-and-alerts, Property 3: AlertType round-trip',
    (seed) {
      final value = AlertType.values[seed.abs() % AlertType.values.length];
      final backendString = value.toBackendString();
      final restored = AlertType.fromString(backendString);
      expect(restored, equals(value));
    },
  );

  Glados<int>().test(
    'Feature: readings-and-alerts, Property 3: BreachedBound round-trip',
    (seed) {
      final value =
          BreachedBound.values[seed.abs() % BreachedBound.values.length];
      final backendString = value.toBackendString();
      final restored = BreachedBound.fromString(backendString);
      expect(restored, equals(value));
    },
  );

  Glados<int>().test(
    'Feature: readings-and-alerts, Property 3: DeliveryStatus round-trip',
    (seed) {
      final value =
          DeliveryStatus.values[seed.abs() % DeliveryStatus.values.length];
      final backendString = value.toBackendString();
      final restored = DeliveryStatus.fromString(backendString);
      expect(restored, equals(value));
    },
  );
}
