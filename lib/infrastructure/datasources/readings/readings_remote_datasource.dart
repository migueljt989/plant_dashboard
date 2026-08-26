import '../../../domain/entities/metric_type.dart';
import '../../models/paginated_response.dart';
import '../../models/reading_dto.dart';

/// Contrato abstracto del datasource de lecturas.
/// Comunica con los endpoints `/readings` y `/readings/latest` del backend.
abstract class ReadingsRemoteDataSource {
  /// Obtiene lecturas paginadas con filtros opcionales.
  ///
  /// [sensorId] - filtrar por sensor específico.
  /// [deviceId] - filtrar por dispositivo específico.
  /// [metric] - filtrar por tipo de métrica.
  /// [from] - fecha de inicio del rango.
  /// [to] - fecha de fin del rango.
  /// [limit] - cantidad máxima de resultados por página.
  /// [offset] - desplazamiento para paginación.
  Future<PaginatedResponse<ReadingDto>> fetchReadings({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  });

  /// Obtiene la lectura más reciente con filtros opcionales.
  ///
  /// [sensorId] - filtrar por sensor específico.
  /// [deviceId] - filtrar por dispositivo específico.
  /// [metric] - filtrar por tipo de métrica.
  Future<ReadingDto> fetchLatestReading({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
  });
}
