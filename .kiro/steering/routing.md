---
inclusion: fileMatch
fileMatchPattern: 'lib/presentation/router/**/*.dart'
---

# Convenciones de go_router

## Rutas como constantes
Definir todas las rutas en `app_routes.dart` como constantes de string, nunca strings sueltos repetidos en el código:

```dart
class AppRoutes {
  static const splash = '/';        // ruta raíz = splash de carga
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const deviceDetail = '/dispositivo/:deviceId';
}
```

## Guard de autenticación con splash

El guard vive en `redirect` de `GoRouter`. Usa una pantalla de splash (`/`) como sala de espera mientras se restaura la sesión desde localStorage, evitando flashes del login o del dashboard.

### refreshListenable: `authSessionProvider`

GoRouter escucha SOLO `authSessionProvider` (un `Notifier<AppUser?>` con `ChangeNotifier` mixin). Este provider nunca expone loading ni error — solo `null` o `AppUser`. Esto hace que el redirect sea trivial y predecible.

### Restauración de sesión desde el router provider

La restauración de sesión se activa en el `routerProvider` (no en splash) para que funcione sin importar la ruta inicial del browser:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final sessionNotifier = ref.watch(authSessionProvider.notifier);

  // Activar restoreSessionProvider (lee tokens de localStorage).
  ref.read(restoreSessionProvider);

  // Cuando termine, volcar el usuario a authSessionProvider.
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
        if (goingToLogin || goingToRegister || goingToSplash) {
          return AppRoutes.dashboard;
        }
        return null;
      }

      // No autenticado: permitir login, register y splash. Bloquear el resto.
      if (!goingToLogin && !goingToRegister && !goingToSplash) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [...],
  );
});
```

**¿Por qué en el router y no en splash?** Porque si el usuario entra directamente a `/#/login`, la splash page nunca se monta. El router siempre se crea, así que `restoreSessionProvider` siempre se activa.

### Flujo de restauración de sesión

1. App arranca → `routerProvider` se crea → `ref.read(restoreSessionProvider)` activa la restauración.
2. GoRouter muestra splash como `initialLocation` (o la ruta del browser).
3. `restoreSessionProvider` lee tokens de localStorage.
4. Si hay usuario → `ref.listen` callback → `setUser(user)` → `notifyListeners()` → redirect re-evalúa → redirige a dashboard.
5. Si no hay usuario → splash page navega a login. El redirect permite login y register.

### Navegación explícita tras login

Después de un login/register exitoso en la UI, llamar `context.go(AppRoutes.dashboard)` explícitamente para asegurar que la URL del browser se actualice correctamente (no depender solo del redirect vía refreshListenable para este caso).

```dart
final success = await ref.read(loginControllerProvider.notifier).login(email, password);
if (mounted && success) context.go(AppRoutes.dashboard);
```

### Lo que GoRouter NO debe escuchar

- Errores de formulario (login/register fallido) → viven en controllers autoDispose, son invisibles para el router.
- Estado de loading transitorio de un submit → no afecta al router.

Solo transiciones reales de sesión (`null` ↔ `AppUser`) disparan re-evaluación del redirect.

## Parámetros de ruta
Usar `state.pathParameters['deviceId']` para parámetros de ruta, tipados explícitamente al entrar a la página. No pasar objetos completos por `extra` salvo que sea estrictamente necesario (rompe deep-linking).

## Estructura de rutas anidadas
Si el dashboard crece (ej. tabs internos para dispositivos, histórico, ajustes), usar `ShellRoute` para mantener una barra de navegación persistente en vez de duplicar el `Scaffold` en cada página.
