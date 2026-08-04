import '../../../domain/failures/app_failure.dart';
import '../../models/app_user_dto.dart';
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
  Future<AppUserDto> signIn(String email, String password) async {
    if (email == _fakeEmail && password == _fakePassword) {
      return const AppUserDto(id: 'fake-user-1', email: _fakeEmail, token: 'fake-token');
    }
    throw const AuthFailure('Credenciales inválidas');
  }

  @override
  Future<void> signOut() async {}
}
