import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:plant_dashboard/presentation/providers/auth/auth_datasource_provider.dart';
import 'package:plant_dashboard/presentation/providers/auth/auth_local_datasource_provider.dart';
import 'package:plant_dashboard/presentation/providers/auth/auth_providers.dart';

import 'token_interceptor.dart';

/// Instancia base de Dio SIN interceptor — usada por [AuthRemoteDataSource]
/// para evitar dependencia circular durante el refresh de tokens.
final baseDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));
});

/// Instancia de Dio CON [TokenInterceptor] — usada por todos los demás
/// datasources (sensores, dispositivos, lecturas, alertas).
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));
  final localStorage = ref.watch(authLocalDataSourceProvider);
  final authDataSource = ref.watch(authDataSourceProvider);

  dio.interceptors.add(TokenInterceptor(
    localStorage: localStorage,
    authDataSource: authDataSource,
    onSessionExpired: () {
      ref.read(logoutProvider)();
    },
  ));

  return dio;
});
