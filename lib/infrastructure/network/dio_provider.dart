import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:plant_dashboard/presentation/providers/auth/auth_datasource_provider.dart';
import 'package:plant_dashboard/presentation/providers/auth/auth_local_datasource_provider.dart';
import 'package:plant_dashboard/presentation/providers/auth/auth_providers.dart';

import 'token_interceptor.dart';

/// Timeouts compartidos por todas las instancias de Dio. Sin esto, si el
/// backend no responde (p. ej. no está corriendo en `127.0.0.1:8000`), las
/// peticiones se cuelgan hasta el timeout por defecto del sistema (~1 min en
/// Flutter Web) antes de fallar. Con estos valores fallan en pocos segundos.
const _connectTimeout = Duration(seconds: 5);
const _receiveTimeout = Duration(seconds: 10);
const _sendTimeout = Duration(seconds: 10);

const _baseUrl = 'http://127.0.0.1:8000';

/// Opciones base compartidas por todas las instancias de Dio (baseUrl +
/// timeouts). Centralizadas para que el retry del interceptor use exactamente
/// la misma configuración que el Dio autenticado.
BaseOptions _baseOptions() => BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
    );

/// Crea un Dio con las opciones base compartidas.
Dio _buildDio() => Dio(_baseOptions());

/// Instancia base de Dio SIN [TokenInterceptor] — usada por
/// [AuthRemoteDataSource] para evitar dependencia circular durante el refresh.
final baseDioProvider = Provider<Dio>((ref) {
  return _buildDio();
});

/// Instancia de Dio CON [TokenInterceptor] — usada por todos los demás
/// datasources (sensores, dispositivos, lecturas, alertas).
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = _buildDio();
  final localStorage = ref.watch(authLocalDataSourceProvider);
  final authDataSource = ref.watch(authDataSourceProvider);

  dio.interceptors.add(TokenInterceptor(
    localStorage: localStorage,
    authDataSource: authDataSource,
    onSessionExpired: () {
      ref.read(logoutProvider)();
    },
    // El retry tras un refresh exitoso usa un Dio limpio con la MISMA baseUrl
    // y timeouts, pero sin el interceptor (para no reentrar en el refresh).
    retryDioFactory: _buildDio,
  ));

  return dio;
});
