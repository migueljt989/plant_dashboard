import 'package:dio/dio.dart';

import '../../../core/utils/jwt_utils.dart';
import '../../../domain/failures/app_failure.dart';
import '../../models/token_pair_dto.dart';
import 'auth_remote_datasource.dart';

/// Implementación concreta del datasource de autenticación contra el backend FastAPI.
class AuthRemoteDataSourceBackend implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceBackend(this._dio);

  @override
  Future<TokenPairDto> signIn(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final payload = decodeJwtPayload(accessToken);
      final userId = payload['sub'] as String;

      return TokenPairDto(
        userId: userId,
        email: email,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const InvalidCredentialsFailure();
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<TokenPairDto> register(String email, String password) async {
    try {
      final regResponse = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
      });

      final userId = regResponse.data['id'] as String;

      // Auto-login to get tokens
      final loginResponse = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final accessToken = loginResponse.data['access_token'] as String;
      final refreshToken = loginResponse.data['refresh_token'] as String;

      return TokenPairDto(
        userId: userId,
        email: email,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const EmailAlreadyExistsFailure();
      }
      if (e.response?.statusCode == 422) {
        final detail = e.response?.data?['detail'];
        final msg = detail is List ? detail.first['msg'] as String : '$detail';
        throw ValidationFailure(msg);
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return response.data['access_token'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const SessionExpiredFailure();
      }
      throw NetworkFailure(e.message ?? 'Error de red');
    }
  }

  @override
  Future<void> signOut() async {
    // Backend has no explicit logout endpoint — session cleanup is handled locally.
  }
}
