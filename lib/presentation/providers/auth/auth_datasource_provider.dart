
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_dashboard/infrastructure/datasources/auth/auth_remote_datasource_backend.dart';

import '../../../infrastructure/datasources/auth/auth_remote_datasource.dart';
// import '../../../infrastructure/datasources/auth/auth_remote_datasource_fake.dart';

/// Provee el [AuthRemoteDataSource] concreto que se usará en toda la app.
///
/// Para cambiar al datasource real (Firebase Auth, Cognito, etc.),
/// reemplaza el cuerpo de este provider — nada más cambia.
final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceBackend();
});
