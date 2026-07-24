import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/datasources/auth/local_auth_datasource.dart';
import '../../../infrastructure/datasources/auth/local_auth_datasource_shared_prefs.dart';

/// Provee la implementación de [LocalAuthDataSource] usada para persistir
/// la sesión entre recargas.
///
/// Usa [SharedPreferences], que en Flutter Web se apoya en localStorage del
/// navegador. Para cambiar la implementación (ej. flutter_secure_storage),
/// solo hay que modificar este provider.
final authLocalDataSourceProvider = Provider<LocalAuthDataSource>((ref) {
  return LocalAuthDataSourceSharedPrefs();
});
