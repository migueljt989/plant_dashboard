import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/alerts/alerts_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/camera/live_stream_page.dart';
import '../pages/camera/photo_gallery_page.dart';
import '../pages/camera/photo_viewer_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/devices/devices_page.dart';
import '../pages/readings/readings_page.dart';
import '../pages/sensors/sensors_page.dart';
import '../pages/splash/splash_page.dart';
import '../providers/auth/auth_providers.dart';
import '../widgets/navigation/navigation_shell.dart';
import 'app_routes.dart';

/// Provee el [GoRouter] configurado con:
/// - Guard de autenticación basado en [authSessionProvider].
/// - `refreshListenable` apuntando al [AuthSessionNotifier] para que el router
///   re-evalúe el guard solo cuando la sesión cambia (login/logout).
/// - `ShellRoute` que envuelve las rutas autenticadas con [NavigationShell].
///
/// El router NUNCA se entera de errores de formulario — esos viven en
/// [loginControllerProvider] y [registerControllerProvider] que son autoDispose.
final routerProvider = Provider<GoRouter>((ref) {
  final sessionNotifier = ref.watch(authSessionProvider.notifier);

  // Forzar la activación de restoreSessionProvider (lee tokens de localStorage).
  // Esto garantiza que la restauración se dispare sin importar la ruta inicial.
  ref.read(restoreSessionProvider);

  // Cuando restoreSession termine, volcar el usuario a authSessionProvider.
  // setUser → notifyListeners → GoRouter re-evalúa redirect.
  ref.listen(restoreSessionProvider, (prev, next) {
    next.whenData((user) {
      if (user != null) {
        ref.read(authSessionProvider.notifier).setUser(user);
      }
    });
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: sessionNotifier,
    redirect: (context, state) {
      final user = ref.read(authSessionProvider);
      final location = state.matchedLocation;
      final goingToLogin = location == AppRoutes.login;
      final goingToRegister = location == AppRoutes.register;
      final goingToSplash = location == AppRoutes.splash;

      final isLoggedIn = user != null;

      if (isLoggedIn) {
        // Autenticado: si está en login, register o splash → dashboard.
        if (goingToLogin || goingToRegister || goingToSplash) {
          return AppRoutes.dashboard;
        }
        return null;
      }

      // No autenticado: permitir login, register, y splash. Bloquear el resto.
      if (!goingToLogin && !goingToRegister && !goingToSplash) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      // ── Rutas fuera del shell (sin sidebar) ─────────────────────
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

      // ── Shell (con sidebar) ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.devices,
            builder: (context, state) => const DevicesPage(),
          ),
          GoRoute(
            path: AppRoutes.sensors,
            builder: (context, state) => const SensorsPage(),
          ),
          GoRoute(
            path: AppRoutes.readings,
            builder: (context, state) => const ReadingsPage(),
          ),
          GoRoute(
            path: AppRoutes.alerts,
            builder: (context, state) => const AlertsPage(),
          ),
          GoRoute(
            path: AppRoutes.cameras,
            builder: (context, state) => const PhotoGalleryPage(),
          ),
          GoRoute(
            path: AppRoutes.cameraPhoto,
            builder: (context, state) {
              final String id = state.pathParameters['id']!;
              return PhotoViewerPage(photoId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.cameraStream,
            builder: (context, state) {
              final String deviceId = state.pathParameters['deviceId']!;
              return LiveStreamPage(deviceId: deviceId);
            },
          ),
        ],
      ),
    ],
  );
});
