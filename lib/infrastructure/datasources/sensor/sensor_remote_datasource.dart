import 'package:flutter/material.dart';

import '../../models/sensor_reading_dto.dart';

/// Contrato abstracto del DataSource de sensores.
/// Las implementaciones concretas (Fake, REST, etc.) deben extender esta clase.
abstract class SensorRemoteDataSource {
  /// Devuelve la lectura más reciente para [deviceId].
  /// Lanza [NotFoundFailure] si no hay datos para ese dispositivo.
  Future<SensorReadingDto> fetchLatest(String deviceId);

  /// Stream continuo que emite la lectura más reciente de [deviceId] periódicamente.
  Stream<SensorReadingDto> streamLatest(String deviceId);

  /// Devuelve todas las lecturas de [deviceId] cuyo [recordedAt] está dentro de [range].
  /// El rango es inclusivo en ambos extremos (start <= recordedAt <= end).
  Future<List<SensorReadingDto>> fetchHistory(
    String deviceId,
    DateTimeRange range,
  );
}
