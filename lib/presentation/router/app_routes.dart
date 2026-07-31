/// Constantes de rutas usadas por [GoRouter] y por cualquier widget
/// que necesite navegar de forma programática.
///
/// Centralizar aquí evita strings duplicados en el código.
class AppRoutes {
  AppRoutes._();

  /// Pantalla de inicio de sesión.
  static const login = '/login';

  /// Dashboard principal (ruta protegida por el guard de auth).
  static const dashboard = '/dashboard';

  /// Splash de carga mientras se restaura la sesión.
  static const splash = '/';
}
