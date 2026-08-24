import 'package:flutter_test/flutter_test.dart';
import 'package:plant_dashboard/domain/entities/metric_type.dart';

void main() {
  group('MetricType', () {
    test('has exactly four values', () {
      expect(MetricType.values.length, 4);
    });

    test('contains soilMoisture, airHumidity, temperature, and uvIndex', () {
      expect(MetricType.values, contains(MetricType.soilMoisture));
      expect(MetricType.values, contains(MetricType.airHumidity));
      expect(MetricType.values, contains(MetricType.temperature));
      expect(MetricType.values, contains(MetricType.uvIndex));
    });
  });

  group('MetricType.fromString', () {
    test('maps "soil_moisture" to MetricType.soilMoisture', () {
      expect(MetricType.fromString('soil_moisture'), MetricType.soilMoisture);
    });

    test('maps "air_humidity" to MetricType.airHumidity', () {
      expect(MetricType.fromString('air_humidity'), MetricType.airHumidity);
    });

    test('maps "temperature" to MetricType.temperature', () {
      expect(MetricType.fromString('temperature'), MetricType.temperature);
    });

    test('maps "uv_index" to MetricType.uvIndex', () {
      expect(MetricType.fromString('uv_index'), MetricType.uvIndex);
    });

    test('defaults to MetricType.temperature on unknown value', () {
      expect(MetricType.fromString('unknown'), MetricType.temperature);
    });

    test('defaults to MetricType.temperature on empty string', () {
      expect(MetricType.fromString(''), MetricType.temperature);
    });
  });

  group('MetricType.toBackendString', () {
    test('soilMoisture returns "soil_moisture"', () {
      expect(MetricType.soilMoisture.toBackendString(), 'soil_moisture');
    });

    test('airHumidity returns "air_humidity"', () {
      expect(MetricType.airHumidity.toBackendString(), 'air_humidity');
    });

    test('temperature returns "temperature"', () {
      expect(MetricType.temperature.toBackendString(), 'temperature');
    });

    test('uvIndex returns "uv_index"', () {
      expect(MetricType.uvIndex.toBackendString(), 'uv_index');
    });
  });

  group('MetricType.label', () {
    test('soilMoisture returns "Humedad de suelo"', () {
      expect(MetricType.soilMoisture.label, 'Humedad de suelo');
    });

    test('airHumidity returns "Humedad ambiental"', () {
      expect(MetricType.airHumidity.label, 'Humedad ambiental');
    });

    test('temperature returns "Temperatura"', () {
      expect(MetricType.temperature.label, 'Temperatura');
    });

    test('uvIndex returns "Índice UV"', () {
      expect(MetricType.uvIndex.label, 'Índice UV');
    });
  });
}
