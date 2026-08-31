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

/// Expone el primer dispositivo cuyo tipo es [DeviceType.irrigation], o `null`
/// si la lista cargó correctamente pero no hay ninguno registrado.
///
/// Es un [FutureProvider] (y no un `Provider` síncrono) a propósito: así se
/// distinguen tres situaciones que antes se colapsaban todas en `null`:
/// - lista aún cargando  → este provider sigue en `loading`
/// - lista falló (red/401) → el error se propaga tal cual
/// - lista OK sin riego   → devuelve `null`
///
/// Colapsarlas hacía que un fallo de red o una carga en curso se mostraran en
/// la UI como "no hay dispositivo de riego registrado", que es engañoso.
final irrigationDeviceProvider = FutureProvider<Device?>((ref) async {
  final devices = await ref.watch(devicesControllerProvider.future);
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
