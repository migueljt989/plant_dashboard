import '../../domain/entities/batch_delete_result.dart';

/// DTO para el resultado de una eliminación en lote de fotos.
///
/// Realiza serialización manual (sin codegen) mapeando las claves snake_case
/// del backend (`deleted_count`, `not_found_ids`) a los campos camelCase del
/// dominio, y expone [toEntity] para convertir a la entidad de dominio.
class BatchDeleteResultDto {
  final int deletedCount;
  final List<String> notFoundIds;

  const BatchDeleteResultDto({
    required this.deletedCount,
    required this.notFoundIds,
  });

  /// Construye un [BatchDeleteResultDto] a partir de un mapa JSON.
  ///
  /// Valida explícitamente los tipos antes de castear y lanza una
  /// [FormatException] con un mensaje descriptivo si:
  /// - falta `deleted_count` o no es un entero,
  /// - falta `not_found_ids` o no es una lista,
  /// - algún elemento de `not_found_ids` no es un String.
  factory BatchDeleteResultDto.fromJson(Map<String, dynamic> json) {
    final rawDeletedCount = json['deleted_count'];
    if (rawDeletedCount is! int) {
      throw FormatException(
        rawDeletedCount == null
            ? "Campo requerido 'deleted_count' ausente"
            : "Campo 'deleted_count' debe ser un entero, "
                'se recibió ${rawDeletedCount.runtimeType}',
      );
    }

    final rawNotFoundIds = json['not_found_ids'];
    if (rawNotFoundIds is! List) {
      throw FormatException(
        rawNotFoundIds == null
            ? "Campo requerido 'not_found_ids' ausente"
            : "Campo 'not_found_ids' debe ser una lista, "
                'se recibió ${rawNotFoundIds.runtimeType}',
      );
    }

    final notFoundIds = <String>[];
    for (var i = 0; i < rawNotFoundIds.length; i++) {
      final element = rawNotFoundIds[i];
      if (element is! String) {
        throw FormatException(
          "Elemento en 'not_found_ids' en el índice $i debe ser un String, "
          'se recibió ${element.runtimeType}',
        );
      }
      notFoundIds.add(element);
    }

    return BatchDeleteResultDto(
      deletedCount: rawDeletedCount,
      notFoundIds: notFoundIds,
    );
  }

  /// Convierte este DTO en la entidad de dominio [BatchDeleteResult],
  /// preservando todos los valores.
  BatchDeleteResult toEntity() => BatchDeleteResult(
        deletedCount: deletedCount,
        notFoundIds: notFoundIds,
      );
}
