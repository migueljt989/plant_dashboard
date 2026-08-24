import 'package:shared_preferences/shared_preferences.dart';

import 'local_auth_datasource.dart';

/// Implementación de [LocalAuthDataSource] sobre [SharedPreferences].
///
/// En Flutter Web, [SharedPreferences] usa localStorage del navegador,
/// por lo que la sesión sobrevive recargas de página.
///
/// Claves usadas (prefijo `auth_` para evitar colisiones):
///   - `auth_user_id`
///   - `auth_email`
///   - `auth_token`
///   - `auth_refresh_token`
class LocalAuthDataSourceSharedPrefs implements LocalAuthDataSource {
  static const _keyUserId = 'auth_user_id';
  static const _keyEmail = 'auth_email';
  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'auth_refresh_token';

  @override
  Future<String?> readUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  @override
  Future<String?> readEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  @override
  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  @override
  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  @override
  Future<void> saveSession({
    required String userId,
    required String email,
    required String token,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  @override
  Future<void> updateAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
  }
}
