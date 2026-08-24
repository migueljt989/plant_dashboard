import 'dart:async';

import 'package:dio/dio.dart';

import '../datasources/auth/auth_remote_datasource.dart';
import '../datasources/auth/local_auth_datasource.dart';

/// Interceptor que adjunta el access token a cada petición saliente
/// y refresca automáticamente si recibe un 401 en un endpoint no-auth.
///
/// Usa un [Completer] para evitar múltiples llamadas de refresh concurrentes:
/// si varias peticiones fallan con 401 al mismo tiempo, solo se ejecuta
/// un refresh y el resto espera el mismo resultado.
class TokenInterceptor extends Interceptor {
  final LocalAuthDataSource _localStorage;
  final AuthRemoteDataSource _authDataSource;
  final void Function() _onSessionExpired;

  Completer<String>? _refreshCompleter;

  /// Paths de auth que NO deben disparar un refresh al recibir 401.
  static const _authPaths = [
    '/auth/login',
    '/auth/refresh',
    '/auth/register',
  ];

  TokenInterceptor({
    required LocalAuthDataSource localStorage,
    required AuthRemoteDataSource authDataSource,
    required void Function() onSessionExpired,
  })  : _localStorage = localStorage,
        _authDataSource = authDataSource,
        _onSessionExpired = onSessionExpired;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _localStorage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // No intentar refresh en endpoints de autenticación.
    final path = err.requestOptions.path;
    if (_authPaths.contains(path)) {
      return handler.next(err);
    }

    try {
      final newToken = await _getRefreshedToken();

      // Reintenta la petición original con el nuevo token.
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';

      // Usa un Dio limpio para el retry y evitar loop infinito
      // (este interceptor vive en el Dio autenticado).
      final response = await Dio().fetch(opts);
      return handler.resolve(response);
    } catch (_) {
      _onSessionExpired();
      return handler.next(err);
    }
  }

  /// Garantiza que solo un refresh ocurra a la vez.
  /// Peticiones concurrentes que lleguen aquí esperan el mismo [Completer].
  Future<String> _getRefreshedToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String>();
    try {
      final refreshToken = await _localStorage.readRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final newAccessToken = await _authDataSource.refreshToken(refreshToken);
      await _localStorage.updateAccessToken(newAccessToken);

      _refreshCompleter!.complete(newAccessToken);
      return newAccessToken;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
