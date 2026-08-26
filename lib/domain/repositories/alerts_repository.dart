import '../entities/alert.dart';
import '../entities/alert_type.dart';
import '../entities/metric_type.dart';
import '../../infrastructure/models/paginated_response.dart';

/// Contrato del repositorio de alertas.
///
/// Define cómo la capa de presentación obtiene alertas paginadas
/// sin conocer detalles de la implementación (HTTP, base de datos, etc.).
abstract class AlertsRepository {
  /// Obtiene alertas paginadas con filtros opcionales.
  ///
  /// [sensorId] - Filtra por sensor específico.
  /// [deviceId] - Filtra por dispositivo específico.
  /// [metric] - Filtra por tipo de métrica.
  /// [alertType] - Filtra por tipo de alerta (breach/recovery).
  /// [from] - Inicio del rango de fechas.
  /// [to] - Fin del rango de fechas.
  /// [limit] - Cantidad máxima de items por página.
  /// [offset] - Desplazamiento desde el inicio de resultados.
  Future<PaginatedResponse<Alert>> getAlerts({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    AlertType? alertType,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  });
}
