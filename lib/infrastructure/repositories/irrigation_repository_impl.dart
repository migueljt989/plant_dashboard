import '../../domain/entities/irrigation_command_response.dart';
import '../../domain/entities/irrigation_session.dart';
import '../../domain/entities/irrigation_status.dart';
import '../../domain/repositories/irrigation_repository.dart';
import '../datasources/irrigation/irrigation_datasource.dart';
import '../models/paginated_response.dart';

/// Implementación de [IrrigationRepository].
///
/// Recibe un [IrrigationDataSource] por constructor y delega en él, mapeando
/// los DTOs a entidades de dominio vía `toEntity()`. Los fallos lanzados por el
/// datasource (NetworkFailure, NotFoundFailure, SessionExpiredFailure) se
/// propagan sin envolver ni transformar.
class IrrigationRepositoryImpl implements IrrigationRepository {
  final IrrigationDataSource _dataSource;
  IrrigationRepositoryImpl(this._dataSource);

  @override
  Future<IrrigationCommandResponse> startIrrigation(String deviceId) async {
    final dto = await _dataSource.startIrrigation(deviceId);
    return dto.toEntity();
  }

  @override
  Future<IrrigationCommandResponse> stopIrrigation(String deviceId) async {
    final dto = await _dataSource.stopIrrigation(deviceId);
    return dto.toEntity();
  }

  @override
  Future<IrrigationStatus> getStatus(String deviceId) async {
    final dto = await _dataSource.fetchStatus(deviceId);
    return dto.toEntity();
  }

  @override
  Future<PaginatedResponse<IrrigationSession>> getHistory(
    String deviceId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dataSource.fetchHistory(
      deviceId,
      limit: limit,
      offset: offset,
    );
    return PaginatedResponse<IrrigationSession>(
      items: response.items.map((dto) => dto.toEntity()).toList(),
      total: response.total,
      limit: response.limit,
      offset: response.offset,
    );
  }
}
