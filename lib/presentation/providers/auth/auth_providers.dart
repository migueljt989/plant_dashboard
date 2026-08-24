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

// ─────────────────────────────────────────────────────────────────────────────
// Estado de sesión (lo que GoRouter observa)
// ─────────────────────────────────────────────────────────────────────────────

/// Estado de sesión global. Solo tiene dos valores posibles:
/// - `null` → no hay sesión activa
/// - `AppUser` → sesión activa
///
/// GoRouter usa este provider (a través del [AuthSessionNotifier]) como
/// `refreshListenable` para re-evaluar el redirect.
/// Nunca expone loading ni error — esos son responsabilidad de los controllers
/// de formulario.
final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AppUser?>(() => AuthSessionNotifier());

/// Notifier simple que además implementa [ChangeNotifier] para que GoRouter
/// pueda escucharlo como `refreshListenable`.
class AuthSessionNotifier extends Notifier<AppUser?> with ChangeNotifier {
  @override
  AppUser? build() => null; // Se resuelve en el init del app (restoreSession)

  void setUser(AppUser? user) {
    state = user;
    notifyListeners();
  }
}

/// Provider que restaura la sesión al inicio de la app.
/// Se lee una sola vez en el splash; su resultado se vuelca a [authSessionProvider].
final restoreSessionProvider = FutureProvider<AppUser?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  if (repo is AuthRepositoryImpl) {
    return repo.restoreSession();
  }
  return null;
});

// ─────────────────────────────────────────────────────────────────────────────
// Controller de Login (estado de formulario)
// ─────────────────────────────────────────────────────────────────────────────

/// Maneja el estado de loading/error del formulario de login.
/// Es `autoDispose` — al salir de la página, el estado se limpia solo.
final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
  () => LoginController(),
);

class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Estado inicial: idle (data(void))
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async {
        final user =
            await ref.read(authRepositoryProvider).login(email, password);
        // Éxito → actualizar sesión global
        ref.read(authSessionProvider.notifier).setUser(user);
      },
    );
    return !state.hasError;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller de Register (estado de formulario)
// ─────────────────────────────────────────────────────────────────────────────

/// Maneja el estado de loading/error del formulario de registro.
/// Es `autoDispose` — al salir de la página, el estado se limpia solo.
final registerControllerProvider =
    AsyncNotifierProvider.autoDispose<RegisterController, void>(
  () => RegisterController(),
);

class RegisterController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Estado inicial: idle (data(void))
  }

  Future<bool> register(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async {
        final user =
            await ref.read(authRepositoryProvider).register(email, password);
        // Éxito → actualizar sesión global
        ref.read(authSessionProvider.notifier).setUser(user);
      },
    );
    return !state.hasError;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout helper
// ─────────────────────────────────────────────────────────────────────────────

/// Función de logout accesible desde cualquier lugar (dashboard, interceptor).
/// Limpia la sesión del repositorio y actualiza el estado global.
final logoutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(authSessionProvider.notifier).setUser(null);
  };
});
