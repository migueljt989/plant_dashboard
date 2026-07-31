import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../infrastructure/repositories/auth_repository_impl.dart';
import 'auth_datasource_provider.dart';
import 'auth_local_datasource_provider.dart';

/// Provee el [AuthRepository] conectado al datasource remoto (fake o real)
/// y al datasource de storage local para persistencia de sesión.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});

/// Maneja el ciclo de vida de la sesión (login / logout) y expone
/// el usuario actual como [AsyncValue<AppUser?>].
///
/// - `AsyncValue.loading()` mientras se restaura o procesa la sesión.
/// - `AsyncValue.data(user)` cuando la sesión está activa.
/// - `AsyncValue.data(null)` cuando no hay sesión (estado inicial o tras logout).
/// - `AsyncValue.error(failure, st)` si el login falló.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(() => AuthController());

/// [AsyncNotifier] que encapsula la lógica de autenticación.
///
/// Implementa [ChangeNotifier] para que [GoRouter] pueda usarlo como
/// `refreshListenable` y re-evaluar el guard de auth cada vez que el
/// estado de sesión cambia (login / logout).
///
/// Consume [authRepositoryProvider] para login/logout.
/// La UI no instancia ni [AuthRepositoryImpl] ni ningún datasource directamente.
class AuthController extends AsyncNotifier<AppUser?> with ChangeNotifier {
  /// Estado inicial: intenta restaurar la sesión desde localStorage.
  ///
  /// Si hay una sesión guardada (Requisito 1.4), se restaura el usuario y
  /// el router lleva directamente al dashboard. Si no, el estado es null
  /// y el guard de auth redirige a /login.
  @override
  FutureOr<AppUser?> build() async {
    final repo = ref.read(authRepositoryProvider);
    // AuthRepositoryImpl expone restoreSession(); casteamos para acceder.
    if (repo is AuthRepositoryImpl) {
      return repo.restoreSession();
    }
    return null;
  }

  /// Sobreescribimos [state] para notificar a [GoRouter] cada vez que cambia
  /// el estado de autenticación.
  @override
  set state(AsyncValue<AppUser?> newState) {
    super.state = newState;
    notifyListeners();
  }

  /// Notifica a los listeners (GoRouter) de un cambio en el estado de auth.
  /// Necesario porque [build] resuelve sin pasar por el setter override.
  void notifyAuthChanged() {
    notifyListeners();
  }

  /// Intenta autenticar con [email] y [password].
  ///
  /// Actualiza el estado a `loading` durante la llamada.
  /// En éxito expone `data(AppUser)`.
  /// En fallo (credenciales incorrectas) expone `error(AuthFailure, stackTrace)`.
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }

  /// Cierra la sesión y vuelve al estado `data(null)`.
  Future<void> logout() async {
    state = const AsyncValue.loading();
    await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).logout(),
    );
    state = const AsyncValue.data(null);
  }
}
