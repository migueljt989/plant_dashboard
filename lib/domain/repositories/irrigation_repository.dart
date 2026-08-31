import '../entities/irrigation_command_response.dart';
import '../entities/irrigation_session.dart';
import '../entities/irrigation_status.dart';
import '../../infrastructure/models/paginated_response.dart';

/// Contrato del repositorio de control de riego.
///
/// Expone operaciones en términos de entidades de dominio. La implementación
/// concreta ([IrrigationRepositoryImpl]) delega en un `IrrigationDataSource`
/// y mapea los DTOs a entidades.
abstract class IrrigationRepository {
  /// Inicia el riego para el dispositivo indicado.
  Future<IrrigationCommandResponse> startIrrigation(String deviceId);

  /// Detiene el riego para el dispositivo indicado.
  Future<IrrigationCommandResponse> stopIrrigation(String deviceId);

  /// Obtiene el estado actual del dispositivo de irrigación.
  Future<IrrigationStatus> getStatus(String deviceId);

  /// Obtiene el historial paginado de sesiones de riego.
  ///
  /// - [limit]: cantidad máxima de items por página (default 20, rango 1–100).
  /// - [offset]: desplazamiento desde el inicio (default 0).
  Future<PaginatedResponse<IrrigationSession>> getHistory(
    String deviceId, {
    int limit = 20,
    int offset = 0,
  });
}
