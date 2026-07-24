import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/datasources/sensor/sensor_remote_datasource.dart';
import '../../../infrastructure/datasources/sensor/sensor_remote_datasource_fake.dart';

/// Provee el [SensorRemoteDataSource] concreto que se usará en toda la app.
///
/// Usa [FutureProvider] porque [SensorRemoteDataSourceFake.fromAsset] carga
/// datos desde un asset de forma asíncrona. Para cambiar al datasource real,
/// reemplaza el cuerpo de este provider — nada más cambia.
final sensorRemoteDataSourceProvider =
    FutureProvider<SensorRemoteDataSource>((ref) async {
  return SensorRemoteDataSourceFake.fromAsset();
});
