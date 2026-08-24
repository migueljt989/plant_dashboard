import 'package:dio/dio.dart';
import '../../../domain/failures/app_failure.dart';
import '../../models/sensor_dto.dart';
import 'sensor_remote_management_datasource.dart';

class SensorRemoteManagementDataSourceBackend
    implements SensorRemoteManagementDataSource {
  final Dio _dio;

  SensorRemoteManagementDataSourceBackend(this._dio);

  @override
  Future<List<SensorDto>> fetchAll() async {
    try {
      final response = await _dio.get('/sensors');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => SensorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<List<SensorDto>> fetchByDevice(String deviceId) async {
    try {
      final response = await _dio.get('/devices/$deviceId/sensors');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => SensorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundFailure('Dispositivo no encontrado');
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<SensorDto> create({
    required String deviceId,
    required String name,
    required String metric,
    double? minOk,
    double? maxOk,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'metric': metric,
      };
      if (minOk != null) body['min_ok'] = minOk;
      if (maxOk != null) body['max_ok'] = maxOk;

      final response =
          await _dio.post('/devices/$deviceId/sensors', data: body);
      return SensorDto.fromJson(response.data as Map<String, dynamic>);
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
  Future<SensorDto> update(String sensorId, Map<String, dynamic> fields) async {
    try {
      final response = await _dio.patch('/sensors/$sensorId', data: fields);
      return SensorDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundFailure('Sensor no encontrado');
      }
      if (e.response?.statusCode == 422) {
        final detail = e.response?.data?['detail'];
        final msg =
            detail is List ? detail.first['msg'] as String : '$detail';
        throw ValidationFailure(msg);
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }
}
