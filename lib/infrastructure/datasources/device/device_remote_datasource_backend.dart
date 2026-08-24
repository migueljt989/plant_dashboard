import 'package:dio/dio.dart';

import '../../../domain/failures/app_failure.dart';
import '../../models/device_dto.dart';
import 'device_remote_datasource.dart';

class DeviceRemoteDataSourceBackend implements DeviceRemoteDataSource {
  final Dio _dio;

  DeviceRemoteDataSourceBackend(this._dio);

  @override
  Future<List<DeviceDto>> fetchAll() async {
    try {
      final response = await _dio.get('/devices');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => DeviceDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<Map<String, dynamic>> register(String name, String type) async {
    try {
      final response = await _dio.post('/devices/register', data: {
        'name': name,
        'type': type,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final detail = e.response?.data?['detail'];
        final msg =
            detail is List ? detail.first['msg'] as String : '$detail';
        throw ValidationFailure(msg);
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<DeviceDto> revoke(String deviceId) async {
    try {
      final response = await _dio.patch('/devices/$deviceId/revoke');
      return DeviceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundFailure('Dispositivo no encontrado');
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }
}
