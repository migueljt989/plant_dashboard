import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/alert_threshold.dart';
import '../../../domain/entities/sensor_reading.dart';
import '../../../domain/repositories/sensor_repository.dart';
import '../../../infrastructure/repositories/sensor_repository_impl.dart';
import 'sensor_datasource_provider.dart';

/// Provee el [SensorRepository] conectado al datasource configurado.
///
/// Es un [FutureProvider] porque depende de [sensorRemoteDataSourceProvider],
/// que carga datos de forma asíncrona.
final sensorRepositoryProvider = FutureProvider<SensorRepository>((ref) async {
  final dataSource = await ref.watch(sensorRemoteDataSourceProvider.future);
  return SensorRepositoryImpl(dataSource);
});

/// Stream en tiempo real de la última lectura del dispositivo [deviceId].
///
/// Se autodescarta cuando ya no hay listeners. Entra en estado `loading`
/// mientras el repositorio se está inicializando.
final latestReadingProvider =
    StreamProvider.autoDispose.family<SensorReading, String>((ref, deviceId) async* {
  final repository = await ref.watch(sensorRepositoryProvider.future);
  yield* repository.watchLatestReading(deviceId);
});

/// Histórico de lecturas del dispositivo [params.deviceId] en [params.range].
///
/// Se autodescarta cuando ya no hay listeners. Devuelve lista vacía si no hay
/// datos en el rango seleccionado.
final sensorHistoryProvider = FutureProvider.autoDispose
    .family<List<SensorReading>, ({String deviceId, DateTimeRange range})>(
        (ref, params) async {
  final repository = await ref.watch(sensorRepositoryProvider.future);
  return repository.getHistory(params.deviceId, params.range);
});

/// Notifier que guarda el rango de fechas seleccionado para el histórico.
///
/// El valor por defecto cubre el rango del JSON fake (2025-01-15 a 2025-01-18)
/// para que el selector muestre datos al abrir el panel por primera vez.
class SelectedDateRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() {
    return DateTimeRange(
      start: DateTime.utc(2025, 1, 15),
      end: DateTime.utc(2025, 1, 18, 23, 59, 59),
    );
  }

  void setRange(DateTimeRange range) {
    state = range;
  }
}

final selectedDateRangeProvider =
    NotifierProvider.autoDispose<SelectedDateRangeNotifier, DateTimeRange>(
  SelectedDateRangeNotifier.new,
);

/// Umbrales de alerta hardcodeados para el MVP.
///
/// Temperatura saludable para jitomate cherry: 15 °C – 35 °C.
/// Humedad de suelo saludable: 30 % – 80 %.
///
/// Para cambiarlos durante el MVP, modifica únicamente este provider.
/// No hay UI de configuración en el MVP.
final alertThresholdProvider =
    Provider<({AlertThreshold temperature, AlertThreshold soilMoisture})>((ref) {
  return (
    temperature: const AlertThreshold(min: 15.0, max: 35.0),
    soilMoisture: const AlertThreshold(min: 30.0, max: 80.0),
  );
});
