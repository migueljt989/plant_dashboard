import 'dart:async';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth/auth_remote_datasource.dart';
import '../datasources/auth/local_auth_datasource.dart';
import '../models/app_user_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final LocalAuthDataSource _localStorage;
  AppUser? _currentUser;
  final _authStateController = StreamController<AppUser?>.broadcast();

  AuthRepositoryImpl(this._dataSource, this._localStorage);

  /// Intenta restaurar la sesión desde el storage local.
  ///
  /// Llamado en `AuthController.build()` al arrancar la app.
  /// Devuelve el [AppUser] si había sesión guardada, o `null` si no.
  Future<AppUser?> restoreSession() async {
    final userId = await _localStorage.readUserId();
    final email = await _localStorage.readEmail();
    if (userId != null && email != null) {
      _currentUser = AppUserDto(id: userId, email: email).toEntity();
      _authStateController.add(_currentUser);
      return _currentUser;
    }
    return null;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    final dto = await _dataSource.signIn(email, password);
    _currentUser = dto.toEntity();
    // Persistir la sesión para que sobreviva recargas.
    await _localStorage.saveSession(
      userId: _currentUser!.id,
      email: _currentUser!.email,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await _dataSource.signOut();
    // Borrar la sesión persistida.
    await _localStorage.clearSession();
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;
}
