import '../../models/token_pair_dto.dart';

/// Contrato abstracto del DataSource de autenticación.
/// Las implementaciones concretas (Fake, Firebase, Cognito, etc.) deben extender esta clase.
abstract class AuthRemoteDataSource {
  /// Intenta autenticar con [email] y [password].
  /// Lanza [AuthFailure] si las credenciales son inválidas.
  Future<TokenPairDto> signIn(String email, String password);

  /// Registra un nuevo usuario con [email] y [password].
  Future<TokenPairDto> register(String email, String password);

  /// Solicita un nuevo access token usando el [refreshToken] actual.
  /// Devuelve el nuevo access token.
  Future<String> refreshToken(String refreshToken);

  /// Cierra la sesión actual.
  Future<void> signOut();
}
