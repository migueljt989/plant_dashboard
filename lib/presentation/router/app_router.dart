import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_dashboard/presentation/pages/auth/register_page.dart';

import '../pages/auth/login_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/splash/splash_page.dart';
import '../providers/auth/auth_providers.dart';
import 'app_routes.dart';

/// Provee el [GoRouter] configurado con:
/// - Guard de autenticación en `redirect`.
/// - `refreshListenable` apuntando al notifier de auth para que el router
///   re-evalúe el guard cada vez que la sesión cambia.
///
/// Reglas del guard:
/// 1. Usuario no autenticado que intenta ir a una ruta protegida → `/login`.
/// 2. Usuario autenticado que va a `/login` → `/` (dashboard).
/// 3. Cualquier otro caso → sin redirección.
final routerProvider = Provider<GoRouter>((ref) {
  // Obtenemos el notifier (AuthController) para usarlo como refreshListenable.
  // AuthController extiende ChangeNotifier, por lo que GoRouter escucha sus
  // notificaciones y re-evalúa redirect automáticamente.
  final authNotifier = ref.watch(authControllerProvider.notifier);

  // Escuchamos el estado de auth para que cuando build() resuelva
  // (restoreSession termina), se llame notifyListeners() y GoRouter
  // re-evalúe el redirect. Esto es necesario porque AsyncNotifier.build()
  // no pasa por el setter override al resolver.
  ref.listen(authControllerProvider, (prev, next) {
    authNotifier.notifyAuthChanged();
  });

  return GoRouter(
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final goingToLogin = location == AppRoutes.login;
      final goingToSplash = location == AppRoutes.splash;

      // Mientras el estado está en loading (restaurando sesión), mandamos
      // al splash para mostrar un spinner neutral, no el formulario de login.
      if (authState.isLoading) {
        return goingToSplash ? null : AppRoutes.splash;
      }

      final isLoggedIn = authState.value != null;

      // Ya no necesitamos el splash una vez resuelto el estado.
      // Redirigir según sesión.
      if (isLoggedIn) {
        // Autenticado: si está en login o splash → dashboard.
        if (goingToLogin || goingToSplash) return AppRoutes.dashboard;
        return null;
      }

      // No autenticado: si no está en login o register → forzar login.
      if (!goingToLogin && location != AppRoutes.register) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
    ],
  );
});
