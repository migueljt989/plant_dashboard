/// Constantes de rutas usadas por [GoRouter] y por cualquier widget
/// que necesite navegar de forma programática.
///
/// Centralizar aquí evita strings duplicados en el código.
class AppRoutes {
  AppRoutes._();

  /// Pantalla de inicio de sesión.
  static const login = '/login';

    /// Pantalla de registro.
  static const register = '/register';

  /// Dashboard principal (ruta protegida por el guard de auth).
  static const dashboard = '/dashboard';

  /// Splash de carga mientras se restaura la sesión.
  static const splash = '/';

  // Shell children (authenticated) — secciones del sidebar
  /// Listado de dispositivos IoT.
  static const devices = '/dispositivos';

  /// Listado de sensores.
  static const sensors = '/sensores';

  /// Histórico de lecturas.
  static const readings = '/lecturas';

  /// Alertas del sistema.
  static const alerts = '/alertas';
}
