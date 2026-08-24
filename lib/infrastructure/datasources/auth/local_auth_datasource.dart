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

  /// Lee el access token guardado en storage local.
  /// Devuelve `null` si no hay sesión persistida.
  Future<String?> readToken();

  /// Lee el refresh token guardado en storage local.
  /// Devuelve `null` si no hay sesión persistida.
  Future<String?> readRefreshToken();

  /// Persiste los datos de sesión del usuario en storage local,
  /// incluyendo ambos tokens (access y refresh).
  Future<void> saveSession({
    required String userId,
    required String email,
    required String token,
    required String refreshToken,
  });

  /// Actualiza únicamente el access token en storage local.
  /// Usado por el interceptor tras un refresh exitoso.
  Future<void> updateAccessToken(String token);

  /// Borra la sesión persistida del storage local.
  Future<void> clearSession();
}
