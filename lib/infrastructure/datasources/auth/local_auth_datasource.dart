/// Contrato para la persistencia local de la sesión de autenticación.
///
/// No forma parte de `domain` porque implica storage local (plataforma),
/// pero es un contrato abstracto dentro de `infrastructure` para que la
/// implementación concreta sea intercambiable (shared_preferences, secure storage, etc.)
abstract class LocalAuthDataSource {
  /// Lee el userId guardado en storage local.
  /// Devuelve `null` si no hay sesión persistida.
  Future<String?> readUserId();

  /// Lee el email guardado en storage local.
  /// Devuelve `null` si no hay sesión persistida.
  Future<String?> readEmail();

  /// Persiste los datos básicos del usuario en storage local.
  Future<void> saveSession({required String userId, required String email, required String token});

  /// Borra la sesión persistida del storage local.
  Future<void> clearSession();
}
