import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/batch_delete_result.dart';
import 'camera_providers.dart';
import 'photo_gallery_filter.dart';
import 'photo_gallery_state.dart';

/// Controlador de la galería de fotos.
///
/// Expone el estado paginado de la galería ([PhotoGalleryState]) como
/// [AsyncValue] y las operaciones que la UI puede disparar: aplicar filtros,
/// cargar más fotos, capturar bajo demanda, eliminar (individual o en lote) y
/// gestionar el modo de selección múltiple.
final photoGalleryControllerProvider =
    AsyncNotifierProvider<PhotoGalleryController, PhotoGalleryState>(
        () => PhotoGalleryController());

class PhotoGalleryController extends AsyncNotifier<PhotoGalleryState> {
  /// Tiempo máximo de espera para una captura bajo demanda.
  static const _captureTimeout = Duration(seconds: 30);

  @override
  Future<PhotoGalleryState> build() async {
    const filter = PhotoGalleryFilter();
    final response = await ref.read(cameraRepositoryProvider).getPhotos(
          limit: 20,
          offset: 0,
        );
    return PhotoGalleryState(
      items: response.items,
      total: response.total,
      limit: response.limit,
      offset: response.offset,
      filter: filter,
    );
  }

  /// Reinicia la paginación (offset 0) y recarga las fotos aplicando el nuevo
  /// [filter]. Requirement 11.3.
  Future<void> applyFilters(PhotoGalleryFilter filter) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await ref.read(cameraRepositoryProvider).getPhotos(
            deviceId: filter.deviceId,
            from: filter.from,
            to: filter.to,
            limit: 20,
            offset: 0,
          );
      return PhotoGalleryState(
        items: response.items,
        total: response.total,
        limit: response.limit,
        offset: 0,
        filter: filter,
      );
    });
  }

  /// Obtiene el siguiente lote de fotos y lo agrega al final de la lista
  /// acumulada, avanzando el offset. Solo actúa si [PhotoGalleryState.hasMore]
  /// es `true`. Requirement 11.3.
  ///
  /// El nuevo estado cumple: `items == [...previos, ...nuevos]` y
  /// `offset == offset_previo + items_previos.length` (Property 9).
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    final nextOffset = currentState.offset + currentState.items.length;
    final filter = currentState.filter;
    state = await AsyncValue.guard(() async {
      final response = await ref.read(cameraRepositoryProvider).getPhotos(
            deviceId: filter.deviceId,
            from: filter.from,
            to: filter.to,
            limit: currentState.limit,
            offset: nextOffset,
          );
      return currentState.copyWith(
        items: [...currentState.items, ...response.items],
        total: response.total,
        offset: nextOffset,
        isLoadingMore: false,
      );
    });
  }

  /// Dispara una captura bajo demanda en el dispositivo [deviceId] con un
  /// timeout de 30 segundos. Al tener éxito, antepone la foto capturada y
  /// recarga la galería para reflejar el cambio. Requirements 7.3, 7.5, 11.4.
  ///
  /// Si la captura excede el timeout, se propaga el error para que la UI
  /// muestre una notificación de tiempo agotado.
  Future<void> capturePhoto(String deviceId) async {
    final photo = await ref
        .read(cameraRepositoryProvider)
        .capturePhoto(deviceId)
        .timeout(_captureTimeout);

    // Anteponer optimísticamente la foto recién capturada para feedback
    // inmediato en la UI.
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        items: [photo, ...currentState.items],
        total: currentState.total + 1,
      ));
    }

    // Invalidar y recargar el estado de la galería desde el repositorio
    // para que la UI quede consistente con el backend. Requirement 11.4.
    ref.invalidateSelf();
  }

  /// Elimina la foto [photoId] y recarga la galería. Requirement 8.3, 11.4.
  Future<void> deletePhoto(String photoId) async {
    await ref.read(cameraRepositoryProvider).deletePhoto(photoId);
    ref.invalidateSelf();
  }

  /// Elimina en lote las fotos [photoIds] y recarga la galería. Devuelve el
  /// [BatchDeleteResult] para que la UI reporte la cantidad eliminada y los
  /// IDs no encontrados. Requirements 9.7, 9.8, 11.4.
  Future<BatchDeleteResult> deletePhotos(List<String> photoIds) async {
    final result =
        await ref.read(cameraRepositoryProvider).deletePhotos(photoIds);
    ref.invalidateSelf();
    return result;
  }

  /// Alterna la selección de la foto [photoId] en el modo de selección
  /// múltiple. Requirement 9.x (modo selección).
  void toggleSelection(String photoId) {
    final currentState = state.value;
    if (currentState == null) return;

    final selected = Set<String>.from(currentState.selectedIds);
    if (selected.contains(photoId)) {
      selected.remove(photoId);
    } else {
      selected.add(photoId);
    }
    state = AsyncValue.data(currentState.copyWith(selectedIds: selected));
  }

  /// Entra al modo de selección múltiple. Requirement 9.1.
  void enterSelectionMode() {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncValue.data(currentState.copyWith(isSelectionMode: true));
  }

  /// Sale del modo de selección múltiple y limpia la selección actual.
  /// Requirement 9.1.
  void exitSelectionMode() {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncValue.data(currentState.copyWith(
      isSelectionMode: false,
      selectedIds: const {},
    ));
  }
}
