/// Modelo de filtro inmutable para la galería de fotos.
///
/// Todos los campos son opcionales — solo los valores no nulos se incluyen
/// al construir los parámetros de consulta hacia el backend.
class PhotoGalleryFilter {
  /// Filtra por dispositivo de cámara específico. `null` significa
  /// "todas las cámaras".
  final String? deviceId;

  /// Inicio del rango temporal (inclusive). `null` significa sin límite
  /// inferior.
  final DateTime? from;

  /// Fin del rango temporal (inclusive). `null` significa sin límite
  /// superior.
  final DateTime? to;

  const PhotoGalleryFilter({
    this.deviceId,
    this.from,
    this.to,
  });
}
