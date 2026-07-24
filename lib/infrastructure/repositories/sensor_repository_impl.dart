import 'package:flutter/material.dart';
import '../../domain/entities/sensor_reading.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../datasources/sensor/sensor_remote_datasource.dart';

class SensorRepositoryImpl implements SensorRepository {
  final SensorRemoteDataSource _dataSource;
  SensorRepositoryImpl(this._dataSource);

  @override
  Future<SensorReading> getLatestReading(String deviceId) async {
    final dto = await _dataSource.fetchLatest(deviceId);
    return dto.toEntity();
  }

  @override
  Stream<SensorReading> watchLatestReading(String deviceId) =>
      _dataSource.streamLatest(deviceId).map((dto) => dto.toEntity());

  @override
  Future<List<SensorReading>> getHistory(
    String deviceId,
    DateTimeRange range,
  ) async {
    final dtos = await _dataSource.fetchHistory(deviceId, range);
    return dtos.map((dto) => dto.toEntity()).toList();
  }
}
