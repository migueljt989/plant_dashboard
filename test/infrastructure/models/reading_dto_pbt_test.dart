import 'package:glados/glados.dart';
import 'package:plant_dashboard/infrastructure/models/reading_dto.dart';

/// **Validates: Requirements 1.2, 1.3, 1.4**

final _metrics = ['soil_moisture', 'air_humidity', 'temperature', 'uv_index'];
final _units = ['°C', '%', 'lux', 'µmol/m²/s'];

extension ReadingDtoAny on Any {
  Generator<ReadingDto> get readingDto => combine8(
        any.nonEmptyLetterOrDigits, // id
        any.nonEmptyLetterOrDigits, // sensorId
        any.nonEmptyLetterOrDigits, // sensorName
        any.nonEmptyLetterOrDigits, // deviceId
        any.choose(_metrics), // metric
        any.choose(_units), // unit
        any.doubleInRange(-100.0, 100.0), // value
        any.positiveIntOrZero, // seed for recordedAt
        (id, sensorId, sensorName, deviceId, metric, unit, value, seed) =>
            ReadingDto(
          id: id,
          sensorId: sensorId,
          sensorName: sensorName,
          deviceId: deviceId,
          metric: metric,
          unit: unit,
          value: value,
          recordedAt: DateTime(
            2020 + (seed % 5),
            1 + (seed % 12),
            1 + (seed % 28),
            seed % 24,
            seed % 60,
          ).toIso8601String(),
        ),
      );
}

void main() {
  Glados(any.readingDto, ExploreConfig(numRuns: 100)).test(
    'Feature: readings-and-alerts, Property 1: ReadingDto round-trip serialization',
    (dto) {
      final json1 = dto.toJson();
      final restored = ReadingDto.fromJson(json1);
      final json2 = restored.toJson();

      expect(json2, equals(json1));
    },
  );
}
