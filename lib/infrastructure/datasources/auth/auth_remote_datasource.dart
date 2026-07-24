import '../../models/app_user_dto.dart';

/// Contrato abstracto del DataSource de autenticación.
/// Las implementaciones concretas (Fake, Firebase, Cognito, etc.) deben extender esta clase.
abstract class AuthRemoteDataSource {
  /// Intenta autenticar con [email] y [password].
  /// Lanza [AuthFailure] si las credenciales son inválidas.
  Future<AppUserDto> signIn(String email, String password);

  /// Cierra la sesión actual.
  Future<void> signOut();
}
