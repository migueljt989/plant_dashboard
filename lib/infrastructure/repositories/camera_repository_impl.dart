import '../../domain/entities/batch_delete_result.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/camera_repository.dart';
import '../datasources/camera/camera_datasource.dart';
import '../models/paginated_response.dart';

/// Implementación de [CameraRepository] que delega en un [CameraDataSource].
///
/// Sigue el patrón Repository/DataSource del proyecto: habla en términos de
/// entidades de dominio de cara a la presentación, mientras que el datasource
/// trabaja con DTOs. Esta clase se limita a delegar cada llamada y a mapear los
/// DTOs resultantes a entidades vía `toEntity()`. Las URLs se devuelven tal
/// cual (son Strings puros) y los [Failure] lanzados por el datasource se
/// propagan sin envolverse ni transformarse.
class CameraRepositoryImpl implements CameraRepository {
  final CameraDataSource _dataSource;

  CameraRepositoryImpl(this._dataSource);

  @override
  Future<PaginatedResponse<Photo>> getPhotos({
    String? deviceId,
    DateTime? from,
    DateTime? to,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dataSource.fetchPhotos(
      deviceId: deviceId,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
    return PaginatedResponse<Photo>(
      items: response.items.map((dto) => dto.toEntity()).toList(),
      total: response.total,
      limit: response.limit,
      offset: response.offset,
    );
  }

  @override
  Future<Photo> getPhotoMetadata(String photoId) async {
    final dto = await _dataSource.fetchPhotoMetadata(photoId);
    return dto.toEntity();
  }

  @override
  String getPhotoDownloadUrl(String photoId) {
    return _dataSource.getPhotoDownloadUrl(photoId);
  }

  @override
  Future<Photo> capturePhoto(String deviceId) async {
    final dto = await _dataSource.capturePhoto(deviceId);
    return dto.toEntity();
  }

  @override
  Future<void> deletePhoto(String photoId) {
    return _dataSource.deletePhoto(photoId);
  }

  @override
  Future<BatchDeleteResult> deletePhotos(List<String> photoIds) async {
    final dto = await _dataSource.deletePhotos(photoIds);
    return dto.toEntity();
  }

  @override
  String getStreamUrl(String deviceId) {
    return _dataSource.getStreamUrl(deviceId);
  }
}
