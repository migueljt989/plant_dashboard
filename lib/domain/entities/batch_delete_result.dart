/// Entidad de dominio que representa el resultado de una operación de
/// eliminación en lote de fotos.
///
/// Modelo puro de dominio: sin dependencias de Flutter, red ni JSON.
class BatchDeleteResult {
  /// Cantidad de fotos efectivamente eliminadas.
  final int deletedCount;

  /// Identificadores de fotos que no fueron encontradas durante la
  /// eliminación en lote.
  final List<String> notFoundIds;

  const BatchDeleteResult({
    required this.deletedCount,
    required this.notFoundIds,
  });
}
