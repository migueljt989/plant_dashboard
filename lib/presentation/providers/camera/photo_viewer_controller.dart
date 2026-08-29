import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/photo.dart';
import 'camera_providers.dart';
import 'photo_gallery_controller.dart';

/// Controlador del visor de una foto individual.
///
/// Es una familia parametrizada por el ID de la foto y `autoDispose`, de modo
/// que el estado se limpia al salir de la página del visor. Expone los
/// metadatos de la foto como [AsyncValue] y permite eliminarla.
final photoViewerControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PhotoViewerController, Photo, String>(
  PhotoViewerController.new,
);

class PhotoViewerController extends AsyncNotifier<Photo> {
  /// Crea el controlador para la foto identificada por [photoId] (argumento
  /// de la familia).
  PhotoViewerController(this.photoId);

  /// ID de la foto que este controlador gestiona.
  final String photoId;

  /// Obtiene los metadatos de la foto. Requirement 11.5.
  @override
  Future<Photo> build() async {
    return ref.read(cameraRepositoryProvider).getPhotoMetadata(photoId);
  }

  /// Elimina la foto actualmente mostrada. Devuelve `true` si la eliminación
  /// tuvo éxito para que la UI pueda navegar de vuelta a la galería, o `false`
  /// si falló. Requirement 11.6.
  ///
  /// Ante un fallo, el motivo queda expuesto en el [state] como
  /// [AsyncValue.error] (mismo patrón que `loginController`), de modo que la
  /// UI pueda mostrar el mensaje sin que el error se pierda. Requirement 8.5.
  /// Solo invalida la galería cuando el borrado tuvo éxito.
  Future<bool> deletePhoto() async {
    final photo = state.value;
    state = const AsyncValue<Photo>.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(cameraRepositoryProvider).deletePhoto(photoId);
      ref.invalidate(photoGalleryControllerProvider);
      // Conserva los metadatos de la foto en el estado tras el borrado, para
      // que la UI pueda seguir mostrándolos mientras navega de vuelta.
      return photo!;
    });
    return !state.hasError;
  }
}
