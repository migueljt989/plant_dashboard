import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/failures/app_failure.dart';
import '../../models/sensor_reading_dto.dart';
import 'sensor_remote_datasource.dart';

/// Implementación fake del [SensorRemoteDataSource].
///
/// Carga datos desde un JSON estático en memoria (assets/fake_sensor_data.json).
/// NO genera valores aleatorios: los datos fijos permiten pruebas deterministas.
/// El stream simula tiempo real emitiendo la lectura más reciente periódicamente.
///
/// El constructor recibe la lista ya parseada para que los tests puedan inyectar
/// datos directamente sin pasar por file I/O.
class SensorRemoteDataSourceFake implements SensorRemoteDataSource {
  /// Intervalo entre emisiones del stream en tiempo real.
  static const _streamInterval = Duration(seconds: 5);

  final List<SensorReadingDto> _data;

  const SensorRemoteDataSourceFake(this._data);

  /// Crea una instancia a partir de una cadena JSON (el contenido del asset).
  factory SensorRemoteDataSourceFake.fromJsonString(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    final data = list
        .map((e) => SensorReadingDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return SensorRemoteDataSourceFake(data);
  }

  /// Crea una instancia cargando el asset `assets/fake_sensor_data.json`.
  /// Usar este factory en el provider de Riverpod.
  static Future<SensorRemoteDataSourceFake> fromAsset() async {
    final json = await rootBundle.loadString('assets/fake_sensor_data.json');
    return SensorRemoteDataSourceFake.fromJsonString(json);
  }

  /// Devuelve la lectura más reciente de [deviceId] según [recordedAt].
  /// Lanza [NotFoundFailure] si no hay datos para ese dispositivo.
  @override
  Future<SensorReadingDto> fetchLatest(String deviceId) async {
    final readings = _readingsForDevice(deviceId);
    if (readings.isEmpty) {
      throw NotFoundFailure('No hay lecturas para el dispositivo "$deviceId".');
    }
    return readings.reduce(
      (a, b) =>
          DateTime.parse(a.recordedAt).isAfter(DateTime.parse(b.recordedAt))
              ? a
              : b,
    );
  }

  /// Emite la lectura más reciente de [deviceId] cada [_streamInterval].
  /// Lanza [NotFoundFailure] en la primera emisión si no hay datos.
  @override
  Stream<SensorReadingDto> streamLatest(String deviceId) async* {
    // Verificar que existen datos antes de empezar el stream.
    final latest = await fetchLatest(deviceId);
    yield latest;

    await for (final _ in Stream.periodic(_streamInterval)) {
      yield await fetchLatest(deviceId);
    }
  }

  /// Devuelve las lecturas de [deviceId] cuyo [recordedAt] está dentro de [range].
  ///
  /// El rango es **inclusivo en ambos extremos**:
  ///   `range.start <= recordedAt <= range.end`
  @override
  Future<List<SensorReadingDto>> fetchHistory(
    String deviceId,
    DateTimeRange range,
  ) async {
    final readings = _readingsForDevice(deviceId);
    return readings.where((dto) {
      final ts = DateTime.parse(dto.recordedAt);
      return !ts.isBefore(range.start) && !ts.isAfter(range.end);
    }).toList();
  }

  List<SensorReadingDto> _readingsForDevice(String deviceId) =>
      _data.where((dto) => dto.deviceId == deviceId).toList();
}
