import 'package:flutter_test/flutter_test.dart';
import 'package:plant_dashboard/domain/entities/device_type.dart';

void main() {
  group('DeviceType', () {
    test('has exactly three values', () {
      expect(DeviceType.values.length, 3);
    });

    test('contains sensor, camera, and irrigation', () {
      expect(DeviceType.values, contains(DeviceType.sensor));
      expect(DeviceType.values, contains(DeviceType.camera));
      expect(DeviceType.values, contains(DeviceType.irrigation));
    });
  });

  group('DeviceType.fromString', () {
    test('maps "sensor" to DeviceType.sensor', () {
      expect(DeviceType.fromString('sensor'), DeviceType.sensor);
    });

    test('maps "camera" to DeviceType.camera', () {
      expect(DeviceType.fromString('camera'), DeviceType.camera);
    });

    test('maps "irrigation" to DeviceType.irrigation', () {
      expect(DeviceType.fromString('irrigation'), DeviceType.irrigation);
    });

    test('defaults to DeviceType.sensor on unknown value', () {
      expect(DeviceType.fromString('unknown'), DeviceType.sensor);
    });

    test('defaults to DeviceType.sensor on empty string', () {
      expect(DeviceType.fromString(''), DeviceType.sensor);
    });
  });
}
