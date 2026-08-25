import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/sensor.dart';
import 'sensor_management_providers.dart';

/// Agrupa los sensores por `deviceId`.
///
/// Devuelve un `Map<String, List<Sensor>>` donde la key es el deviceId
/// y el valor es la lista de sensores de ese dispositivo.
///
/// Se deriva de [sensorsControllerProvider] para no hacer una llamada extra
/// al backend — simplemente reorganiza los mismos datos.
final sensorsByDeviceProvider =
    Provider<AsyncValue<Map<String, List<Sensor>>>>((ref) {
  final sensorsAsync = ref.watch(sensorsControllerProvider);

  return sensorsAsync.whenData((sensors) {
    final grouped = <String, List<Sensor>>{};
    for (final sensor in sensors) {
      grouped.putIfAbsent(sensor.deviceId, () => []).add(sensor);
    }
    return grouped;
  });
});
