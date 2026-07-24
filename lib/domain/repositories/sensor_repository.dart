import 'package:flutter/material.dart';

import '../entities/sensor_reading.dart';

abstract class SensorRepository {
  /// Última lectura disponible (consulta puntual).
  Future<SensorReading> getLatestReading(String deviceId);

  /// Stream continuo de lecturas en tiempo real.
  Stream<SensorReading> watchLatestReading(String deviceId);

  /// Histórico en un rango de fechas.
  Future<List<SensorReading>> getHistory(String deviceId, DateTimeRange range);
}
