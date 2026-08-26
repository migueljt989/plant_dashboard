import '../../../domain/entities/alert_type.dart';
import '../../../domain/entities/metric_type.dart';
import '../../models/alert_dto.dart';
import '../../models/paginated_response.dart';

/// Contrato abstracto del datasource remoto de alertas.
///
/// Define las operaciones de lectura contra el endpoint `/alerts` del backend.
abstract class AlertsRemoteDataSource {
  /// Obtiene alertas paginadas con filtros opcionales.
  ///
  /// [sensorId] - Filtra por ID del sensor.
  /// [deviceId] - Filtra por ID del dispositivo.
  /// [metric] - Filtra por tipo de métrica.
  /// [alertType] - Filtra por tipo de alerta (breach/recovery).
  /// [from] - Fecha inicio del rango temporal.
  /// [to] - Fecha fin del rango temporal.
  /// [limit] - Cantidad máxima de items por página.
  /// [offset] - Desplazamiento para paginación.
  Future<PaginatedResponse<AlertDto>> fetchAlerts({
    String? sensorId,
    String? deviceId,
    MetricType? metric,
    AlertType? alertType,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  });
}
