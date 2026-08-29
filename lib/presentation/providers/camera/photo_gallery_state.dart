import 'package:plant_dashboard/domain/entities/photo.dart';
import 'package:plant_dashboard/presentation/providers/camera/photo_gallery_filter.dart';

/// Modelo de estado del controlador de la galería de fotos.
///
/// Contiene la lista acumulada de fotos, los metadatos de paginación, el
/// filtro activo, una bandera de carga para operaciones de "cargar más" y el
/// estado del modo de selección múltiple.
class PhotoGalleryState {
  /// Fotos actualmente acumuladas en la galería.
  final List<Photo> items;

  /// Total de fotos disponibles en el backend para el filtro actual.
  final int total;

  /// Cantidad de items por página.
  final int limit;

  /// Desplazamiento desde el inicio de la lista.
  final int offset;

  /// Filtro activo aplicado a la galería.
  final PhotoGalleryFilter filter;

  /// Indica si hay una operación de "cargar más" en curso.
  final bool isLoadingMore;

  /// IDs de las fotos seleccionadas en modo de selección múltiple.
  final Set<String> selectedIds;

  /// Indica si el modo de selección múltiple está activo.
  final bool isSelectionMode;

  const PhotoGalleryState({
    this.items = const [],
    this.total = 0,
    this.limit = 20,
    this.offset = 0,
    this.filter = const PhotoGalleryFilter(),
    this.isLoadingMore = false,
    this.selectedIds = const {},
    this.isSelectionMode = false,
  });

  /// Indica si hay más items por obtener más allá de la página actual.
  bool get hasMore => offset + items.length < total;

  /// Crea una copia de este estado reemplazando los campos indicados.
  PhotoGalleryState copyWith({
    List<Photo>? items,
    int? total,
    int? limit,
    int? offset,
    PhotoGalleryFilter? filter,
    bool? isLoadingMore,
    Set<String>? selectedIds,
    bool? isSelectionMode,
  }) =>
      PhotoGalleryState(
        items: items ?? this.items,
        total: total ?? this.total,
        limit: limit ?? this.limit,
        offset: offset ?? this.offset,
        filter: filter ?? this.filter,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        selectedIds: selectedIds ?? this.selectedIds,
        isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      );
}
