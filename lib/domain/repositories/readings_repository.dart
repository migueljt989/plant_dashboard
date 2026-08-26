import '../entities/metric_type.dart';
import '../entities/reading.dart';
import '../../infrastructure/models/paginated_response.dart';

/// Contrato del repositorio de lecturas históricas.
///
/// Separado del [SensorRepository] existente (que sirve para streaming
/// en tiempo real del dashboard). Este repositorio consume endpoints REST
/// paginados.
abstract class ReadingsRepository {
  /// Obtiene lecturas paginadas con filtros opcionales.
  ///
  /// Parámetros de filtro (todos opcionales):
  /// - [sensorId]: filtra por sensor específico.
  /// - [deviceId]: filtra por dispositivo específico.
  /// - [metric]: filtra por tipo de métrica.
  /// - [from]: inicio del rango temporal (inclusive).
  /// - [to]: fin del rango temporal (inclusive).
  ///
  /// Parámetros de paginación:
  /// - [limit]: cantidad máxima de items por página (default 50).
  /// - [offset]: desplazamiento desde el inicio (default 0).
  Future<PaginatedResponse<Reading>> getReadings({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  });

  /// Obtiene la lectura más reciente que coincida con los filtros.
  ///
  /// Parámetros de filtro (todos opcionales):
  /// - [sensorId]: filtra por sensor específico.
  /// - [deviceId]: filtra por dispositivo específico.
  /// - [metric]: filtra por tipo de métrica.
  Future<Reading> getLatestReading({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
  });
}
