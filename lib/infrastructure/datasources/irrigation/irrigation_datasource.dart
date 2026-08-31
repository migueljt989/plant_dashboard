import '../../models/irrigation_command_response_dto.dart';
import '../../models/irrigation_session_dto.dart';
import '../../models/irrigation_status_dto.dart';
import '../../models/paginated_response.dart';

/// Contrato abstracto del datasource de riego.
///
/// Habla en términos de datos crudos del proveedor (DTOs), no de entidades de
/// dominio. Comunica con los endpoints `/irrigation` del backend. La
/// implementación concreta (por ejemplo [IrrigationDataSourceBackend]) se
/// encarga de la comunicación real con el backend.
abstract class IrrigationDataSource {
  /// Inicia el riego en el dispositivo indicado.
  ///
  /// Envía un comando de inicio y devuelve la respuesta del backend como
  /// [IrrigationCommandResponseDto].
  Future<IrrigationCommandResponseDto> startIrrigation(String deviceId);

  /// Detiene el riego en el dispositivo indicado.
  ///
  /// Envía un comando de paro y devuelve la respuesta del backend como
  /// [IrrigationCommandResponseDto].
  Future<IrrigationCommandResponseDto> stopIrrigation(String deviceId);

  /// Obtiene el estado actual del dispositivo de irrigación.
  Future<IrrigationStatusDto> fetchStatus(String deviceId);

  /// Obtiene el historial paginado de sesiones de riego del dispositivo.
  ///
  /// [limit] - cantidad máxima de resultados por página.
  /// [offset] - desplazamiento para paginación.
  Future<PaginatedResponse<IrrigationSessionDto>> fetchHistory(
    String deviceId, {
    required int limit,
    required int offset,
  });
}
