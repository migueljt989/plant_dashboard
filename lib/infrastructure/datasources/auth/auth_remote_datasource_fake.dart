import '../../../domain/failures/app_failure.dart';
import '../../models/token_pair_dto.dart';
import 'auth_remote_datasource.dart';

/// Implementación fake del [AuthRemoteDataSource].
///
/// Acepta las credenciales fijas definidas en las constantes internas.
/// No persiste sesión entre recargas — comportamiento esperado para el MVP fake.
class AuthRemoteDataSourceFake implements AuthRemoteDataSource {
  static const _fakeEmail = 'admin@huerto.local';
  static const _fakePassword = 'jitomate123';

  const AuthRemoteDataSourceFake();

  @override
  Future<TokenPairDto> signIn(String email, String password) async {
    if (email == _fakeEmail && password == _fakePassword) {
      return TokenPairDto(
        userId: 'fake-user-1',
        email: email,
        accessToken: 'fake-access-token',
        refreshToken: 'fake-refresh-token',
      );
    }
    throw const InvalidCredentialsFailure();
  }

  @override
  Future<TokenPairDto> register(String email, String password) async {
    if (email == _fakeEmail) {
      throw const EmailAlreadyExistsFailure();
    }
    return TokenPairDto(
      userId: 'fake-user-${email.hashCode}',
      email: email,
      accessToken: 'fake-access-token',
      refreshToken: 'fake-refresh-token',
    );
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    return 'fake-refreshed-token';
  }

  @override
  Future<void> signOut() async {}
}
