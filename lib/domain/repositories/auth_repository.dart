import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Intenta autenticar. Lanza [AppFailure] si falla.
  Future<AppUser> login(String email, String password);

  Future<AppUser> register(String email, String password);

  /// Cierra la sesión actual.
  Future<void> logout();

  /// Usuario actualmente autenticado, o null si no hay sesión.
  AppUser? get currentUser;

  /// Stream que emite cambios en el estado de autenticación.
  Stream<AppUser?> get authStateChanges;
}
