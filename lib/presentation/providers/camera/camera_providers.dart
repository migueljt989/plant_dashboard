import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_type.dart';
import '../../../domain/repositories/camera_repository.dart';
import '../../../infrastructure/datasources/camera/camera_datasource.dart';
import '../../../infrastructure/datasources/camera/camera_datasource_backend.dart';
import '../../../infrastructure/network/dio_provider.dart';
import '../../../infrastructure/repositories/camera_repository_impl.dart';
import '../device/device_providers.dart';

/// Provee la implementación de [CameraDataSource] contra el backend REST,
/// usando la instancia de Dio autenticada compartida.
final cameraDataSourceProvider = Provider<CameraDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return CameraDataSourceBackend(dio);
});

/// Provee la implementación de [CameraRepository] que delega en el datasource
/// de cámara. Único punto donde se decide la implementación concreta.
final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  return CameraRepositoryImpl(ref.watch(cameraDataSourceProvider));
});

/// Deriva la lista de dispositivos de tipo cámara a partir del controlador de
/// dispositivos existente, preservando el orden original.
///
/// Se usa en los controles de selección de dispositivo y en la navegación al
/// stream en vivo. Mientras la lista de dispositivos aún no cargó (o falló),
/// devuelve una lista vacía.
final cameraDevicesProvider = Provider<List<Device>>((ref) {
  final devicesAsync = ref.watch(devicesControllerProvider);
  return devicesAsync.value
          ?.where((d) => d.type == DeviceType.camera)
          .toList() ??
      [];
});
