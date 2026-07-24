import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/auth/login_page.dart';
import '../pages/dashboard/dashboard_page.dart';
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

  return GoRouter(
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // .value devuelve null tanto si el estado es loading/error como si el
      // dato es null (sin sesión). Solo hay sesión activa cuando el valor es
      // un AppUser no nulo.
      final isLoggedIn =
          ref.read(authControllerProvider).value != null;
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      // Requisito 1.1: ruta protegida sin sesión → forzar login.
      if (!isLoggedIn && !goingToLogin) return AppRoutes.login;

      // Requisito 1.2: ya autenticado y va al login → llevar al dashboard.
      if (isLoggedIn && goingToLogin) return AppRoutes.dashboard;

      // Sin redirección necesaria.
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
    ],
  );
});
