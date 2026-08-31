import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_type.dart';
import '../../../domain/repositories/irrigation_repository.dart';
import '../../../infrastructure/datasources/irrigation/irrigation_datasource.dart';
import '../../../infrastructure/datasources/irrigation/irrigation_datasource_backend.dart';
import '../../../infrastructure/network/dio_provider.dart';
import '../../../infrastructure/repositories/irrigation_repository_impl.dart';
import '../device/device_providers.dart';
import 'irrigation_controller.dart';
import 'irrigation_state.dart';

/// Provee la implementación de [IrrigationDataSource] contra el backend REST,
/// usando la instancia de Dio autenticada compartida.
final irrigationDataSourceProvider = Provider<IrrigationDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return IrrigationDataSourceBackend(dio);
});

/// Provee la implementación de [IrrigationRepository] que delega en el
/// datasource de riego. Único punto donde se decide la implementación concreta.
final irrigationRepositoryProvider = Provider<IrrigationRepository>((ref) {
  return IrrigationRepositoryImpl(ref.watch(irrigationDataSourceProvider));
});

/// Expone el primer dispositivo cuyo tipo es [DeviceType.irrigation], o null si
/// no existe ningún dispositivo de riego registrado.
///
/// Deriva la selección del controlador de dispositivos existente. Mientras la
/// lista de dispositivos aún no cargó (o falló), devuelve null.
final irrigationDeviceProvider = Provider<Device?>((ref) {
  final devicesAsync = ref.watch(devicesControllerProvider);
  final devices = devicesAsync.value;
  if (devices == null) return null;
  for (final device in devices) {
    if (device.type == DeviceType.irrigation) return device;
  }
  return null;
});

/// Controlador del feature de riego. Es `autoDispose` para cancelar el polling
/// y limpiar el estado al salir de la página.
final irrigationControllerProvider =
    AsyncNotifierProvider.autoDispose<IrrigationController, IrrigationState>(
  () => IrrigationController(),
);
